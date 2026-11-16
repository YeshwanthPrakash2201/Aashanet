import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../theme/app_theme.dart';

// ============================================================
// KOLAM PATTERN
// ============================================================

/// A light dot-grid with interlocking loops, inspired by the kolam /
/// rangoli drawn at the doorsteps of the homes ASHA workers visit.
/// Drawn in code, so it costs no image assets and works offline.
class KolamPainter extends CustomPainter {
  const KolamPainter({
    this.color = Colors.white,
    this.opacity = 0.10,
    this.spacing = 30,
  });

  final Color color;
  final double opacity;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = color.withValues(alpha: opacity * 1.6);
    final line = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final cols = (size.width / spacing).ceil() + 1;
    final rows = (size.height / spacing).ceil() + 1;
    final r = spacing * 0.5;

    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final center = Offset(i * spacing, j * spacing);
        canvas.drawCircle(center, 1.6, dot);

        // Loops between every other group of four dots.
        if ((i + j).isEven) {
          final loopCenter = center + Offset(spacing / 2, spacing / 2);
          canvas.drawCircle(loopCenter, r * 0.72, line);
        }
      }
    }
  }

  @override
  bool shouldRepaint(KolamPainter old) =>
      old.color != color || old.opacity != opacity || old.spacing != spacing;
}

// ============================================================
// HERO SURFACE
// ============================================================

/// Deep-teal gradient panel with the kolam motif and a marigold glow.
/// Used for the top of home, login and language screens.
class HeroSurface extends StatelessWidget {
  const HeroSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: KolamPainter()),
            ),
            // Warm marigold glow in the corner.
            Positioned(
              right: -80,
              top: -90,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.marigold.withValues(alpha: 0.38),
                        AppColors.marigold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BRAND MARK
// ============================================================

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: onDark ? null : AppColors.tealGradient,
              color: onDark ? Colors.white.withValues(alpha: 0.14) : null,
              borderRadius: BorderRadius.circular(size * 0.3),
              border: onDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.28))
                  : null,
              boxShadow: onDark
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: size * 0.58,
            ),
          ),
          // Marigold "bindi" accent.
          Positioned(
            right: -size * 0.06,
            top: -size * 0.06,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                gradient: AppColors.actionGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: onDark ? AppColors.forest : AppColors.cream,
                  width: size * 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LAYOUT
// ============================================================

/// Centers content and caps its width so pages read well on tablets and
/// desktops, while using the full width on phones.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // heightFactor 1: centre horizontally only and take the child's
    // height, so it also works inside bottom bars and columns.
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small uppercase label above a section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.saffron),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.forest,
                  letterSpacing: 0.3,
                ),
          ),
        ),
      ],
    );
  }
}

/// White rounded card with a soft border, the base surface of the app.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.borderColor = AppColors.line,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tinted callout (notice, info, warning).
class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.icon,
    required this.child,
    this.color = AppColors.warning,
    this.background = AppColors.warningMist,
  });

  final IconData icon;
  final Widget child;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: Color.lerp(color, Colors.black, 0.35),
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOTION
// ============================================================

/// Fades and slides its child in once, after [delay]. Used to stagger
/// the arrival of cards so screens feel alive without being busy.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Gives any tappable surface a gentle lift on hover (mouse / tablet
/// pointer) and a press-down scale on touch.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = AppRadii.lg,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final scale = !enabled
        ? 1.0
        : _pressed
            ? 0.97
            : _hovered
                ? 1.015
                : 1.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.55,
              duration: const Duration(milliseconds: 200),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTION TILE
// ============================================================

