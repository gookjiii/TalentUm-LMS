import 'package:flutter/material.dart';
import 'package:school_world/src/firebase/safe_firestore.dart';

class CachedStreamBuilder<T> extends StatefulWidget {
  final Stream<T> Function() streamFactory;
  final Widget Function(BuildContext, AsyncSnapshot<T>) builder;
  final List<Object?> keys;

  const CachedStreamBuilder({
    super.key,
    required this.streamFactory,
    required this.builder,
    this.keys = const [],
  });

  @override
  State<CachedStreamBuilder<T>> createState() => _CachedStreamBuilderState<T>();
}

class _CachedStreamBuilderState<T> extends State<CachedStreamBuilder<T>> {
  late Stream<T> _stream;

  @override
  void initState() {
    super.initState();
    _stream = safeFirebaseStream(widget.streamFactory());
  }

  @override
  void didUpdateWidget(covariant CachedStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool keysChanged = false;
    if (widget.keys.length != oldWidget.keys.length) {
      keysChanged = true;
    } else {
      for (int i = 0; i < widget.keys.length; i++) {
        if (widget.keys[i] != oldWidget.keys[i]) {
          keysChanged = true;
          break;
        }
      }
    }
    if (keysChanged) {
      _stream = safeFirebaseStream(widget.streamFactory());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _stream,
      builder: widget.builder,
    );
  }
}
