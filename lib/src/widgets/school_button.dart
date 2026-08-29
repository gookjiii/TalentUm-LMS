import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Các biến thể phong cách của SchoolButton
enum SchoolButtonVariant {
  /// Nút hành động chính (Primary filled)
  primary,

  /// Nút hành động phụ nổi bật vừa (Tonal / Soft filled)
  secondary,

  /// Nút có đường viền (Outlined)
  outlined,

  /// Nút dạng văn bản (Ghost / Text)
  ghost,

  /// Nút cảnh báo / Xóa dữ liệu (Destructive / Danger)
  destructive,
}

/// Thang kích thước chuẩn cho SchoolButton
enum SchoolButtonSize {
  /// Kích thước lớn: 52px - Dùng cho Auth, Onboarding, Mobile Main CTA
  lg(
    height: 52,
    horizontalPadding: 24,
    verticalPadding: 15,
    fontSize: 16,
    iconSize: 20,
    borderRadius: 14,
    iconSpacing: 10,
  ),

  /// Kích thước trung bình (Mặc định): 44px - Dùng cho Dialogs, Forms, Toolbars
  md(
    height: 44,
    horizontalPadding: 18,
    verticalPadding: 11,
    fontSize: 14.5,
    iconSize: 18,
    borderRadius: 12,
    iconSpacing: 8,
  ),

  /// Kích thước nhỏ: 36px - Dùng cho Table actions, Card sub-actions, Filters
  sm(
    height: 36,
    horizontalPadding: 13,
    verticalPadding: 7,
    fontSize: 13,
    iconSize: 16,
    borderRadius: 10,
    iconSpacing: 6,
  ),

  /// Kích thước siêu nhỏ: 28px - Dùng cho Chat micro-actions, Compact tags
  xs(
    height: 28,
    horizontalPadding: 9,
    verticalPadding: 4,
    fontSize: 11.5,
    iconSize: 14,
    borderRadius: 8,
    iconSpacing: 5,
  );

  const SchoolButtonSize({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.fontSize,
    required this.iconSize,
    required this.borderRadius,
    required this.iconSpacing,
  });

  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final double iconSpacing;
}

/// Component Button đồng bộ chuẩn Design System cho TalentUm-LMS.
///
/// Hỗ trợ đầy đủ các biến thể (primary, secondary, outlined, ghost, destructive),
/// thang kích thước tokenized (lg, md, sm, xs), hiệu ứng micro-animations mượt mà,
/// trạng thái loading không làm lệch layout, và haptic feedback trên mobile.
class SchoolButton extends StatefulWidget {
  const SchoolButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SchoolButtonVariant.primary,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  });

  /// Nút hành động chính (Primary Filled)
  const SchoolButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  })  : variant = SchoolButtonVariant.primary,
        borderColor = null;

  /// Nút hành động phụ nổi bật vừa (Tonal / Soft Surface)
  const SchoolButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  })  : variant = SchoolButtonVariant.secondary,
        borderColor = null;

  /// Nút dạng viền mảnh (Outlined)
  const SchoolButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  })  : variant = SchoolButtonVariant.outlined,
        backgroundColor = null;

  /// Nút dạng chữ không nền (Ghost / Text)
  const SchoolButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.foregroundColor,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  })  : variant = SchoolButtonVariant.ghost,
        backgroundColor = null,
        borderColor = null;

  /// Nút cảnh báo / Xóa dữ liệu (Destructive Danger)
  const SchoolButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SchoolButtonSize.md,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.borderRadius,
    this.tooltip,
    this.enableHaptics = true,
  })  : variant = SchoolButtonVariant.destructive,
        backgroundColor = null,
        foregroundColor = null,
        borderColor = null;

  final String label;
  final VoidCallback? onPressed;
  final SchoolButtonVariant variant;
  final SchoolButtonSize size;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final String? tooltip;
  final bool enableHaptics;

  @override
  State<SchoolButton> createState() => _SchoolButtonState();
}

