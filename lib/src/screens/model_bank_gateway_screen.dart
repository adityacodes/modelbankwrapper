import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model_bank/model_bank_config.dart';
import '../model_bank/model_bank_gateway_service.dart';
import '../model_bank/model_bank_models.dart';
import '../theme/cbd_colors.dart';

class ModelBankGatewayScreen extends StatefulWidget {
  const ModelBankGatewayScreen({super.key});

  @override
  State<ModelBankGatewayScreen> createState() => _ModelBankGatewayScreenState();
}

class _ModelBankGatewayScreenState extends State<ModelBankGatewayScreen> {
  final ModelBankGatewayService _gatewayService = ModelBankGatewayService();
  late final TextEditingController _deepLinkInputController;

  @override
  void initState() {
    super.initState();
    _deepLinkInputController = TextEditingController(
      text: ModelBankConfig.sampleDeepLink,
    );
    _gatewayService.addListener(_onServiceUpdate);
    _gatewayService.init();
  }

  @override
  void dispose() {
    _gatewayService.removeListener(_onServiceUpdate);
    _deepLinkInputController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: CbdColors.limeGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('$label copied to clipboard')),
          ],
        ),
        duration: const Duration(milliseconds: 2000),
        backgroundColor: CbdColors.bannerNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openSettingsDialog() {
    final authUrlCtrl = TextEditingController(
      text: ModelBankConfig.baseAuthUrl,
    );
    final tppUrlCtrl = TextEditingController(
      text: ModelBankConfig.targetTppUrl,
    );
    final issuerCtrl = TextEditingController(
      text: ModelBankConfig.defaultIssuer,
    );
    bool autoLaunch = ModelBankConfig.autoLaunchBrowser;
    bool autoOpen = ModelBankConfig.autoOpenTpp;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: CbdColors.darkLime),
                    const SizedBox(width: 10),
                    const Text(
                      'Gateway Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CbdColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Bank Portal Base Auth URL',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: authUrlCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'TPP Redirect Handoff URL',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: tppUrlCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'https://cbd-flutter.go.link',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Fallback Authorization Issuer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: issuerCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: autoLaunch,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: CbdColors.darkLime,
                  title: const Text(
                    'Auto-Launch In-App Browser',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Automatically open bank portal upon deeplink arrival',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onChanged: (val) {
                    setModalState(() => autoLaunch = val);
                  },
                ),
                SwitchListTile.adaptive(
                  value: autoOpen,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: CbdColors.darkLime,
                  title: const Text(
                    'Auto-Handoff to TPP',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Automatically open target TPP URL once redirect arrives',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onChanged: (val) {
                    setModalState(() => autoOpen = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CbdColors.darkLime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        ModelBankConfig.baseAuthUrl = authUrlCtrl.text.trim();
                        ModelBankConfig.targetTppUrl = tppUrlCtrl.text.trim();
                        ModelBankConfig.defaultIssuer = issuerCtrl.text.trim();
                        ModelBankConfig.autoLaunchBrowser = autoLaunch;
                        ModelBankConfig.autoOpenTpp = autoOpen;
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gateway configuration saved'),
                          backgroundColor: CbdColors.darkLime,
                        ),
                      );
                    },
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = _gatewayService.stage;
    final req = _gatewayService.currentRequest;
    final resp = _gatewayService.currentResponse;
    final targetTppUri = _gatewayService.currentTppForwardUri;
    final bankAuthUri = _gatewayService.currentBankAuthUri;

    return Scaffold(
      backgroundColor: CbdColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CbdColors.bannerNavy,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CbdColors.limeGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: CbdColors.limeGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODEL BANK',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Open Finance AE Gateway',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: CbdColors.limeGreen,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configure Gateway',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _openSettingsDialog,
          ),
          IconButton(
            tooltip: 'Reset Session',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              _gatewayService.resetSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gateway session reset')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gateway Status Banner
            _buildListeningBanner(),
            const SizedBox(height: 16),

            // 2. Visual Pipeline Flow
            _buildPipelineFlow(stage),
            const SizedBox(height: 16),

            // 3. Completed Redirection Result Card (Hero)
            if (resp != null && resp.isSuccess) ...[
              _buildRedirectionResultCard(resp, targetTppUri),
              const SizedBox(height: 16),
            ],

            // 4. In-App Browser Pending / Active Card
            if (stage == GatewayStage.browserActive ||
                stage == GatewayStage.deeplinkReceived) ...[
              _buildBrowserActiveCard(bankAuthUri),
              const SizedBox(height: 16),
            ],

            // 5. Error Card if any
            if (_gatewayService.errorMessage != null) ...[
              _buildErrorCard(_gatewayService.errorMessage!),
              const SizedBox(height: 16),
            ],

            // 6. Deep Link Testing Studio (Manual Simulator)
            _buildTestingStudioCard(),
            const SizedBox(height: 16),

            // 7. Decoded OAuth Parameters Inspector
            if (req != null) ...[
              _buildParametersInspector(req, bankAuthUri),
              const SizedBox(height: 16),
            ],

            // 8. Live Gateway Audit Log
            _buildAuditLogsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Banner showing live listening status
  Widget _buildListeningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CbdColors.bannerNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CbdColors.darkLime.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: CbdColors.limeGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CbdColors.limeGreen,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gateway Active & Listening',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Listening for: auth.mytpp.dpdns.org & openfinance.ae',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CbdColors.darkLime.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CbdColors.limeGreen.withValues(alpha: 0.6),
                width: 0.8,
              ),
            ),
            child: const Text(
              'SANDBOX',
              style: TextStyle(
                color: CbdColors.limeGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visual 4-Step Pipeline Stepper
  Widget _buildPipelineFlow(GatewayStage stage) {
    final step1Done = stage != GatewayStage.idle;
    final step2Done =
        stage == GatewayStage.browserActive ||
        stage == GatewayStage.redirectIntercepted ||
        stage == GatewayStage.forwardedToTpp;
    final step3Done =
        stage == GatewayStage.redirectIntercepted ||
        stage == GatewayStage.forwardedToTpp;
    final step4Done = stage == GatewayStage.forwardedToTpp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CbdColors.border),
        boxShadow: const [CbdColors.fintechShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_outlined, color: CbdColors.darkLime, size: 18),
              SizedBox(width: 8),
              Text(
                'OAuth Lifecycle Pipeline',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CbdColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepItem(
                number: '1',
                title: 'App Link',
                subtitle: 'auth.mytpp.dpdns.org',
                isDone: step1Done,
                isActive: stage == GatewayStage.deeplinkReceived,
              ),
              _buildStepDivider(step2Done),
              _buildStepItem(
                number: '2',
                title: 'In-App Web',
                subtitle: 'Bank Auth',
                isDone: step2Done,
                isActive: stage == GatewayStage.browserActive,
              ),
              _buildStepDivider(step3Done),
              _buildStepItem(
                number: '3',
                title: 'Redirect',
                subtitle: 'code + state',
                isDone: step3Done,
                isActive: stage == GatewayStage.redirectIntercepted,
              ),
              _buildStepDivider(step4Done),
              _buildStepItem(
                number: '4',
                title: 'Handoff',
                subtitle: 'cbd-flutter.go.link',
                isDone: step4Done,
                isActive: stage == GatewayStage.forwardedToTpp,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
  }) {
    Color circleBg = Colors.grey.shade200;
    Color textColor = Colors.grey.shade600;
    Color numberColor = Colors.grey.shade700;

    if (isActive) {
      circleBg = CbdColors.limeGreen;
      textColor = CbdColors.darkLime;
      numberColor = Colors.black87;
    } else if (isDone) {
      circleBg = CbdColors.darkLime;
      textColor = CbdColors.darkLime;
      numberColor = Colors.white;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
            child: Center(
              child: isDone && !isActive
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      number,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: numberColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(bool isCompleted) {
    return Container(
      width: 14,
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isCompleted ? CbdColors.darkLime : Colors.grey.shade300,
    );
  }

  /// Result Card when redirect has been intercepted with `state`, `code`, and `issuer`
  Widget _buildRedirectionResultCard(
    OAuthAuthResponse resp,
    Uri? targetTppUri,
  ) {
    final tppUrlString =
        targetTppUri?.toString() ??
        '${ModelBankConfig.targetTppUrl}?state=${resp.state}&code=${resp.code}&issuer=${resp.issuer}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CbdColors.darkLime, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14388022),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CbdColors.limeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: CbdColors.darkLime,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redirection Intercepted!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CbdColors.textDark,
                      ),
                    ),
                    Text(
                      'State, Code, and Issuer captured from Bank Portal',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: CbdColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CbdColors.darkLime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parameter badges
          _buildParamPill('state', resp.state ?? 'None'),
          const SizedBox(height: 8),
          _buildParamPill('code', resp.code ?? 'None'),
          const SizedBox(height: 8),
          _buildParamPill('issuer', resp.issuer ?? 'None'),
          const SizedBox(height: 16),

          // Target TPP URL Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CbdColors.limeLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CbdColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: CbdColors.deepLime,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Target Handoff URL:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: CbdColors.deepLime,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () =>
                          _copyToClipboard(tppUrlString, 'Target TPP URL'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'COPY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: CbdColors.oceanBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  tppUrlString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: CbdColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action button to open TPP link
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CbdColors.darkLime,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'Open with params in Target TPP App',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _gatewayService.forwardToTpp(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CbdColors.bannerNavy,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: CbdColors.limeGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CbdColors.textDark,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
            onPressed: () => _copyToClipboard(value, label.toUpperCase()),
          ),
        ],
      ),
    );
  }

  /// Browser Active / Launch prompt card
  Widget _buildBrowserActiveCard(Uri? bankAuthUri) {
    final urlStr = bankAuthUri?.toString() ?? ModelBankConfig.baseAuthUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CbdColors.iceBlueLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CbdColors.lightOceanBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    CbdColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'In-App Browser Ready for Bank Auth',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: CbdColors.oceanNavyText,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CbdColors.oceanBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _gatewayService.launchInAppBrowser(),
                child: const Text(
                  'Open Browser',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              urlStr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error display banner
  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF8B4B4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE02424),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFF9B1C1C),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Testing Studio card with the preloaded sample deeplink and simulation buttons
  Widget _buildTestingStudioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CbdColors.border),
        boxShadow: const [CbdColors.fintechShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                color: CbdColors.darkLime,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Testing & Simulation Studio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CbdColors.textDark,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(40, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _deepLinkInputController.text =
                      ModelBankConfig.sampleDeepLink;
                },
                child: const Text(
                  'Sample TPP',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: CbdColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(40, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  _deepLinkInputController.text =
                      ModelBankConfig.sampleApiHubLink;
                },
                child: const Text(
                  'Sample APIHub',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: CbdColors.limeGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Paste or test an incoming authorization link (auth.mytpp.dpdns.org or openfinance.ae):',
            style: TextStyle(fontSize: 12, color: CbdColors.textMuted),
          ),
          const SizedBox(height: 10),

          // Deeplink text area
          TextField(
            controller: _deepLinkInputController,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: CbdColors.darkLime,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Studio Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CbdColors.bannerNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text(
                    'Process & Launch Flow',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    final text = _deepLinkInputController.text.trim();
                    if (text.isNotEmpty) {
                      _gatewayService.handleIncomingDeepLink(text);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CbdColors.darkLime,
                    side: const BorderSide(color: CbdColors.darkLime),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: const Text(
                    'Simulate Handoff',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    _gatewayService.simulateCompletedCallback(
                      state: 'asa',
                      code: 'asasa',
                      issuer: 'asajsa',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card presenting decoded OAuth parameter details
  Widget _buildParametersInspector(OAuthAuthRequest req, Uri? bankAuthUri) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CbdColors.border),
        boxShadow: const [CbdColors.fintechShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.data_object_rounded,
                color: CbdColors.oceanBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Decoded OAuth Parameters',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CbdColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${req.allParams.length} Parameters',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildParamRow('client_id', req.clientId),
          _buildParamRow('response_type', req.responseType),
          _buildParamRow('scope', req.scope),
          _buildParamRow('request_uri', req.requestUri),
          if (req.state != null) _buildParamRow('state', req.state),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // In-App Browser Target URL preview
          Row(
            children: [
              const Icon(
                Icons.language_rounded,
                color: CbdColors.darkLime,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Bank Portal Target URL:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: CbdColors.darkLime,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  if (bankAuthUri != null) {
                    _copyToClipboard(bankAuthUri.toString(), 'Bank Auth URL');
                  }
                },
                child: const Text(
                  'COPY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CbdColors.oceanBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SelectableText(
              bankAuthUri?.toString() ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String key, String? val) {
    if (val == null || val.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              key,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: CbdColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              val,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: CbdColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live Gateway Event Audit Logs terminal section
  Widget _buildAuditLogsSection() {
    final logs = _gatewayService.logs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141E28),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.terminal_rounded,
                color: CbdColors.limeGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Gateway Event Audit Logs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  final text = logs
                      .map(
                        (l) =>
                            '[${l.timestamp.toIso8601String()}] ${l.title}: ${l.description}',
                      )
                      .join('\n');
                  _copyToClipboard(text, 'All Audit Logs');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'EXPORT',
                    style: TextStyle(
                      color: CbdColors.limeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _gatewayService.clearLogs(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'CLEAR',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No log events yet. Waiting for incoming requests.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 25 ? 25 : logs.length,
              separatorBuilder: (_, _) => Divider(
                color: Colors.white.withValues(alpha: 0.08),
                height: 14,
              ),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogTile(log);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLogTile(GatewayLogEntry log) {
    Color typeColor = CbdColors.limeGreen;
    IconData typeIcon = Icons.info_outline;

    switch (log.type) {
      case LogType.deeplink:
        typeColor = const Color(0xFF68D391);
        typeIcon = Icons.arrow_downward_rounded;
        break;
      case LogType.browser:
        typeColor = const Color(0xFF63B3ED);
        typeIcon = Icons.open_in_browser_rounded;
        break;
      case LogType.redirect:
        typeColor = const Color(0xFFFAF089);
        typeIcon = Icons.replay_rounded;
        break;
      case LogType.handoff:
        typeColor = const Color(0xFF48BB78);
        typeIcon = Icons.rocket_launch_rounded;
        break;
      case LogType.error:
        typeColor = const Color(0xFFFC8181);
        typeIcon = Icons.error_outline_rounded;
        break;
      case LogType.info:
        typeColor = Colors.white70;
        typeIcon = Icons.info_outline;
        break;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(typeIcon, color: typeColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    log.title,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SelectableText(
                log.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
