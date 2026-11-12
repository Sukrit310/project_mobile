// หน้าต้อนรับเพียงหน้าเดียว ส่งต่อการเริ่มใช้งานให้ root flow เดิมดูแล
import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          final illustrationSize = (constraints.maxHeight * 0.26).clamp(
            112.0,
            220.0,
          );
          // minHeight ดันปุ่มลงด้านล่างเมื่อมีพื้นที่ และปล่อยให้เลื่อนเมื่อตัวอักษรใหญ่/จอเตี้ย
          final contentHeight = (constraints.maxHeight - 48).clamp(
            0.0,
            double.infinity,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  minHeight: contentHeight,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: compact ? 0 : 24),
                        _WalletIllustration(size: illustrationSize),
                        const SizedBox(height: 28),
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'MoneyMate',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 38,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'จัดการรายรับรายจ่าย\nให้ง่ายขึ้นทุกวัน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'บันทึกค่าใช้จ่าย ติดตามงบประมาณ\nและดูภาพรวมการเงินของคุณได้ในที่เดียว',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            key: const Key('welcome-start'),
                            onPressed: onGetStarted,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              minimumSize: const Size(48, 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'เริ่มต้นใช้งาน',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward_rounded, size: 22),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'เริ่มวางแผนการเงินในแบบของคุณ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// ภาพประกอบวาดจาก Flutter/Material Icons ไม่มีจำนวนเงินสมมติหรือทรัพยากรจากเครือข่าย
class _WalletIllustration extends StatelessWidget {
  const _WalletIllustration({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'ภาพประกอบกระเป๋าเงิน',
    child: ExcludeSemantics(
      child: SizedBox(
        width: size + 36,
        height: size + 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.mintSurface,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: size * 0.63,
              height: size * 0.63,
              decoration: BoxDecoration(
                color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDeep.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.mintSurface,
                size: size * 0.32,
              ),
            ),
            Positioned(
              left: 0,
              top: 12,
              child: _AbstractCard(
                icon: Icons.south_west_rounded,
                color: AppColors.income,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.mintSurface,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 20,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.outline,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 6,
              child: _AbstractCard(
                icon: Icons.bar_chart_rounded,
                color: AppColors.primary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final height in [12.0, 22.0, 17.0]) ...[
                      Container(
                        width: 7,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AbstractCard extends StatelessWidget {
  const _AbstractCard({
    required this.icon,
    required this.color,
    required this.child,
  });
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outline),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 10),
        child,
      ],
    ),
  );
}
