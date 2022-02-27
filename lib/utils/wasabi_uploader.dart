import 'dart:typed_data';

import 'package:minio/minio.dart';

import 'keys.dart';

class SongDatabase {
  String bucket = 'user-recordings';
  final minio = Minio(
    endPoint: "s3.us-central-1.wasabisys.com",
    accessKey: Keys().getAccessKey(),
    secretKey: Keys().getPrivateKey(),
  );

  Future<String> uploadToWasabi(Stream<Uint8List> fileStream,
      String fileName) async {
    await minio.putObject(bucket, fileName, fileStream,
        onProgress: (bytes) => print('$bytes uploaded'),
        metadata: {'x-amz-acl': 'public-read'});
    return "https://s3.us-central-1.wasabisys.com/$bucket/$fileName";
  }

  deleteFromWasabi(String fileName) async {
    MinioInvalidBucketNameError.check(bucket);
    MinioInvalidObjectNameError.check(fileName);

    await minio.removeObject(bucket, fileName);
  }

  Future<MinioByteStream> getObjectFromWasabi(String fileName) async {
    return minio.getObject(bucket, fileName);
  }
}
