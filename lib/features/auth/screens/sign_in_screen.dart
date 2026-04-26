import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/auth_provider.dart';
import 'sign_up_screen.dart';

class _SignInColors {
  static const primary = Color(0xFF1A6BFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9E9E9E);
  static const textLink = Color(0xFF1A6BFF);
  static const border = Color(0xFFE0E0E0);
  static const buttonDisabled = Color(0xFF9E9E9E);
  static const facebookBlue = Color(0xFF1877F2);
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const String _googleLogoSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M18.2 10.2c0-.66-.06-1.28-.17-1.88H10v3.56h4.62c-.2 1.08-.82 1.99-1.74 2.6v2.16h2.81c1.64-1.5 2.51-3.72 2.51-6.44Z" fill="#4285F4"/>
<path d="M10 19c2.34 0 4.3-.78 5.73-2.12l-2.81-2.16c-.78.52-1.77.83-2.92.83-2.24 0-4.14-1.51-4.82-3.54H2.29v2.23A8.99 8.99 0 0 0 10 19Z" fill="#34A853"/>
<path d="M5.18 12c-.17-.52-.27-1.07-.27-1.64s.1-1.12.27-1.64V6.49H2.29A9 9 0 0 0 1 10.36c0 1.45.35 2.82 1.29 3.87L5.18 12Z" fill="#FBBC05"/>
<path d="M10 4.05c1.27 0 2.41.44 3.3 1.31l2.47-2.47C14.29 1.41 12.34.5 10 .5A8.99 8.99 0 0 0 2.29 6.49l2.89 2.23C5.86 5.56 7.76 4.05 10 4.05Z" fill="#EA4335"/>
</svg>
''';

  bool _isFormFilled = false;
  bool _obscurePassword = true;
  bool _isForgotPasswordHovered = false;
  bool _isSignUpHovered = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  TapGestureRecognizer? _termsRecognizer;
  TapGestureRecognizer? _privacyRecognizer;

  TapGestureRecognizer get _termsTapRecognizer {
    return _termsRecognizer ??= TapGestureRecognizer()
      ..onTap = () {
        _showSnackBar('Terms of Service will be available soon.');
      };
  }

  TapGestureRecognizer get _privacyTapRecognizer {
    return _privacyRecognizer ??= TapGestureRecognizer()
      ..onTap = () {
        _showSnackBar('Privacy Policy will be available soon.');
      };
  }

  double get _formWidth {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 480;
    if (w >= 768) return 520;
    return double.infinity;
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final filled = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
    if (filled != _isFormFilled) {
      setState(() => _isFormFilled = filled);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
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
          backgroundColor: _SignInColors.background,
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
                  color: _SignInColors.background,
                  borderRadius: BorderRadius.circular(boxRadius),
                  boxShadow: boxShadow,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeading(),
                    const SizedBox(height: 24),
                    _buildGoogleButton(
                      isLoading: actionState.isLoading,
                      onTap: () => _handleGoogleSignIn(ref),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialRow(isLoading: actionState.isLoading),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildForgotPassword(
                      ref: ref,
                      isLoading: actionState.isLoading,
                    ),
                    const SizedBox(height: 24),
                    _buildLoginButton(
                      isLoading: actionState.isLoading,
                      onTap: () => _handleSignIn(ref),
                    ),
                    const SizedBox(height: 20),
                    _buildTermsText(),
                    const SizedBox(height: 20),
                    _buildSignUpLink(),
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
      },
    );
  }

  Widget _buildHeading() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Log in now!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _SignInColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _SignInColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                  fontWeight: FontWeight.bold,
                  color: _SignInColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialRow({required bool isLoading}) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            isLoading: isLoading,
            child: const Icon(
              Icons.facebook,
              color: _SignInColors.facebookBlue,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            isLoading: isLoading,
            child: const Icon(
              Icons.apple,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            isLoading: isLoading,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _MicrosoftLogoPainter()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required Widget child, required bool isLoading}) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
          // TODO: connect social sign-in.
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _SignInColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(color: _SignInColors.border, thickness: 1, height: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or log in with email',
            style: TextStyle(color: _SignInColors.textMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Divider(color: _SignInColors.border, thickness: 1, height: 1),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Email or username',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _SignInColors.textPrimary,
              ),
            ),
            Text(
              'required',
              style: TextStyle(
                fontSize: 12,
                color: _SignInColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontSize: 15,
            color: _SignInColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'email@example.com',
            hintStyle: const TextStyle(
              color: _SignInColors.textMuted,
              fontSize: 14,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _SignInColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _SignInColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: _SignInColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _SignInColors.textPrimary,
              ),
            ),
            Text(
              'required',
              style: TextStyle(
                fontSize: 12,
                color: _SignInColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Password must be at least 8 characters and should have a mixture of letters and other characters',
          style: TextStyle(
            fontSize: 12,
            color: _SignInColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontSize: 15,
            color: _SignInColors.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _SignInColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _SignInColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: _SignInColors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword({
    required WidgetRef ref,
    required bool isLoading,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MouseRegion(
        cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) {
          if (!_isForgotPasswordHovered) {
            setState(() => _isForgotPasswordHovered = true);
          }
        },
        onExit: (_) {
          if (_isForgotPasswordHovered) {
            setState(() => _isForgotPasswordHovered = false);
          }
        },
        child: GestureDetector(
          onTap: isLoading ? null : () => _handleForgotPassword(ref),
          child: Text(
            'Forgot password?',
            style: TextStyle(
              color: _SignInColors.textLink,
              fontSize: 13.5,
              decoration: _isForgotPasswordHovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading || !_isFormFilled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isFormFilled ? _SignInColors.primary : _SignInColors.buttonDisabled,
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
        child: const Text('Log in'),
      ),
    );
  }

  Widget _buildTermsText() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          color: _SignInColors.textPrimary,
          height: 1.5,
        ),
        children: [
          const TextSpan(text: 'By logging in, you agree to the '),
          TextSpan(
            text: 'QiyasReady Terms of Service',
            style: const TextStyle(color: _SignInColors.textLink),
            recognizer: _termsTapRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: const TextStyle(color: _SignInColors.textLink),
            recognizer: _privacyTapRecognizer,
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Need a QiyasReady account? ',
          style: TextStyle(
            fontSize: 13.5,
            color: _SignInColors.textPrimary,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            if (!_isSignUpHovered) {
              setState(() => _isSignUpHovered = true);
            }
          },
          onExit: (_) {
            if (_isSignUpHovered) {
              setState(() => _isSignUpHovered = false);
            }
          },
          child: GestureDetector(
            onTap: _handleSignUpNavigation,
            child: Text(
              'Sign up today',
              style: TextStyle(
                color: _SignInColors.textLink,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                decoration: _isSignUpHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: _SignInColors.textLink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignIn(WidgetRef ref) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty || password.length < 8) {
      _showSnackBar('Password must be at least 8 characters.');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signIn(
          email: email,
          password: password,
        );

    if (!mounted || !success) {
      return;
    }

    _emailController.clear();
    _passwordController.clear();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted || !success) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleForgotPassword(WidgetRef ref) async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showSnackBar('Enter your account email first, then tap Forgot password.');
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).forgotPassword(
              email: email,
            );

    if (!mounted || !success) {
      return;
    }

    _showSnackBar('Password reset email sent. Check your inbox.');
  }

  void _handleSignUpNavigation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MicrosoftLogoPainter extends CustomPainter {
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

