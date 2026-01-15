import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class ProfileViewEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfileRequested extends ProfileViewEvent {
  final String userId;
  LoadProfileRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
abstract class ProfileViewState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileViewInitial extends ProfileViewState {}

class ProfileViewLoading extends ProfileViewState {}

class ProfileViewLoaded extends ProfileViewState {
  final UserProfile profile;
  ProfileViewLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class ProfileViewError extends ProfileViewState {
  final String message;
  ProfileViewError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ProfileViewBloc extends Bloc<ProfileViewEvent, ProfileViewState> {
  final AuthRepository repository;

  ProfileViewBloc({required this.repository}) : super(ProfileViewInitial()) {
    on<LoadProfileRequested>((event, emit) async {
      emit(ProfileViewLoading());
      final result = await repository.getProfile(event.userId);
      result.fold(
        (failure) => emit(ProfileViewError(failure.message)),
        (profile) => emit(ProfileViewLoaded(profile)),
      );
    });
  }
}
