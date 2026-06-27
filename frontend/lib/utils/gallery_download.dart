export 'gallery_download_stub.dart'
    if (dart.library.html) 'gallery_download_web.dart'
    if (dart.library.io) 'gallery_download_io.dart';
