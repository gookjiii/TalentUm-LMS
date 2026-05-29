import 'package:school_world/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_world/src/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart'; // ADDED

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

  @override
  void initState() {
    super.initState();
    
    if (!isPdf) {
      final docsPreviewUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
      
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
        
        _controller!.loadRequest(Uri.parse(docsPreviewUrl));
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
              aspectRatio: 1 / 1.414, // A4 document ratio
              child: isPdf 
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
