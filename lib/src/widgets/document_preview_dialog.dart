import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_world/src/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart'; // ADDED
import 'package:url_launcher/url_launcher.dart';

class DocumentPreviewDialog extends StatefulWidget {
  final String url;
  final String fileName;

  const DocumentPreviewDialog({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  State<DocumentPreviewDialog> createState() => _DocumentPreviewDialogState();
}

class _DocumentPreviewDialogState extends State<DocumentPreviewDialog> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isWebViewSupported = false;

  bool get isPdf => widget.fileName.toLowerCase().endsWith('.pdf');
  
  bool get isVideo {
    final ext = widget.fileName.toLowerCase().split('.').last;
    return ['mp4', 'mov', 'avi', 'webm', 'mkv'].contains(ext);
  }

  String get _embedUrl {
    if (widget.url.contains('drive.google.com')) {
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
      
      if (fileId != null && fileId.isNotEmpty) {
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
    
    // Use WebView for non-PDFs on all platforms, and for PDFs on Web to bypass CORS and memory issues with heavy files
    final useWebView = !isPdf || kIsWeb;

    if (useWebView) {
      _isWebViewSupported = kIsWeb || 
          defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS;

      if (_isWebViewSupported) {
        if (kIsWeb) {
          // Explicitly register the web platform to avoid auto-registration bugs
          WebViewPlatform.instance = WebWebViewPlatform();
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
          // On web, iframe loading state is not tracked via NavigationDelegate
          _isLoading = false;
        }
        
        _controller!.loadRequest(Uri.parse(_embedUrl));
      } else {
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                IconButton(
                  onPressed: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new_rounded, color: SchoolColors.primary, size: 22),
                  splashRadius: 24,
                  tooltip: 'Open in Google Drive',
                ),
                const SizedBox(width: 8),
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
              aspectRatio: isVideo ? 16 / 9 : 1 / 1.414, // 16:9 for videos, A4 document ratio for others
              child: (isPdf && !kIsWeb) 
              ? SfPdfViewer.network(
                  widget.url,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
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
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.previewNotAvailableOnThis,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isLoading)
                      Container(
                        color: isDark ? SchoolColors.darkSurface : Colors.white,
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
