import 'dart:io';
import 'package:dio/dio.dart';
import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_world/src/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Removed webview_flutter_web import because it breaks Android build on Dart 3+
import 'package:url_launcher/url_launcher.dart';
import 'package:school_world/src/utils/google_drive_helper.dart';
import 'package:open_filex/open_filex.dart';

class DocumentPreviewDialog extends StatefulWidget {
  final String url;
  final String fileName;
  final String? driveFileId;
  final String? storageProvider;

  const DocumentPreviewDialog({
    super.key,
    required this.url,
    required this.fileName,
    this.driveFileId,
    this.storageProvider,
  });

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isWebViewSupported = false;

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  String? _previewError;
  int _pdfViewerAttempt = 0;

  bool get isPdf => widget.fileName.toLowerCase().endsWith('.pdf');
  bool get isDoc {
    final ext = widget.fileName.toLowerCase().split('.').last;
    return [
      'doc',
      'docx',
      'ppt',
      'pptx',
      'xls',
      'xlsx',
      'txt',
      'csv',
    ].contains(ext);
  }

  bool get _isGoogleDrive => widget.url.contains('drive.google.com');

  bool get isVideo {
    final ext = widget.fileName.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
  }

  String get _fileId {
    String? fileId;
    if (widget.url.contains('/file/d/')) {
      final parts = widget.url.split('/file/d/');
      if (parts.length > 1) {
        fileId = parts[1].split('/').first.split('?').first;
      }
    } else if (widget.url.contains('id=')) {
      try {
        final uri = Uri.parse(widget.url);
        fileId = uri.queryParameters['id'];
      } catch (_) {}
    }
    return fileId ?? '';
  }

  String get _resolvedDriveFileId {
    final explicitId = widget.driveFileId?.trim();
    if (explicitId != null && explicitId.isNotEmpty) return explicitId;
    return _fileId;
  }

  bool get _isGoogleDriveFile {
    final provider = widget.storageProvider?.trim().toLowerCase();
    return provider == 'google_drive' ||
        _isGoogleDrive ||
        (widget.driveFileId?.trim().isNotEmpty ?? false);
  }

  String get _pdfPreviewUrl {
    if (!isPdf || !_isGoogleDriveFile) return widget.url;

    const proxyBaseUrl = String.fromEnvironment(
      'GOOGLE_DRIVE_PROXY_URL',
      defaultValue: 'https://vercel-talentum-backend.vercel.app',
    );
    final proxyUrl = GoogleDriveHelper.buildPdfPreviewUrl(
      _resolvedDriveFileId,
      proxyBaseUrl: proxyBaseUrl,
    );
    return proxyUrl.isEmpty ? widget.url : proxyUrl;
  }