class _SchoolButtonState extends State<SchoolButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableHaptics &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? widget.size.borderRadius;

    // Phân giải màu sắc theo variant & dark mode
    Color effectiveBg;
    Color effectiveFg;
    Color? effectiveBorder;
    List<BoxShadow>? effectiveShadow;

    switch (widget.variant) {
      case SchoolButtonVariant.primary:
        effectiveBg = widget.backgroundColor ??
            (_isEnabled
                ? theme.colorScheme.primary
                : (isDark
                    ? SchoolColors.darkBorder
                    : SchoolColors.border));
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? Colors.white
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = null;
        if (_isEnabled && !_isPressed) {
          effectiveShadow = [
            BoxShadow(
              color: effectiveBg.withValues(alpha: _isHovered ? 0.35 : 0.2),
              blurRadius: _isHovered ? 14 : 8,
              offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ];
        }
        break;

      case SchoolButtonVariant.secondary:
        effectiveBg = widget.backgroundColor ??
            (_isEnabled
                ? (isDark
                    ? SchoolColors.darkSurfaceElevated
                    : SchoolColors.primaryContainer)
                : (isDark
                    ? SchoolColors.darkBg.withValues(alpha: 0.5)
                    : SchoolColors.secondaryContainer.withValues(alpha: 0.5)));
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? (isDark
                    ? theme.colorScheme.primary
                    : SchoolColors.onPrimaryContainer)
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = null;
        break;

      case SchoolButtonVariant.outlined:
        effectiveBg = widget.backgroundColor ??
            (_isHovered && _isEnabled
                ? (isDark
                    ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.6)
                    : theme.colorScheme.primary.withValues(alpha: 0.05))
                : Colors.transparent);
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? (isDark ? SchoolColors.darkText : SchoolColors.text)
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = widget.borderColor ??
            (_isEnabled
                ? (_isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : (isDark ? SchoolColors.darkBorder : SchoolColors.border))
                : (isDark
                    ? SchoolColors.darkBorder.withValues(alpha: 0.4)
                    : SchoolColors.border.withValues(alpha: 0.6)));
        break;

      case SchoolButtonVariant.ghost:
        effectiveBg = widget.backgroundColor ??
            (_isHovered && _isEnabled
                ? (isDark
                    ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.6)
                    : theme.colorScheme.primary.withValues(alpha: 0.08))
                : Colors.transparent);
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? (isDark ? SchoolColors.darkText : theme.colorScheme.primary)
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = null;
        break;

      case SchoolButtonVariant.destructive:
        effectiveBg = widget.backgroundColor ??
            (_isEnabled
                ? SchoolColors.red
                : (isDark
                    ? SchoolColors.darkBorder
                    : SchoolColors.border));
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? Colors.white
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = null;
        if (_isEnabled && !_isPressed) {
          effectiveShadow = [
            BoxShadow(
              color: SchoolColors.red.withValues(alpha: _isHovered ? 0.35 : 0.2),
              blurRadius: _isHovered ? 14 : 8,
              offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
            ),
          ];
        }
        break;
    }

    // Micro-animation Matrix transform
    Matrix4 transform = Matrix4.identity();
    if (_isEnabled && !kIsWeb) {
      if (_isPressed) {
        transform.scale(0.985);
      }
    } else if (_isEnabled && kIsWeb) {
      if (_isPressed) {
        transform.scale(0.985);
      } else if (_isHovered) {
        transform.translate(0.0, -1.0, 0.0);
      }
    }

    final contentWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('loading_spinner'),
              height: widget.size.iconSize,
              width: widget.size.iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: effectiveFg,
              ),
            )
          : Row(
              key: const ValueKey('button_content'),
              mainAxisSize:
                  widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: widget.size.iconSize,
                      color: effectiveFg,
                    ),
                    child: widget.icon!,
                  ),
                  SizedBox(width: widget.size.iconSpacing),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: widget.size.fontSize,
                      fontWeight: FontWeight.w700,
                      color: effectiveFg,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (widget.trailingIcon != null) ...[
                  SizedBox(width: widget.size.iconSpacing),
                  IconTheme(
                    data: IconThemeData(
                      size: widget.size.iconSize,
                      color: effectiveFg,
                    ),
                    child: widget.trailingIcon!,
                  ),
                ],
              ],
            ),
    );

    Widget button = MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: _isEnabled ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            _isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: widget.size.height,
          constraints: BoxConstraints(
            minWidth: widget.isFullWidth
                ? double.infinity
                : (widget.size.height * 1.5),
          ),
          transform: transform,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(radius),
            border: effectiveBorder != null
                ? Border.all(color: effectiveBorder, width: 1.2)
                : null,
            boxShadow: effectiveShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isEnabled ? _handleTap : null,
              borderRadius: BorderRadius.circular(radius),
              splashColor: effectiveFg.withValues(alpha: 0.12),
              highlightColor: effectiveFg.withValues(alpha: 0.06),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.size.horizontalPadding,
                  vertical: widget.size.verticalPadding,
                ),
                child: Center(
                  widthFactor: widget.isFullWidth ? 1.0 : null,
                  child: contentWidget,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: button,
    );
  }
}