/// Large, glove-friendly navigation tile with a tinted icon.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.teal,
    this.background = AppColors.tealMist,
    this.trailing,
    this.vertical = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final Widget? trailing;

  /// Icon above text (grid layouts) instead of beside it (lists).
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final iconBadge = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Icon(icon, color: color, size: 28),
    );

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: AppColors.ink),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: SurfaceCard(
        padding: const EdgeInsets.all(18),
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      iconBadge,
                      const Spacer(),
                      trailing ??
                          const Icon(Icons.arrow_outward_rounded,
                              color: AppColors.inkMuted, size: 20),
                    ],
                  ),
                  const SizedBox(height: 18),
                  texts,
                ],
              )
            : Row(
                children: [
                  iconBadge,
                  const SizedBox(width: 16),
                  Expanded(child: texts),
                  trailing ??
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.inkMuted),
                ],
              ),
      ),
    );
  }
}

// ============================================================
// GRADIENT BUTTON
// ============================================================

/// The one primary action on a screen: marigold gradient, full width.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Pressable(
      onTap: enabled ? onPressed : null,
      borderRadius: AppRadii.md,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.actionGradient,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.saffron.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MICROPHONE
// ============================================================

/// The voice-first heart of the app: a large microphone that breathes
/// with expanding rings while recording and shows the elapsed time.
class PulsingMicButton extends StatefulWidget {
  const PulsingMicButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.size = 148,
  });

  final bool isRecording;
  final VoidCallback? onPressed;
  final double size;

  @override
  State<PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PulsingMicButton old) {
    super.didUpdateWidget(old);
    if (old.isRecording != widget.isRecording) {
      _sync();
    }
  }

  void _sync() {
    if (widget.isRecording) {
      _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final recording = widget.isRecording;
    final ringColor = recording ? AppColors.saffron : AppColors.teal;

    return SizedBox(
      width: size * 1.7,
      height: size * 1.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding rings (only animate while recording).
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    _ring(
                      ((_pulse.value + i / 3) % 1.0),
                      size,
                      ringColor,
                      recording,
                    ),
                ],
              );
            },
          ),
          Pressable(
            onTap: widget.onPressed,
            borderRadius: size,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: recording
                    ? AppColors.actionGradient
                    : AppColors.tealGradient,
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  recording ? Icons.stop_rounded : Icons.mic_rounded,
                  key: ValueKey(recording),
                  color: Colors.white,
                  size: size * 0.44,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double t, double size, Color color, bool active) {
    if (!active) {
      // A quiet static halo when idle.
      return Container(
        width: size * 1.28,
        height: size * 1.28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.teal.withValues(alpha: 0.07),
        ),
      );
    }

    final scale = 1 + t * 0.7;
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: size * scale,
        height: size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
      ),
    );
  }
}

/// mm:ss timer that runs while [running] is true.
class ElapsedTimer extends StatefulWidget {
  const ElapsedTimer({super.key, required this.running, this.style});

  final bool running;
  final TextStyle? style;

  @override
  State<ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<ElapsedTimer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    final seconds = elapsed.inSeconds;
    if (seconds != _seconds) {
      setState(() => _seconds = seconds);
    }
  });

  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.running) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(ElapsedTimer old) {
    super.didUpdateWidget(old);
    if (widget.running && !_ticker.isActive) {
      _seconds = 0;
      _ticker.start();
    } else if (!widget.running && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return Text('$m:$s', style: widget.style);
  }
}

// ============================================================
// SMALL HELPERS
// ============================================================

/// "—— OR ——" divider.
class OrDivider extends StatelessWidget {
  const OrDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.6,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Gentle loading view with the brand mark, used while the app starts.
class BrandedLoader extends StatelessWidget {
  const BrandedLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HeroSurface(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMark(size: 76, onDark: true),
              const SizedBox(height: 28),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.marigold,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rotating gradient sweep used behind empty states.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealMist,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: KolamPainter(
                      color: AppColors.teal,
                      opacity: 0.12,
                      spacing: 20,
                    ),
                  ),
                  Icon(icon, size: 52, color: AppColors.teal),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clamp helper used by responsive grids.
int columnsFor(double width, {int max = 3}) =>
    math.max(1, math.min(max, (width / 300).floor()));
