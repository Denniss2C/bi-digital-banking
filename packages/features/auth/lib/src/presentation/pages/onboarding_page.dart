import 'package:auth/l10n/gen/auth_localizations.dart';
import 'package:auth/src/presentation/widgets/auth_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Three-slide onboarding ("onboarding" screen of the design).
///
/// It only reports the user's choice; the shell decides what to persist and
/// where to navigate.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.onFinished,
    required this.onSignIn,
    super.key,
  });

  /// "Omitir" or the last "Comenzar": go create an account.
  final VoidCallback onFinished;

  /// "¿Ya tienes cuenta? Inicia sesión".
  final VoidCallback onSignIn;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) => _controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context);
    final theme = Theme.of(context);
    final slides = [
      _Slide(
        Icons.account_balance_wallet_outlined,
        l10n.onboardingBankingTab,
        l10n.onboardingBankingTitle,
        l10n.onboardingBankingBody,
      ),
      _Slide(
        Icons.verified_user_outlined,
        l10n.onboardingSecurityTab,
        l10n.onboardingSecurityTitle,
        l10n.onboardingSecurityBody,
      ),
      _Slide(
        Icons.trending_up,
        l10n.onboardingSavingsTab,
        l10n.onboardingSavingsTitle,
        l10n.onboardingSavingsBody,
      ),
    ];
    final isLast = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Decorative: the brand name is written next to it.
                  const NexoLogo(size: 32, semanticsLabel: null),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'nexo',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onFinished,
                    child: Text(l10n.onboardingSkip),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final (i, slide) in slides.indexed)
                    ButtonSegment(value: i, label: Text(slide.tab)),
                ],
                selected: {_index},
                onSelectionChanged: (selection) => _goTo(selection.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _index = index),
                  children: [for (final slide in slides) _SlideView(slide)],
                ),
              ),
              _Dots(count: slides.length, index: _index),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: isLast ? l10n.onboardingStart : l10n.onboardingContinue,
                icon: Icons.arrow_forward,
                onPressed: isLast ? widget.onFinished : () => _goTo(_index + 1),
              ),
              SwitchModePrompt(
                question: l10n.onboardingHaveAccount,
                action: l10n.onboardingSignIn,
                onPressed: widget.onSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.icon, this.tab, this.title, this.body);

  final IconData icon;
  final String tab;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            variant: AppCardVariant.hero,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ExcludeSemantics(
                child: Icon(slide.icon, size: 96, color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page indicator; screen readers hear "Paso 2 de 3".
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AuthLocalizations.of(context).onboardingStep(index + 1, count),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index ? scheme.primary : scheme.outlineVariant,
                  borderRadius: AppRadius.pillBorder,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
