extension ImageUrlExtension on String {
  /// Converts a Google Drive viewer URL to a direct download URL so it can be
  /// rendered by Image providers like CachedNetworkImage.
  String get toDirectImageUrl {
    if (isEmpty) return this;
    return _googleDriveImageUrl(this, width: 1000);
  }

  /// Returns the highest-quality safe image source for a full-screen viewer.
  ///
  /// Cloudinary URLs stay untouched so that the viewer receives the original
  /// stored asset instead of an additional lossy transformation. Drive images
  /// use a larger, but still bounded, preview to avoid fetching arbitrary files.
  String toFullResolutionImageUrl({int googleDriveWidth = 2560}) {
    if (isEmpty) return this;
    return _googleDriveImageUrl(this, width: googleDriveWidth);
  }

  String toOptimizedCloudinary({
    int width = 800,
    bool lowPerformance = false,
    bool performance = false,
  }) {
    if (isEmpty) return this;
    if (!contains('cloudinary.com')) return this;

    final isLow = lowPerformance || performance;
    final targetWidth = isLow ? (width ~/ 2).clamp(200, 600) : width;
    if (contains('/upload/')) {
      final transformation = 'q_auto,f_auto,w_$targetWidth,c_limit/';
      return replaceFirst('/upload/', '/upload/$transformation');
    }
    return this;
  }
}

String _googleDriveImageUrl(String url, {required int width}) {
  final clean = url.trim();
  if (clean.isEmpty) return url;
  if (!clean.contains('drive.google.com') &&
      !clean.contains('docs.google.com') &&
      !clean.contains('drive.usercontent.google.com')) {
    return url;
  }

  String? fileId;
  final uri = Uri.tryParse(clean);
  final queryId = uri?.queryParameters['id'];
  if (queryId != null && queryId.isNotEmpty) {
    fileId = queryId;
  } else {
    final patterns = [
      RegExp(
        r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.google\.com\/open\?id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.google\.com\/uc\?.*id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'drive\.usercontent\.google\.com\/download\?.*id=([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'docs\.google\.com\/(?:document|spreadsheets|presentation|file)\/d\/([a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(clean);
      if (match != null && match.groupCount >= 1) {
        fileId = match.group(1);
        if (fileId != null && fileId.isNotEmpty) break;
      }
    }
  }

  if (fileId == null || fileId.isEmpty) return url;

  final targetWidth = width.clamp(1000, 4096).toInt();
  const proxyUrl = String.fromEnvironment(
    'GOOGLE_DRIVE_PROXY_URL',
    defaultValue: 'https://vercel-talentum-backend.vercel.app',
  );
  if (proxyUrl.isNotEmpty) {
    return '$proxyUrl/api/library/image?id=$fileId&width=$targetWidth';
  }
  return 'https://drive.google.com/thumbnail?id=$fileId&sz=w$targetWidth';
}
