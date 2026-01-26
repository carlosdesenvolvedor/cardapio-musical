import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../community/domain/repositories/social_graph_repository.dart';

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

class GoogleSignInRequested extends AuthEvent {}

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

class FollowUserRequested extends AuthEvent {
  final String currentUserId;
  final String targetUserId;
  final String? senderName;
  final String? senderPhoto;
  FollowUserRequested(this.currentUserId, this.targetUserId,
      {this.senderName, this.senderPhoto});
  @override
  List<Object?> get props =>
      [currentUserId, targetUserId, senderName, senderPhoto];
}

class UnfollowUserRequested extends AuthEvent {
  final String currentUserId;
  final String targetUserId;
  UnfollowUserRequested(this.currentUserId, this.targetUserId);
  @override
  List<Object?> get props => [currentUserId, targetUserId];
}

class LoadFollowedUsersRequested extends AuthEvent {
  final String userId;
  LoadFollowedUsersRequested(this.userId);
  @override
  List<Object?> get props => [userId];
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
  final UserEntity? currentUser;
  ProfileLoaded(this.profile, {this.currentUser});
  @override
  List<Object?> get props => [profile, currentUser];
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
  final SocialGraphRepository socialGraphRepository;

  AuthBloc({
    required this.repository,
    required this.notificationService,
    required this.socialGraphRepository,
  }) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final result = await repository.getCurrentUser();
      result.fold((_) => emit(Unauthenticated()), (user) {
        if (user != null) {
          notificationService.saveTokenToFirestore(user.id);
          add(UpdateLastActive(user.id));
          add(LoadFollowedUsersRequested(user.id));
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
        add(LoadFollowedUsersRequested(user.id));
        emit(Authenticated(user));
      });
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await repository.signInWithGoogle();
      result.fold((failure) => emit(AuthError(failure.message)), (user) {
        notificationService.saveTokenToFirestore(user.id);
        add(LoadFollowedUsersRequested(user.id));
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
      UserEntity? currentUser;
      if (state is Authenticated) {
        currentUser = (state as Authenticated).user;
      } else if (state is ProfileLoaded) {
        currentUser = (state as ProfileLoaded).currentUser;
      }

      final result = await repository.getProfile(event.userId);
      result.fold(
        (failure) => emit(AuthError(failure.message)),
        (profile) {
          final user = currentUser;
          // If the profile being viewed is the current user's profile, update the user entity data
          if (user != null && user.id == profile.id) {
            currentUser = user.copyWith(
              displayName: profile.artisticName,
              photoUrl: profile.photoUrl,
              nickname: profile.nickname,
            );
          }
          emit(ProfileLoaded(profile, currentUser: currentUser));
        },
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
      if (state is ProfileLoaded) {
        final currentProfile = (state as ProfileLoaded).profile;
        if (currentProfile.id == event.userId) {
          add(ProfileRequested(event.userId));
        }
      }
    });

    on<FollowUserRequested>((event, emit) async {
      await socialGraphRepository.followUser(
        event.currentUserId,
        event.targetUserId,
        senderName: event.senderName,
        senderPhoto: event.senderPhoto,
      );
      add(LoadFollowedUsersRequested(event.currentUserId));
    });

    on<UnfollowUserRequested>((event, emit) async {
      await socialGraphRepository.unfollowUser(
          event.currentUserId, event.targetUserId);
      add(LoadFollowedUsersRequested(event.currentUserId));
    });

    on<LoadFollowedUsersRequested>((event, emit) async {
      final result = await socialGraphRepository.getFollowingIds(event.userId);

      result.fold(
        (failure) {
          // falha silenciosa
        },
        (ids) {
          if (state is Authenticated) {
            final currentUser = (state as Authenticated).user;
            emit(Authenticated(currentUser.copyWith(followingIds: ids)));
          } else if (state is ProfileLoaded) {
            final currentState = state as ProfileLoaded;
            final currentUser = currentState.currentUser;
            if (currentUser != null) {
              emit(ProfileLoaded(currentState.profile,
                  currentUser: currentUser.copyWith(followingIds: ids)));
            }
          }
        },
      );
    });
  }
}
