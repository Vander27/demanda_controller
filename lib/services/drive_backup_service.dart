import 'dart:convert';
import 'dart:typed_data';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class DriveBackupService {
  static const String _arquivoBackupNome = 'demanda_controller_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      drive.DriveApi.driveAppdataScope,
      'email',
    ],
  );

  Future<drive.DriveApi?> _obterApiDrive({required bool interativo}) async {
    GoogleSignInAccount? conta = await _googleSignIn.signInSilently();
    conta ??= interativo ? await _googleSignIn.signIn() : null;
    if (conta == null) return null;

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;

    return drive.DriveApi(authClient);
  }

  Future<drive.File?> _buscarArquivoBackup(drive.DriveApi api) async {
    final resposta = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$_arquivoBackupNome' and trashed=false",
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 1,
    );

    if (resposta.files == null || resposta.files!.isEmpty) return null;
    return resposta.files!.first;
  }

  Future<bool> salvarBackupNoDrive(
    String backupJson, {
    bool interativo = true,
  }) async {
    final api = await _obterApiDrive(interativo: interativo);
    if (api == null) return false;

    final bytes = utf8.encode(backupJson);
    final media = drive.Media(
      Stream<List<int>>.fromIterable(<List<int>>[bytes]),
      bytes.length,
    );

    final existente = await _buscarArquivoBackup(api);
    if (existente?.id != null) {
      await api.files.update(
        drive.File(),
        existente!.id!,
        uploadMedia: media,
      );
      return true;
    }

    final metadata = drive.File()
      ..name = _arquivoBackupNome
      ..parents = <String>['appDataFolder'];

    await api.files.create(metadata, uploadMedia: media);
    return true;
  }

  Future<String?> carregarBackupDoDrive({bool interativo = true}) async {
    final api = await _obterApiDrive(interativo: interativo);
    if (api == null) return null;

    final existente = await _buscarArquivoBackup(api);
    if (existente?.id == null) return null;

    final media = await api.files.get(
      existente!.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final parte in media.stream) {
      bytes.addAll(parte);
    }

    if (bytes.isEmpty) return null;
    return utf8.decode(Uint8List.fromList(bytes));
  }
}
