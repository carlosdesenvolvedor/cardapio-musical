import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:excel/excel.dart';
import '../../../../core/error/failures.dart';
import '../../../client_menu/data/datasources/song_remote_data_source.dart';
import '../../../client_menu/data/models/song_model.dart';
import '../../../client_menu/domain/entities/song.dart';
import '../../domain/repositories/repertoire_repository.dart';

class RepertoireRepositoryImpl implements RepertoireRepository {
  final SongRemoteDataSource remoteDataSource;

  RepertoireRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> importFromExcel(Uint8List fileBytes, String musicianId) async {
    try {
      final excel = Excel.decodeBytes(fileBytes);
      final List<SongModel> songs = [];

      for (var table in excel.tables.keys) {
        final tableData = excel.tables[table];
        if (tableData == null) continue;

        // Skip header
        bool firstRow = true;
        for (var row in tableData.rows) {
          if (firstRow) {
            firstRow = false;
            continue;
          }

          if (row.length >= 2) {
            final titleData = row[0];
            final artistData = row[1];
            final genreData = row.length > 2 ? row[2] : null;

            final title = titleData?.value?.toString() ?? '';
            final artist = artistData?.value?.toString() ?? '';
            final genre = genreData?.value?.toString() ?? 'Outros';

            if (title.isNotEmpty && artist.isNotEmpty) {
              songs.add(SongModel(
                id: '',
                title: title,
                artist: artist,
                genre: genre,
                musicianId: musicianId,
              ));
            }
          }
        }
      }

      if (songs.isNotEmpty) {
        await remoteDataSource.uploadBatch(songs);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addSong(Song song) async {
    try {
      final model = _mapToModel(song);
      await remoteDataSource.addSong(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> getSongs(String musicianId) async {
    try {
      final models = await remoteDataSource.getSongs(musicianId);
      final songs = models.map((e) => e as Song).toList();
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSong(Song song) async {
    try {
      final model = _mapToModel(song);
      await remoteDataSource.updateSong(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSong(String songId) async {
    try {
      await remoteDataSource.deleteSong(songId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  SongModel _mapToModel(Song song) {
    return SongModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      genre: song.genre,
      musicianId: song.musicianId,
      albumCoverUrl: song.albumCoverUrl,
    );
  }
}