  String get _embedUrl {
    if (_isGoogleDrive) {
      final fileId = _fileId;
      if (fileId.isNotEmpty) {
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    }
    if (isPdf || isVideo) {
      return widget.url;
    }
    return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
  }

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  void _initPreview() {
    // PDFs must be loaded as PDF bytes. Google Drive's `/preview` URL is an
    // HTML viewer and may render as a blank WebView on mobile, so Google Drive
    // PDFs use the Vercel PDF proxy and SfPdfViewer instead.
    final useWebView = !isPdf;

    if (useWebView) {
      _isWebViewSupported =
          kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      if (_isWebViewSupported) {
        if (kIsWeb) {
          // WebViewPlatform.instance = WebWebViewPlatform();
        }

        _controller = WebViewController();

        if (!kIsWeb) {
          _controller!
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(const Color(0x00000000))
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (String url) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onPageFinished: (String url) {
                  if (mounted) setState(() => _isLoading = false);
                },
                onWebResourceError: (WebResourceError error) {
                  if (mounted) setState(() => _isLoading = false);
                },
              ),
            );
        } else {
          _isLoading = false;
        }

        _controller!.loadRequest(Uri.parse(_embedUrl));
      } else {
        _isLoading = false;
      }
    } else {
      _isLoading = false;
    }
  }

  Future<void> _downloadAndPreview() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _previewError = null;
    });

    try {
      final fileId = _resolvedDriveFileId;
      String downloadUrl = widget.url;
      String cookieString = '';

      if (isPdf && _pdfPreviewUrl != widget.url) {
        downloadUrl = _pdfPreviewUrl;
      } else if (fileId.isNotEmpty) {
        final result = await GoogleDriveHelper.getDirectDownloadLink(fileId);
        downloadUrl = result['url'] ?? widget.url;
        cookieString = result['cookie'] ?? '';
      }

      final dir = await getTemporaryDirectory();
      final safeFileName = widget.fileName.replaceAll(RegExp(r'[/\\]'), '_');
      final tempFilePath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      final dio = Dio();
      await dio.download(
        downloadUrl,
        tempFilePath,
        options: Options(
          headers: cookieString.isNotEmpty ? {'Cookie': cookieString} : null,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _localFilePath = tempFilePath;
          _isDownloading = false;
          _previewError = null;
        });

        if (isDoc) {
          OpenFilex.open(tempFilePath);
        }
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _previewError = AppLocalizations.of(context)!.couldNotOpenAttachment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenAttachment),
          ),
        );
      }
    }
  }

  void _handlePdfLoaded() {
    if (!mounted) return;
    if (_previewError != null) setState(() => _previewError = null);
  }

  void _handlePdfLoadFailed(PdfDocumentLoadFailedDetails details) {
    debugPrint('PDF preview failed: ${details.error} — ${details.description}');
    if (!mounted) return;
    setState(() => _previewError = details.description);
  }

  void _retryPdfPreview() {
    setState(() {
      _previewError = null;
      _pdfViewerAttempt++;
    });
  }

  Widget _buildPdfError(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              size: 48,
              color: isDark ? Colors.white54 : SchoolColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.couldNotOpenAttachment,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : SchoolColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _retryPdfPreview,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
                FilledButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(widget.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l10n.open),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final usePdfViewerFile = isPdf && _localFilePath != null;
    final usePdfViewerNetwork =
        isPdf && _localFilePath == null && _pdfPreviewUrl.isNotEmpty;

    return Dialog(
      backgroundColor: isDark ? SchoolColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!kIsWeb)
                  IconButton(
                    onPressed: _downloadAndPreview,
                    icon: const Icon(
                      Icons.download_rounded,
                      color: SchoolColors.primary,
                      size: 22,
                    ),
                    splashRadius: 24,
                    tooltip: 'Tải xuống',
                  ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => launchUrl(
                    Uri.parse(widget.url),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: SchoolColors.primary,
                    size: 22,
                  ),
                  splashRadius: 24,
                  tooltip: 'Open externally',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  splashRadius: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Preview Area
          Flexible(
            child: AspectRatio(
              aspectRatio: isVideo ? 16 / 9 : 1 / 1.414,
              child: _isDownloading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPdf
                                ? Icons.picture_as_pdf_rounded
                                : Icons.description_rounded,
                            size: 64,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: LinearProgressIndicator(
                              value: _downloadProgress > 0
                                  ? _downloadProgress
                                  : null,
                              color: SchoolColors.primary,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Đang tải... ${(_downloadProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _previewError != null
                  ? _buildPdfError(context, isDark)
                  : usePdfViewerFile
                  ? SfPdfViewer.file(
                      key: ValueKey('pdf-viewer-$_pdfViewerAttempt'),
                      File(_localFilePath!),
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      onDocumentLoaded: (_) => _handlePdfLoaded(),
                      onDocumentLoadFailed: _handlePdfLoadFailed,
                    )
                  : usePdfViewerNetwork
                  ? SfPdfViewer.network(
                      key: ValueKey('pdf-viewer-$_pdfViewerAttempt'),
                      _pdfPreviewUrl,
                      canShowScrollHead: false,
                      canShowScrollStatus: false,
                      onDocumentLoaded: (_) => _handlePdfLoaded(),
                      onDocumentLoadFailed: _handlePdfLoadFailed,
                    )
                  : Stack(
                      children: [
                        if (_isWebViewSupported && _controller != null)
                          WebViewWidget(controller: _controller!)
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insert_drive_file_rounded,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.previewNotAvailableOnThis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                  ),
                                ),
                                if (isDoc && _localFilePath != null) ...[
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        OpenFilex.open(_localFilePath!),
                                    icon: const Icon(Icons.open_in_new_rounded),
                                    label: const Text(
                                      'Mở file bằng ứng dụng khác',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: SchoolColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (_isLoading)
                          Container(
                            color: isDark
                                ? SchoolColors.darkSurface
                                : Colors.white,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: SchoolColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
