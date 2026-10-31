import 'package:flutter/material.dart';

import 'movement_joystick.dart';
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

  Widget _art(_TutorialStep step, double side) => SizedBox(
    width: side,
    height: side,
    child: CustomPaint(
      painter: const MedallionPainter(),
      child: Padding(
        padding: EdgeInsets.all(side * 0.17),
        child: FittedBox(child: step.art),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    final sideways = MediaQuery.sizeOf(context).height < 520;
    return ModalVeil(
      extra: 4,
      color: const Color(0xd9020605),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 470),
        child: OrnatePanel(
          padding: const EdgeInsets.fromLTRB(22, 13, 22, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'CARA MAIN',
                    style: Ts.head(12, color: Palette.leafBright, spacing: 2.6),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      UiKit.onTap?.call();
                      widget.game.closeTutorial();
                    },
                    child: Plaque(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      child: Text(
                        'LEWATI  ›',
                        style: Ts.head(11.5, color: Palette.gold),
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
                    // Phones are played sideways: art beside the text.
                    if (sideways) {
                      return Row(
                        children: [
                          _art(step, 122),
                          const SizedBox(width: 18),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GradientText(
                                      step.title,
                                      colors: const [
                                        Palette.goldBright,
                                        Palette.gold,
                                      ],
                                      style: Ts.head(19, spacing: 1),
                                    ),
                                    const SizedBox(height: 7),
                                    Text(step.body, style: Ts.body(14.5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _art(step, 130),
                          const SizedBox(height: 12),
                          GradientText(
                            step.title,
                            colors: const [Palette.goldBright, Palette.gold],
                            style: Ts.head(22, spacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.body,
                            textAlign: TextAlign.center,
                            style: Ts.body(15),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i == _page
                            ? Palette.gold
                            : const Color(0x55e9c77d),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              GameButton(
                label: last ? 'MULAI MAIN' : 'LANJUT',
                style: GameButtonStyle.primary,
                height: 46,
                onTap: _next,
              ),
            ],
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
  late final Animation<double> _offset = _c.drive(
    Tween<double>(begin: -32, end: 32).chain(CurveTween(curve: Curves.easeInOut)),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 120,
    child: CustomPaint(
      painter: const JoystickBasePainter(),
      foregroundPainter: JoystickThumbPainter(_offset),
    ),
  );
}
