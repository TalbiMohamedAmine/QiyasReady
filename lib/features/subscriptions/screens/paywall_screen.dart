import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/screens/profile_dashboard_screen.dart';
import '../providers/subscriptions_provider.dart';

// ─── Colors ─────────────────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFF1A6BFF);
  static const primaryLight = Color(0xFFE8F0FF);
  static const bg           = Color(0xFFFFFFFF);
  static const surface      = Color(0xFFF7F8FC);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textMuted    = Color(0xFF6B7280);
  static const border       = Color(0xFFE0E0E0);
  static const error        = Color(0xFFDC2626);
  static const success      = Color(0xFF10B981);
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({
    super.key,
    required this.planName,
    required this.planFeatures,
  });

  final String planName;
  final List<String> planFeatures;

  double get monthlyPrice => planName == 'Basic' ? 9.99 : 19.99;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int  _methodIndex  = 0; // 0 = Card, 1 = PayPal
  bool _isProcessing = false;
  String? _errorMessage;

  final _formKey  = GlobalKey<FormState>();
  final _cardCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expCtrl  = TextEditingController();
  final _cvvCtrl  = TextEditingController();

  bool get _isMobile  => MediaQuery.of(context).size.width < 768;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1100;

  @override
  void dispose() {
    _cardCtrl.dispose();
    _nameCtrl.dispose();
    _expCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  // ── Subscribe handler ─────────────────────────────────────────────────────
  Future<void> _onSubscribe() async {
  if (_methodIndex == 0 && !(_formKey.currentState?.validate() ?? false)) {
    return;
  }

  setState(() {
    _isProcessing = true;
    _errorMessage = null;
  });

  final success = await ref
      .read(subscriptionsControllerProvider.notifier)
      .assignPlan(widget.planName);

  if (!mounted) return;

  if (success) {
    setState(() => _isProcessing = false);
    _showSuccess();
  } else {
    setState(() {
      _isProcessing = false;
      _errorMessage = ref.read(subscriptionsControllerProvider).errorMessage
          ?? 'Something went wrong. Please try again.';
    });
  }
}

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: _C.success, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              "You're subscribed!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Your subscription is active. Start preparing for your Qiyas exam.",
              style: TextStyle(
                  fontSize: 14, color: _C.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }
                    ref.read(pendingPlanProvider.notifier).state = null;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileDashboardScreen(),
                      ),
                      (route) => false,
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Start Practicing",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Listen to provider errors passively (catches external invalidations)
    ref.listen<SubscriptionsState>(subscriptionsControllerProvider,
        (previous, next) {
      final prevErr = previous?.errorMessage;
      final nextErr = next.errorMessage;
      if (nextErr != null && nextErr != prevErr && mounted) {
        setState(() => _errorMessage = nextErr);
      }
    });

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _topBar(),
              _isDesktop ? _desktopLayout() : _mobileLayout(),
              _disclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _topBar() => Container(
        height: 56,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _C.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, color: _C.primary, size: 22),
                  Text(
                    "Back",
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "Configure your plan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
            ),
          ],
        ),
      );

  // ── Layouts ───────────────────────────────────────────────────────────────
  Widget _desktopLayout() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _paymentForm()),
                const SizedBox(width: 32),
                SizedBox(width: 340, child: _planSummaryCard()),
              ],
            ),
          ),
        ),
      );

  Widget _mobileLayout() => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 20 : 40,
          vertical: 24,
        ),
        child: Column(
          children: [
            _planSummaryCard(),
            const SizedBox(height: 28),
            _paymentForm(),
          ],
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // PAYMENT FORM
  // ════════════════════════════════════════════════════════════════════════════
  Widget _paymentForm() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment method",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _methodTile(0, Icons.credit_card_outlined, "Card")),
              const SizedBox(width: 12),
              Expanded(
                  child: _methodTile(
                      1, Icons.account_balance_wallet_outlined, "PayPal")),
            ],
          ),
          const SizedBox(height: 24),
          if (_methodIndex == 0) _cardForm() else _paypalNote(),
          // ── Inline error message ──────────────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: _C.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          fontSize: 13, color: _C.error, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _methodTile(int idx, IconData icon, String label) {
    final sel = _methodIndex == idx;
    return GestureDetector(
      onTap: () => setState(() {
        _methodIndex = idx;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 72,
        decoration: BoxDecoration(
          color: sel ? _C.primaryLight : _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: sel ? _C.primary : _C.border, width: sel ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: sel ? _C.primary : _C.textMuted, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? _C.primary : _C.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card form ─────────────────────────────────────────────────────────────
  Widget _cardForm() => Form(
        key: _formKey,
        child: Column(
          children: [
            _fLabel("Card number"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cardCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardFmt(),
                LengthLimitingTextInputFormatter(19),
              ],
              decoration: _deco(
                hint: "0000 0000 0000 0000",
                counterText: "",
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brand("MC", const Color(0xFFEB001B)),
                    const SizedBox(width: 4),
                    _brand("VISA", const Color(0xFF1A1F71)),
                  ],
                ),
              ),
              validator: (v) =>
                  (v?.replaceAll(" ", "").length ?? 0) < 16
                      ? "Enter a valid 16-digit card number"
                      : null,
            ),
            const SizedBox(height: 16),
            _fLabel("Cardholder name"),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _deco(hint: "Name as it appears on card"),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? "Enter the cardholder name"
                      : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fLabel("Expiration date"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _expCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ExpiryFmt(),
                        ],
                        maxLength: 7,
                        decoration:
                            _deco(hint: "MM / YY", counterText: ""),
                        validator: (v) =>
                            (v == null || v.length < 5)
                                ? "Invalid date"
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fLabel("Security code"),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _deco(
                          hint: "CVV",
                          counterText: "",
                          suffix: const Icon(Icons.credit_card,
                              size: 18, color: _C.textMuted),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 3)
                                ? "Invalid CVV"
                                : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_isMobile) _subscribeBtn(),
          ],
        ),
      );

  Widget _paypalNote() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: _C.primary, size: 36),
            const SizedBox(height: 12),
            const Text(
              "You'll be redirected to PayPal to complete your payment.",
              style: TextStyle(
                  fontSize: 14, color: _C.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_isMobile) _subscribeBtn(),
          ],
        ),
      );

  Widget _fLabel(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _C.textPrimary,
        ),
      );

  InputDecoration _deco(
          {required String hint, Widget? suffix, String? counterText}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _C.textMuted, fontSize: 14),
        counterText: counterText,
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: _C.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _C.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: _C.error, width: 1.5)),
      );

  Widget _brand(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // PLAN SUMMARY CARD
  // ════════════════════════════════════════════════════════════════════════════
  Widget _planSummaryCard() {
    final price = widget.monthlyPrice;
    const tax = 0.00;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${widget.planName} Plan",
              style: const TextStyle(
                color: _C.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "QiyasReady ${widget.planName}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "\$${price.toStringAsFixed(2)} / month",
            style: const TextStyle(fontSize: 14, color: _C.textMuted),
          ),
          const SizedBox(height: 20),
          const Text(
            "Top features",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.planFeatures.take(5).map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: _C.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                              fontSize: 13, color: _C.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          const Divider(color: _C.border),
          const SizedBox(height: 16),
          _row("Monthly subscription", "\$${price.toStringAsFixed(2)}"),
          const SizedBox(height: 8),
          _row("Estimated tax", "\$${tax.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          const Divider(color: _C.border),
          const SizedBox(height: 12),
          _row(
            "Due today",
            "\$${(price + tax).toStringAsFixed(2)}",
            bold: true,
            size: 16,
          ),
          const SizedBox(height: 24),
          if (!_isMobile) _subscribeBtn(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_outline, size: 13, color: _C.textMuted),
              SizedBox(width: 4),
              Text(
                "256-bit SSL encryption",
                style: TextStyle(fontSize: 12, color: _C.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v,
      {bool bold = false, double size = 14}) {
    final s = TextStyle(
      fontSize: size,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: _C.textPrimary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(l, style: s), Text(v, style: s)],
    );
  }

  Widget _subscribeBtn() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _onSubscribe,
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7FABFF),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text("Subscribe to ${widget.planName}"),
        ),
      );

  Widget _disclaimer() => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _isDesktop ? 120 : (_isMobile ? 24 : 48),
          vertical: 24,
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                fontSize: 12, color: _C.textMuted, height: 1.6),
            children: [
              const TextSpan(text: "Renews monthly until cancelled. "),
              const TextSpan(
                text: "Cancel anytime",
                style: TextStyle(
                  color: _C.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(
                  text:
                      " in Settings. By subscribing, you agree to our "),
              const TextSpan(
                text: "Terms of Service",
                style: TextStyle(
                  color: _C.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: " and "),
              const TextSpan(
                text: "Privacy Policy",
                style: TextStyle(
                  color: _C.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: "."),
            ],
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// INPUT FORMATTERS
// ══════════════════════════════════════════════════════════════════════════════
class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(" ", "");
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(" ");
      b.write(d[i]);
    }
    final s = b.toString();
    return n.copyWith(
        text: s,
        selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) {
    final d =
        n.text.replaceAll("/", "").replaceAll(" ", "");
    final b = StringBuffer();
    for (int i = 0; i < d.length; i++) {
      if (i == 2) b.write(" / ");
      b.write(d[i]);
    }
    final s = b.toString();
    return n.copyWith(
        text: s,
        selection: TextSelection.collapsed(offset: s.length));
  }
}