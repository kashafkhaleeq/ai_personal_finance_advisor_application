import 'package:flutter/material.dart';

class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  static const _green = Color(0xFF2E7D32);
  static const _muted = Color(0xFF6B7280);
  static const _bg = Color(0xFFF7F9F7);
  static const _border = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Personalized tips',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A))),
                  ),
                  _tipCard(
                    iconBg: Color(0xFFFFEBEE), icon: '🚨',
                    badgeText: 'Action needed', badgeType: _BadgeType.bad,
                    title: 'Food budget 97% used',
                    body: 'You\'ve spent Rs 19,400 of your Rs 20,000 food budget with 8 days left. Reduce dining out to stay on track.',
                  ),
                  const SizedBox(height: 10),
                  _tipCard(
                    iconBg: Color(0xFFFFF8E1), icon: '⚡',
                    badgeText: 'Watch out', badgeType: _BadgeType.warn,
                    title: 'Thursday spike detected',
                    body: 'Your Thursday spending is consistently highest. Consider setting a daily limit for mid-week.',
                  ),
                  const SizedBox(height: 10),
                  _tipCard(
                    iconBg: Color(0xFFE8F5E9), icon: '💪',
                    badgeText: 'Well done', badgeType: _BadgeType.good,
                    title: 'Entertainment under budget',
                    body: 'Only 23% of your fun budget used. Great restraint — you have Rs 3,850 of breathing room.',
                  ),
                  const SizedBox(height: 10),
                  _tipCard(
                    iconBg: Color(0xFFE8F5E9), icon: '📊',
                    badgeText: 'Insight', badgeType: _BadgeType.good,
                    title: 'Saving opportunity',
                    body: 'If you stay at current pace in Bills & Transport, you could save Rs 7,800 by month end.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO SCORE SECTION ────────────────────────────────────
  Widget _buildHero() {
    return Container(
      color: _green,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial health score',
              style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('72',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                      height: 1)),
              SizedBox(width: 12),
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('/ 100',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Good · Keep it up!',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── TIP CARD ──────────────────────────────────────────────
  Widget _tipCard({
    required Color iconBg,
    required String icon,
    required String badgeText,
    required _BadgeType badgeType,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _badge(badgeText, badgeType),
                const SizedBox(height: 3),
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: _muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, _BadgeType type) {
    Color bg, fg;
    switch (type) {
      case _BadgeType.good: bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); break;
      case _BadgeType.warn: bg = const Color(0xFFFFF8E1); fg = const Color(0xFFF57F17); break;
      case _BadgeType.bad:  bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

enum _BadgeType { good, warn, bad }