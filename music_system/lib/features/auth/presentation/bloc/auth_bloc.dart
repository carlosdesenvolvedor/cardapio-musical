import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  SignUpRequested(this.email, this.password, this.name);
  @override
  List<Object?> get props => [email, password, name];
}

class SignOutRequested extends AuthEvent {}

class ProfileRequested extends AuthEvent {
  final String userId;
  ProfileRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends AuthEvent {
  final UserProfile profile;
  ProfileUpdateRequested(this.profile);
  @override
  List<Object?> get props => [profile];
}

class UpdateLastActive extends AuthEvent {
  final String userId;
  UpdateLastActive(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ToggleLiveStatus extends AuthEvent {
  final String userId;
  final bool isLive;
  ToggleLiveStatus(this.userId, this.isLive);
  @override
  List<Object?> get props => [userId, isLive];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserEntity user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileLoaded extends AuthState {
  final UserProfile profile;
  ProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  final PushNotificationService notificationService;

  AuthBloc({required this.repository, required this.notificationService})
      : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final result = await repository.getCurrentUser();
      result.fold((_) => emit(Unauthenticated()), (user) {
        if (user != null) {
          notificationService.saveTokenToFirestore(user.id);
          add(UpdateLastActive(user.id)); // Atualiza status online
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      });
    });

    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.signIn(event.email, event.password);
      result.fold((failure) => emit(AuthError(failure.message)), (user) {
        notificationService.saveTokenToFirestore(user.id);
        emit(Authenticated(user));
      });
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.signUp(
        event.email,
        event.password,
        event.name,
      );
      result.fold((failure) => emit(AuthError(failure.message)), (user) {
        notificationService.saveTokenToFirestore(user.id);
        emit(Authenticated(user));
      });
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      await repository.signOut();
      emit(Unauthenticated());
    });

    on<ProfileRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.getProfile(event.userId);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (profile) => emit(ProfileLoaded(profile)),
      );
    });

    on<ProfileUpdateRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.updateProfile(event.profile);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (_) => add(ProfileRequested(event.profile.id)),
      );
    });

    on<UpdateLastActive>((event, emit) async {
      await repository.updateLastActive(event.userId);
    });

    on<ToggleLiveStatus>((event, emit) async {
      await repository.setLiveStatus(event.userId, event.isLive);
      // If we are showing the profile of this person, refresh it
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        if (currentProfile.id == event.userId) {
          add(ProfileRequested(event.userId));
        }
      }
    });
  }
}
