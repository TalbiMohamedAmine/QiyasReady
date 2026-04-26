import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/auth_provider.dart';
import 'sign_in_screen.dart';

class _SignUpColors {
  static const primaryBlue = Color(0xFF1A6BFF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9E9E9E);
  static const textLink = Color(0xFF1A6BFF);
  static const requiredBadgeBg = Colors.transparent;
  static const requiredBadgeText = Color(0xFF9E9E9E);
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const String _googleLogoSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M18.2 10.2c0-.66-.06-1.28-.17-1.88H10v3.56h4.62c-.2 1.08-.82 1.99-1.74 2.6v2.16h2.81c1.64-1.5 2.51-3.72 2.51-6.44Z" fill="#4285F4"/>
<path d="M10 19c2.34 0 4.3-.78 5.73-2.12l-2.81-2.16c-.78.52-1.77.83-2.92.83-2.24 0-4.14-1.51-4.82-3.54H2.29v2.23A8.99 8.99 0 0 0 10 19Z" fill="#34A853"/>
<path d="M5.18 12c-.17-.52-.27-1.07-.27-1.64s.1-1.12.27-1.64V6.49H2.29A9 9 0 0 0 1 10.36c0 1.45.35 2.82 1.29 3.87L5.18 12Z" fill="#FBBC05"/>
<path d="M10 4.05c1.27 0 2.41.44 3.3 1.31l2.47-2.47C14.29 1.41 12.34.5 10 .5A8.99 8.99 0 0 0 2.29 6.49l2.89 2.23C5.86 5.56 7.76 4.05 10 4.05Z" fill="#EA4335"/>
</svg>
''';

  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _isBackHovered = false;
  bool _isLoginHovered = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  double get _formWidth {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 480;
    if (width >= 768) return 520;
    return double.infinity;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthActionState>(authControllerProvider, (previous, next) {
      final previousError = previous?.errorMessage;
      final nextError = next.errorMessage;

      if (nextError != null && nextError != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(nextError),
              backgroundColor: Colors.red,
            ),
          );
      }
    });

    final actionState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _SignUpColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            final isTablet =
                constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
            final isDesktop = constraints.maxWidth >= 1200;
            final maxWidth =
                _formWidth.isFinite ? _formWidth : constraints.maxWidth;
            final horizontalPadding = isMobile
                ? 24.0
                : isTablet
                    ? 40.0
                    : 48.0;
            const verticalPadding = 32.0;
            final boxRadius = isMobile ? 0.0 : 12.0;
            final boxShadow = isMobile
                ? const <BoxShadow>[]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDesktop ? 0.12 : 0.08),
                      blurRadius: isDesktop ? 24 : 18,
                      offset: Offset(0, isDesktop ? 12 : 8),
                    ),
                  ];

            final form = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _SignUpColors.surface,
                  borderRadius: BorderRadius.circular(boxRadius),
                  boxShadow: boxShadow,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBackButton(),
                    const SizedBox(height: 24),
                    _buildHeading(),
                    const SizedBox(height: 20),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 24),
                    _buildGoogleButton(isLoading: actionState.isLoading),
                    const SizedBox(height: 12),
                    _buildSocialRow(),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 28),
                    _buildSignUpButton(isLoading: actionState.isLoading),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                  ],
                ),
              ),
            );

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: isDesktop
                    ? Center(child: form)
                    : Align(
                        alignment: Alignment.topCenter,
                        child: form,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    final backColor =
        _isBackHovered ? const Color(0xFF0F57D4) : _SignUpColors.textLink;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_isBackHovered) {
          setState(() {
            _isBackHovered = true;
          });
        }
      },
      onExit: (_) {
        if (_isBackHovered) {
          setState(() {
            _isBackHovered = false;
          });
        }
      },
      child: GestureDetector(
        onTap: _handleBack,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, color: backColor, size: 22),
            const SizedBox(width: 2),
            Text(
              'Back',
              style: TextStyle(
                color: backColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                decoration: _isBackHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Sign up as a learner today!',
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _SignUpColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    const linkStyle = TextStyle(
      color: _SignUpColors.textLink,
      decoration: TextDecoration.underline,
      decorationColor: _SignUpColors.textLink,
      height: 1.35,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            // TODO: connect to auth_provider.dart
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: _SignUpColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          side: const BorderSide(color: _SignUpColors.border),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: _SignUpColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.35,
                ),
                children: [
                  const TextSpan(text: 'By checking this box, I agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: connect to auth_provider.dart
                      },
                      child: const Text('QiyasReady Terms of Service',
                          style: linkStyle),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: connect to auth_provider.dart
                      },
                      child: const Text('Privacy Policy', style: linkStyle),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton({required bool isLoading}) {
    return _OutlinedActionButton(
      onTap: () {
        if (isLoading) {
          return;
        }

        _handleGoogleSignIn();
      },
      height: 52,
      borderRadius: 8,
      showShadow: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.string(
            _googleLogoSvg,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Continue with Google',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _SignUpColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            onTap: () {
              // TODO: implement Facebook sign-in in auth_provider.dart
            },
            child:
                const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            onTap: () {
              // TODO: implement Apple sign-in in auth_provider.dart
            },
            child: const Icon(Icons.apple, color: Colors.black, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            onTap: () {
              // TODO: implement Microsoft sign-in in auth_provider.dart
            },
            child: const _MicrosoftLogo(),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
      {required VoidCallback onTap, required Widget child}) {
    return _OutlinedActionButton(
      onTap: onTap,
      height: 52,
      borderRadius: 6,
      child: Center(child: child),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(
            child:
                Divider(color: _SignUpColors.border, thickness: 1, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or sign up with email',
            style: TextStyle(
              color: _SignUpColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
            child:
                Divider(color: _SignUpColors.border, thickness: 1, height: 1)),
      ],
    );
  }

  Widget _buildEmailField() {
    return _LabeledInputField(
      label: 'Email',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      hintText: 'email@example.com',
    );
  }

  Widget _buildPasswordField() {
    return _LabeledInputField(
      label: 'Password',
      controller: _passwordController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      obscureText: _obscurePassword,
      helperText:
          'Password must be at least 8 characters and should have a mixture of letters and other characters',
    );
  }

  Widget _buildSignUpButton({required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: _SignUpColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Sign up'),
      ),
    );
  }

  Widget _buildLoginLink() {
    final linkStyle = TextStyle(
      color: _SignUpColors.textLink,
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      decoration:
          _isLoginHovered ? TextDecoration.underline : TextDecoration.none,
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _SignUpColors.textPrimary,
          fontSize: 13.5,
          height: 1.4,
        ),
        children: [
          const TextSpan(text: 'Already have a QiyasReady account? '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (!_isLoginHovered) {
                  setState(() {
                    _isLoginHovered = true;
                  });
                }
              },
              onExit: (_) {
                if (_isLoginHovered) {
                  setState(() {
                    _isLoginHovered = false;
                  });
                }
              },
              child: GestureDetector(
                onTap: _handleLogin,
                child: Text('Log in', style: linkStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  Future<void> _handleSignUp() async {
    final agreedToTerms = _agreedToTerms;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!agreedToTerms) {
      _showSnackBar(
        'Please agree to the Terms of Service to continue.',
      );
      return;
    }

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || password.length < 8) {
      _showSnackBar('Password must be at least 8 characters.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: email,
          password: password,
        );

    if (!mounted) return;

    if (success) {
      _emailController.clear();
      _passwordController.clear();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!_agreedToTerms) {
      _showSnackBar('Please agree to the Terms of Service to continue.');
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted || !success) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.onTap,
    required this.child,
    required this.height,
    required this.borderRadius,
    this.showShadow = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final double height;
  final double borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _SignUpColors.surface,
      elevation: showShadow ? 1 : 0,
      shadowColor: Colors.black.withOpacity(0.08),
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: _SignUpColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _SignUpColors.border, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LabeledInputField extends StatelessWidget {
  const _LabeledInputField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.textInputAction,
    this.obscureText = false,
    this.helperText,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final String? helperText;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _SignUpColors.textPrimary,
              ),
            ),
            const _RequiredBadge(),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 15,
            color: _SignUpColors.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: _SignUpColors.textMuted,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: _SignUpColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: _SignUpColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                  color: _SignUpColors.primaryBlue, width: 1.5),
            ),
            helperText: helperText,
            helperMaxLines: 3,
            helperStyle: const TextStyle(
              fontSize: 12,
              color: _SignUpColors.textMuted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'required',
      style: TextStyle(
        fontSize: 12,
        color: _SignUpColors.requiredBadgeText,
      ),
    );
  }
}

class _MicrosoftLogo extends StatelessWidget {
  const _MicrosoftLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _MicrosoftLogoPainter(),
      ),
    );
  }
}

class _MicrosoftLogoPainter extends CustomPainter {
  const _MicrosoftLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 2.0;
    final square = (size.width - gap) / 2;

    final redPaint = Paint()..color = const Color(0xFFF25022);
    final greenPaint = Paint()..color = const Color(0xFF7FBA00);
    final bluePaint = Paint()..color = const Color(0xFF00A4EF);
    final yellowPaint = Paint()..color = const Color(0xFFFFB900);

    canvas.drawRect(Rect.fromLTWH(0, 0, square, square), redPaint);
    canvas.drawRect(Rect.fromLTWH(square + gap, 0, square, square), greenPaint);
    canvas.drawRect(Rect.fromLTWH(0, square + gap, square, square), bluePaint);
    canvas.drawRect(
      Rect.fromLTWH(square + gap, square + gap, square, square),
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
