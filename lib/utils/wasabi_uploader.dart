import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:la_ti/model/custom_url_audio_player.dart';
import 'package:la_ti/screen/main_screen.dart';
import 'package:minio/minio.dart';

import 'keys.dart';

class WasabiUploader{


  final minio = Minio(
    endPoint: "s3.wasabisys.com",
    accessKey: Keys().getAccessKey(),
    secretKey: Keys().getPrivateKey(),
  );

  Future<String> uploadToWasabi(Stream<Uint8List> fileStream) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    String fileName = formattedDate;
    await minio.putObject(
      'new-test-bucket-222',
      fileName,
      fileStream,
      metadata: {'x-amz-acl': 'public-read'}
    );
    return"https://s3.wasabisys.com/new-test-bucket-222/$fileName";
  }
}