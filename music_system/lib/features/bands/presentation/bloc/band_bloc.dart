import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/band_entity.dart';
import '../../domain/entities/band_member_entity.dart';
import '../../domain/usecases/create_band.dart';
import '../../domain/usecases/get_band_members.dart';
import '../../domain/usecases/invite_member.dart';
import '../../domain/repositories/band_repository.dart';

// Events
abstract class BandEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateBandEvent extends BandEvent {
  final BandEntity band;
  CreateBandEvent(this.band);
  @override
  List<Object?> get props => [band];
}

class LoadUserBandsEvent extends BandEvent {
  final String userId;
  LoadUserBandsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadBandMembersEvent extends BandEvent {
  final String bandId;
  LoadBandMembersEvent(this.bandId);
  @override
  List<Object?> get props => [bandId];
}

class InviteMemberEvent extends BandEvent {
  final String bandId;
  final BandMemberEntity member;
  InviteMemberEvent(this.bandId, this.member);
  @override
  List<Object?> get props => [bandId, member];
}

// States
abstract class BandState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BandInitial extends BandState {}

class BandLoading extends BandState {}

class BandLoaded extends BandState {
  final List<BandEntity> bands;
  BandLoaded(this.bands);
  @override
  List<Object?> get props => [bands];
}

class BandMembersLoaded extends BandState {
  final List<BandMemberEntity> members;
  BandMembersLoaded(this.members);
  @override
  List<Object?> get props => [members];
}

class BandOperationSuccess extends BandState {
  final String message;
  BandOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class BandError extends BandState {
  final String message;
  BandError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class BandBloc extends Bloc<BandEvent, BandState> {
  final CreateBand createBand;
  final GetBandMembers getBandMembers;
  final InviteMember inviteMember;
  final BandRepository repository;

  BandBloc({
    required this.createBand,
    required this.getBandMembers,
    required this.inviteMember,
    required this.repository,
  }) : super(BandInitial()) {
    on<CreateBandEvent>((event, emit) async {
      emit(BandLoading());
      final result = await createBand(event.band);
      result.fold(
        (failure) => emit(BandError(failure.message)),
        (id) => emit(BandOperationSuccess('Banda criada com sucesso! ID: $id')),
      );
    });

    on<LoadUserBandsEvent>((event, emit) async {
      emit(BandLoading());
      final result = await repository.getUserBands(event.userId);
      result.fold(
        (failure) => emit(BandError(failure.message)),
        (bands) => emit(BandLoaded(bands)),
      );
    });

    on<LoadBandMembersEvent>((event, emit) async {
      emit(BandLoading());
      final result = await getBandMembers(event.bandId);
      result.fold(
        (failure) => emit(BandError(failure.message)),
        (members) => emit(BandMembersLoaded(members)),
      );
    });

    on<InviteMemberEvent>((event, emit) async {
      emit(BandLoading());
      final result = await inviteMember(InviteMemberParams(
        bandId: event.bandId,
        member: event.member,
      ));
      result.fold(
        (failure) => emit(BandError(failure.message)),
        (_) => emit(BandOperationSuccess('Convite enviado!')),
      );
    });
  }
}
