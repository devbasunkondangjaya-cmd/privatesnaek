import 'package:flutter/material.dart';

import 'ui_kit.dart';
import 'venomcoil_game.dart';

/// Swipeable how-to-play cards opened from the "?" button.
/// "LEWATI" returns to gameplay at any time.
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key, required this.game});

  final VenomcoilGame game;

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialStep {
  const _TutorialStep(this.title, this.body, this.art);

  final String title;
  final String body;
  final Widget art;
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_TutorialStep>[
    _TutorialStep(
      'GERAKKAN ULAR',
      'Geser jempol kirimu pada joystick di kiri bawah layar untuk meluncur. '
          'Makin lama meluncur, makin besar momentumnya — dibutuhkan untuk '
          'menabrak tembok dan menekan saklar.',
      _JoystickArt(),
    ),
    _TutorialStep(
      'LOMPAT DENGAN COIL',
      'Sentuh dan tahan tombol LOMPAT di kanan bawah untuk mengumpulkan '
          'tenaga, lalu angkat jempol untuk melompat. Ketuk lagi di udara '
          'untuk lompatan kedua.',
      AtlasIcon(Hud.coil, size: 120),
    ),
    _TutorialStep(
      'SERANG & SEMBUR',
      'Ketuk SERANG untuk sabetan ekor ke musuh dan saklar emas. Ketuk RACUN '
          '(terbuka di Area 2) untuk menyembur bisa yang melelehkan tanda '
          'hijau dan musuh berlapis.',
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AtlasIcon(Hud.tail, size: 96),
          SizedBox(width: 16),
          AtlasIcon(Hud.venom, size: 84),
        ],
      ),
    ),
    _TutorialStep(
      'JAGA NYAWAMU',
      'Menyentuh musuh kecil, spora beracun, duri, atau tembakan bos '
          'mengurangi 1 hati. Kalahkan musuh dengan sabetan ekor atau '
          'mendarat di atasnya. Checkpoint memulihkan 1 hati.',
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AtlasIcon(Hud.heart, size: 70),
          SizedBox(width: 6),
          AtlasIcon(Hud.heart, size: 70),
          SizedBox(width: 6),
          AtlasIcon(Hud.brokenHeart, size: 70),
        ],
      ),
    ),
    _TutorialStep(
      'CAPAI UJUNG AREA',
      'Lewati bendera checkpoint — progres tersimpan otomatis. Ketuk tombol '
          'jeda di pojok kanan atas kapan saja, dan tombol ? untuk membuka '
          'panduan ini lagi.',
      AtlasIcon(Hud.flag, size: 110),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page >= _steps.length - 1) {
      widget.game.closeTutorial();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safe = safeInsets(context, extra: 6);
    final last = _page == _steps.length - 1;
    return Container(
      color: const Color(0xd9030d0a),
      padding: safe,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 470),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            decoration: BoxDecoration(
              color: Palette.panel.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Palette.panelLine.withValues(alpha: 0.65),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff45df5a).withValues(alpha: 0.14),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'CARA MAIN',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w900,
                        color: Palette.leafBright,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        UiKit.onTap?.call();
                        widget.game.closeTutorial();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Palette.gold.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          'LEWATI  ›',
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                            color: Palette.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      final text = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}/${_steps.length}  ${step.title}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Palette.cream,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.body,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Palette.mist,
                            ),
                          ),
                        ],
                      );
                      // Phones are played sideways: art beside the text.
                      if (MediaQuery.sizeOf(context).height < 520) {
                        return Row(
                          children: [
                            SizedBox(
                              width: 140,
                              child: FittedBox(child: step.art),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: text,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 130,
                              child: FittedBox(child: step.art),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              step.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Palette.cream,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              step.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.42,
                                color: Palette.mist,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: i == _page
                              ? Palette.leafBright
                              : const Color(0x6678a070),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                GameButton(
                  label: last ? 'MULAI MAIN' : 'LANJUT',
                  style: GameButtonStyle.primary,
                  height: 52,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Little illustration of the on-screen joystick for the first step.
class _JoystickArt extends StatefulWidget {
  const _JoystickArt();

  @override
  State<_JoystickArt> createState() => _JoystickArtState();
}

class _JoystickArtState extends State<_JoystickArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final dx = (Curves.easeInOut.transform(_c.value) * 2 - 1) * 28;
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xbb101d19),
          border: Border.all(color: const Color(0x995e7755), width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(left: 4, child: AtlasIcon(Hud.left, size: 30)),
            const Positioned(right: 4, child: AtlasIcon(Hud.right, size: 30)),
            Transform.translate(
              offset: Offset(dx, 0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xff73bf59), Color(0xff294f33)],
                  ),
                  border: Border.all(color: const Color(0xffa9dc81), width: 2),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
