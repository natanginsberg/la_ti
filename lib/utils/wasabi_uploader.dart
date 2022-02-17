import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:minio/minio.dart';

import 'keys.dart';

class SongDatabase {
  String bucket = 'new-test-bucket-222';
  final minio = Minio(
    endPoint: "s3.wasabisys.com",
    accessKey: Keys().getAccessKey(),
    secretKey: Keys().getPrivateKey(),
  );

  Future<String> uploadToWasabi(Stream<Uint8List> fileStream, String fileName) async {
    await minio.putObject(bucket, fileName, fileStream,
        metadata: {'x-amz-acl': 'public-read'});
    return "https://s3.wasabisys.com/new-test-bucket-222/$fileName";
  }

  deleteFromWasabi(String fileName) async {
    MinioInvalidBucketNameError.check(bucket);
    MinioInvalidObjectNameError.check(fileName);

    await minio.removeObject(bucket, fileName);
  }
}
