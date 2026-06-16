extension ImageUrlExtension on String {
  /// Converts a Google Drive viewer URL to a direct download URL so it can be 
  /// rendered by Image providers like CachedNetworkImage.
  String get toDirectImageUrl {
    if (isEmpty) return this;
    
    if (contains('drive.google.com')) {
      final regExp = RegExp(r'drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(this);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        if (fileId != null && fileId.isNotEmpty) {
          const proxyUrl = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');
          if (proxyUrl.isNotEmpty) {
            // Temporarily bypass proxy due to 500 error
            // return '$proxyUrl/api/library/image?id=$fileId';
          }
          return 'https://drive.google.com/thumbnail?id=$fileId&sz=w1000';
        }
      }
    }
    return this;
  }

  String toOptimizedCloudinary({bool performance = false}) {
    if (isEmpty) return this;
    if (!contains('cloudinary.com')) return this;
    
    // Check if it already has transformations
    if (contains('/upload/')) {
      final transformation = performance ? 'q_auto,f_auto,w_400/' : 'q_auto,f_auto/';
      return replaceFirst('/upload/', '/upload/$transformation');
    }
    return this;
  }
}
