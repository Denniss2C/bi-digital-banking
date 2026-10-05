import 'package:auth/l10n/gen/auth_localizations.dart';
import 'package:auth/src/domain/repositories/auth_repository.dart';
import 'package:auth/src/presentation/forms/auth_messages.dart';
import 'package:auth/src/presentation/forms/form_validation.dart';
import 'package:auth/src/presentation/sign_in/sign_in_cubit.dart';
import 'package:auth/src/presentation/sign_up/sign_up_cubit.dart';
import 'package:auth/src/presentation/widgets/auth_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthMode { signIn, signUp }

/// Field errors are shown only after the first submit attempt.
String? _errorText(
  AuthLocalizations l10n, {
  required bool show,
  required FieldError? error,
}) => show && error != null ? fieldErrorMessage(l10n, error) : null;

/// Sign in / create account screen ("autenticación" in the design).
///
/// Success needs no navigation here: the session changes and the app router
/// redirects to home.
class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.repository,
    this.initialMode = AuthMode.signIn,
    super.key,
  });

  final AuthRepository repository;
  final AuthMode initialMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SignInCubit(repository)),
        BlocProvider(create: (_) => SignUpCubit(repository)),
      ],
      child: _AuthView(initialMode: initialMode),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView({required this.initialMode});

  final AuthMode initialMode;

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  late AuthMode _mode = widget.initialMode;

  void _switchTo(AuthMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context);
    final theme = Theme.of(context);
    final isSignIn = _mode == AuthMode.signIn;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NexoLogo(size: 28, semanticsLabel: null),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                isSignIn ? l10n.signInTab : l10n.signUpTab,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            SegmentedButton<AuthMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: AuthMode.signIn,
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l10n.signInTab),
                ),
                ButtonSegment(
                  value: AuthMode.signUp,
                  icon: const Icon(Icons.person_add_alt),
                  label: Text(l10n.signUpTab),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => _switchTo(selection.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                isSignIn ? l10n.signInHeadline : l10n.signUpHeadline,
                style: theme.textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isSignIn ? l10n.signInSubtitle : l10n.signUpSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isSignIn)
              _SignInForm(onRegister: () => _switchTo(AuthMode.signUp))
            else
              _SignUpForm(onSignIn: () => _switchTo(AuthMode.signIn)),
          ],
        ),
      ),
    );
  }
}

class _SignInForm extends StatelessWidget {
  const _SignInForm({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context);
    return BlocBuilder<SignInCubit, SignInState>(
      builder: (context, state) {
        final cubit = context.read<SignInCubit>();
        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: cubit.emailChanged,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.alternate_email),
                        errorText: _errorText(
                          l10n,
                          show: state.showErrors,
                          error: state.emailError,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      label: l10n.passwordLabel,
                      autofillHint: AutofillHints.password,
                      onChanged: cubit.passwordChanged,
                      onSubmitted: (_) => cubit.submit(),
                      errorText: _errorText(
                        l10n,
                        show: state.showErrors,
                        error: state.passwordError,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state.isSubmitting
                            ? null
                            : cubit.sendPasswordReset,
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.failure != null)
                InlineMessage.error(failureMessage(l10n, state.failure!)),
              if (state.resetEmailSentTo != null)
                InlineMessage.info(
                  l10n.resetEmailSent(state.resetEmailSentTo!),
                ),
              const SizedBox(height: AppSpacing.md),
              const SecurityTip(),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.signInAction,
                icon: Icons.login,
                isLoading: state.isSubmitting,
                onPressed: cubit.submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchModePrompt(
                question: l10n.noAccountQuestion,
                action: l10n.registerAction,
                onPressed: onRegister,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AuthLocalizations.of(context);
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        final cubit = context.read<SignUpCubit>();
        String? message(FieldError? error) =>
            _errorText(l10n, show: state.showErrors, error: error);
        return AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: cubit.nameChanged,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: l10n.nameLabel,
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: message(state.nameError),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      onChanged: cubit.emailChanged,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.alternate_email),
                        errorText: message(state.emailError),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PasswordField(
                      label: l10n.passwordLabel,
                      autofillHint: AutofillHints.newPassword,
                      helperText: l10n.passwordRules,
                      onChanged: cubit.passwordChanged,
                      onSubmitted: (_) => cubit.submit(),
                      errorText: message(state.passwordError),
                    ),
                  ],
                ),
              ),
              if (state.failure != null)
                InlineMessage.error(failureMessage(l10n, state.failure!)),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: l10n.signUpAction,
                icon: Icons.person_add_alt,
                isLoading: state.isSubmitting,
                onPressed: cubit.submit,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchModePrompt(
                question: l10n.haveAccountQuestion,
                action: l10n.signInAction,
                onPressed: onSignIn,
              ),
            ],
          ),
        );
      },
    );
  }
}