/// Các biến thể cho SchoolIconButton
enum SchoolIconButtonVariant {
  /// Không nền (Ghost / Standard)
  standard,

  /// Nền mờ nhẹ (Tonal)
  tonal,

  /// Nền chính nổi bật (Filled)
  filled,

  /// Có viền mảnh (Outlined)
  outlined,

  /// Cảnh báo / Xóa (Destructive Danger)
  destructive,
}

/// Thang kích thước cho SchoolIconButton
enum SchoolIconButtonSize {
  /// Kích thước lớn: 48x48px (Icon 22px)
  lg(size: 48, iconSize: 22, borderRadius: 14),

  /// Kích thước trung bình (Mặc định): 40x40px (Icon 20px)
  md(size: 40, iconSize: 20, borderRadius: 12),

  /// Kích thước nhỏ: 32x32px (Icon 16px)
  sm(size: 32, iconSize: 16, borderRadius: 9),

  /// Kích thước siêu nhỏ: 24x24px (Icon 14px)
  xs(size: 24, iconSize: 14, borderRadius: 7);

  const SchoolIconButtonSize({
    required this.size,
    required this.iconSize,
    required this.borderRadius,
  });

  final double size;
  final double iconSize;
  final double borderRadius;
}

/// Component Icon Button đồng bộ chuẩn Design System cho TalentUm-LMS.
class SchoolIconButton extends StatefulWidget {
  const SchoolIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = SchoolIconButtonVariant.standard,
    this.size = SchoolIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.isActive = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enableHaptics = true,
  });

  /// Nút icon không nền (Standard / Ghost)
  const SchoolIconButton.standard({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = SchoolIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.isActive = false,
    this.isLoading = false,
    this.foregroundColor,
    this.borderRadius,
    this.enableHaptics = true,
  })  : variant = SchoolIconButtonVariant.standard,
        backgroundColor = null;

  /// Nút icon nền mềm nhẹ (Tonal)
  const SchoolIconButton.tonal({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = SchoolIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.isActive = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enableHaptics = true,
  }) : variant = SchoolIconButtonVariant.tonal;

  /// Nút icon nền màu chính (Filled)
  const SchoolIconButton.filled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = SchoolIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.isActive = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enableHaptics = true,
  }) : variant = SchoolIconButtonVariant.filled;

  /// Nút icon cảnh báo / Xóa (Destructive Danger)
  const SchoolIconButton.destructive({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = SchoolIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.isLoading = false,
    this.borderRadius,
    this.enableHaptics = true,
  })  : variant = SchoolIconButtonVariant.destructive,
        isActive = false,
        backgroundColor = null,
        foregroundColor = null;

  final Widget icon;
  final VoidCallback? onPressed;
  final SchoolIconButtonVariant variant;
  final SchoolIconButtonSize size;
  final String? tooltip;
  final String? semanticLabel;
  final bool isActive;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final bool enableHaptics;

  @override
  State<SchoolIconButton> createState() => _SchoolIconButtonState();
}

