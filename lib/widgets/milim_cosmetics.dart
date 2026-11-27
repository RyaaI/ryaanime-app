import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MilimTitleBadge extends StatefulWidget {
  final String title;
  final double fontSize;
  const MilimTitleBadge({super.key, this.title = 'MilimNava', this.fontSize = 12.5});

  @override
  State<MilimTitleBadge> createState() => _MilimTitleBadgeState();
}

class _MilimTitleBadgeState extends State<MilimTitleBadge> with SingleTickerProviderStateMixin {
  VideoPlayerController? _vc;
  bool _ready = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();
    _initVid();
  }

  Future<void> _initVid() async {
    try {
      final c = VideoPlayerController.asset('assets/videos/special_title_frame.mp4');
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0.0);
      await c.play();
      if (!mounted) { await c.dispose(); return; }
      setState(() { _vc = c; _ready = true; });
    } catch (_) {}
  }

  @override
  void dispose() { _vc?.dispose(); _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        final wave = (math.sin(t * math.pi * 2) + 1) / 2;
        final glow = Color.lerp(const Color(0xFFFF2A6D), const Color(0xFF1DA1F2), wave)!;
        final glitch = (t > 0.47 && t < 0.51) || (t > 0.96);
        final dx = glitch ? ((t * 100).round().isEven ? 1.8 : -1.8) : 0.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0912).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glow.withValues(alpha: 0.75), width: 1.2),
              boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 12)],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_ready && _vc != null)
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _vc!.value.size.width,
                        height: _vc!.value.size.height,
                        child: Transform.scale(scale: 1.55, child: VideoPlayer(_vc!)),
                      ),
                    ),
                  ),
                if (glitch)
                  Transform.translate(
                    offset: Offset(-dx * 1.4, 0.6),
                    child: Text(widget.title, style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: const Color(0xFF38BDF8).withValues(alpha: 0.85))),
                  ),
                if (glitch)
                  Transform.translate(
                    offset: Offset(dx * 1.4, -0.6),
                    child: Text(widget.title, style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: const Color(0xFFFF2A6D).withValues(alpha: 0.85))),
                  ),
                Transform.translate(
                  offset: Offset(dx, 0),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: Colors.white,
                      shadows: [Shadow(color: glow, blurRadius: 10), Shadow(color: glow.withValues(alpha: 0.8), blurRadius: 20)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MilimAvatarFrame extends StatefulWidget {
  final Widget child;
  final double size;
  final bool enabled;
  const MilimAvatarFrame({super.key, required this.child, required this.size, this.enabled = true});

  @override
  State<MilimAvatarFrame> createState() => _MilimAvatarFrameState();
}

class _MilimAvatarFrameState extends State<MilimAvatarFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final outer = widget.size * 1.44;
    return SizedBox(
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final pulse = 0.55 + 0.35 * math.sin(_ctrl.value * math.pi * 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 1.10,
                height: widget.size * 1.10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF5D8F).withValues(alpha: pulse), blurRadius: 16, spreadRadius: 2),
                    BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: pulse * 0.45), blurRadius: 22),
                  ],
                ),
              ),
              SizedBox(width: widget.size * 0.90, height: widget.size * 0.90, child: ClipOval(child: widget.child)),
              IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (r) => const RadialGradient(colors: [Colors.transparent, Colors.white, Colors.white], stops: [0.56, 0.72, 1.0]).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([1.15,0,0,0,12, 0,0.95,0,0,0, 0,0,1.10,0,10, 0.55,0.55,0.55,0,-25]),
                    child: Image.asset('assets/images/milim_border.jpeg', width: outer, height: outer, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AbyssalCommentBubble extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  const AbyssalCommentBubble({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin});

  @override
  State<AbyssalCommentBubble> createState() => _AbyssalCommentBubbleState();
}

class _AbyssalCommentBubbleState extends State<AbyssalCommentBubble> {
  VideoPlayerController? _vc;
  bool _ready = false;

  @override
  void initState() { super.initState(); _initVid(); }
  Future<void> _initVid() async {
    try {
      final c = VideoPlayerController.asset('assets/videos/special_comment_bg.mp4');
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0.0);
      await c.play();
      if (!mounted) { await c.dispose(); return; }
      setState(() { _vc = c; _ready = true; });
    } catch (_) {}
  }
  @override
  void dispose() { _vc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF5D8F).withValues(alpha: 0.65), width: 1.2),
        boxShadow: [BoxShadow(color: const Color(0xFFFF2A6D).withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0E0918), Color(0xFF1D0D2B)])))),
            if (_ready && _vc != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(width: _vc!.value.size.width, height: _vc!.value.size.height, child: VideoPlayer(_vc!)),
                ),
              ),
            Positioned.fill(child: Container(color: const Color(0xFF07060D).withValues(alpha: 0.42))),
            Padding(padding: widget.padding, child: widget.child),
          ],
        ),
      ),
    );
  }
}