class _SchoolIconButtonState extends State<SchoolIconButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _handleTap() {
    if (!_isEnabled) return;
    if (widget.enableHaptics &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android)) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = widget.borderRadius ?? widget.size.borderRadius;

    Color effectiveBg;
    Color effectiveFg;
    Color? effectiveBorder;

    switch (widget.variant) {
      case SchoolIconButtonVariant.standard:
        effectiveBg = widget.isActive
            ? (isDark
                ? SchoolColors.darkSurfaceElevated
                : theme.colorScheme.primaryContainer)
            : (_isHovered && _isEnabled
                ? (isDark
                    ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.6)
                    : theme.colorScheme.primary.withValues(alpha: 0.08))
                : Colors.transparent);
        effectiveFg = widget.foregroundColor ??
            (widget.isActive
                ? (isDark ? theme.colorScheme.primary : SchoolColors.primary)
                : (_isEnabled
                    ? (isDark
                        ? SchoolColors.darkText
                        : SchoolColors.textSecondary)
                    : (isDark ? SchoolColors.darkMuted : SchoolColors.muted)));
        effectiveBorder = null;
        break;

      case SchoolIconButtonVariant.tonal:
        effectiveBg = widget.backgroundColor ??
            (widget.isActive
                ? (isDark
                    ? SchoolColors.primaryLight.withValues(alpha: 0.25)
                    : SchoolColors.primaryContainer)
                : (_isHovered && _isEnabled
                    ? (isDark
                        ? SchoolColors.darkSurfaceElevated
                        : theme.colorScheme.primary.withValues(alpha: 0.12))
                    : (isDark
                        ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.5)
                        : SchoolColors.surfaceElevated)));
        effectiveFg = widget.foregroundColor ??
            (widget.isActive
                ? theme.colorScheme.primary
                : (_isEnabled
                    ? (isDark
                        ? SchoolColors.darkText
                        : SchoolColors.textSecondary)
                    : (isDark ? SchoolColors.darkMuted : SchoolColors.muted)));
        effectiveBorder = null;
        break;

      case SchoolIconButtonVariant.filled:
        effectiveBg = widget.backgroundColor ??
            (_isEnabled
                ? theme.colorScheme.primary
                : (isDark
                    ? SchoolColors.darkBorder
                    : SchoolColors.border));
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? Colors.white
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = null;
        break;

      case SchoolIconButtonVariant.outlined:
        effectiveBg = _isHovered && _isEnabled
            ? (isDark
                ? SchoolColors.darkSurfaceElevated.withValues(alpha: 0.6)
                : theme.colorScheme.primary.withValues(alpha: 0.05))
            : Colors.transparent;
        effectiveFg = widget.foregroundColor ??
            (_isEnabled
                ? (isDark ? SchoolColors.darkText : SchoolColors.text)
                : (isDark ? SchoolColors.darkMuted : SchoolColors.muted));
        effectiveBorder = _isEnabled
            ? (_isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : (isDark ? SchoolColors.darkBorder : SchoolColors.border))
            : (isDark
                ? SchoolColors.darkBorder.withValues(alpha: 0.4)
                : SchoolColors.border.withValues(alpha: 0.6));
        break;

      case SchoolIconButtonVariant.destructive:
        effectiveBg = _isHovered && _isEnabled
            ? SchoolColors.red.withValues(alpha: 0.12)
            : (isDark
                ? SchoolColors.red.withValues(alpha: 0.08)
                : SchoolColors.redContainer.withValues(alpha: 0.5));
        effectiveFg = _isEnabled
            ? SchoolColors.red
            : (isDark ? SchoolColors.darkMuted : SchoolColors.muted);
        effectiveBorder = null;
        break;
    }

    Matrix4 transform = Matrix4.identity();
    if (_isEnabled) {
      if (_isPressed) {
        transform.scale(0.92);
      } else if (_isHovered && kIsWeb) {
        transform.translate(0.0, -1.0, 0.0);
      }
    }

    Widget button = MouseRegion(
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: _isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: _isEnabled ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel:
            _isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: widget.size.size,
          height: widget.size.size,
          transform: transform,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(radius),
            border: effectiveBorder != null
                ? Border.all(color: effectiveBorder, width: 1.2)
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isEnabled ? _handleTap : null,
              borderRadius: BorderRadius.circular(radius),
              splashColor: effectiveFg.withValues(alpha: 0.15),
              highlightColor: effectiveFg.withValues(alpha: 0.08),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size.iconSize,
                        height: widget.size.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: effectiveFg,
                        ),
                      )
                    : IconTheme(
                        data: IconThemeData(
                          size: widget.size.iconSize,
                          color: effectiveFg,
                        ),
                        child: widget.icon,
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel ?? widget.tooltip,
      child: button,
    );
  }
}

/// Nhóm nút bố cục ngang/dọc đồng bộ cho Dialogs, Form Footers, Toolbars
class SchoolButtonGroup extends StatelessWidget {
  const SchoolButtonGroup({
    super.key,
    required this.children,
    this.spacing = 10,
    this.alignment = MainAxisAlignment.end,
    this.direction = Axis.horizontal,
  });

  /// Bố cục chuẩn cho Dialog Footer (Hủy bên trái, Xác nhận bên phải)
  factory SchoolButtonGroup.dialogActions({
    required Widget cancel,
    required Widget confirm,
    double spacing = 12,
  }) {
    return SchoolButtonGroup(
      alignment: MainAxisAlignment.end,
      spacing: spacing,
      children: [cancel, confirm],
    );
  }

  final List<Widget> children;
  final double spacing;
  final MainAxisAlignment alignment;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          children[i],
        ],
      ],
    );
  }
}
