import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../models/status.dart';
import '../stores/report_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';
import '../widgets/status_badge.dart';

class HomeScreen extends StatefulWidget {
  final void Function({String? reportId}) onSeeReports;
  final VoidCallback onSeePayroll;

  const HomeScreen({
    super.key,
    required this.onSeeReports,
    required this.onSeePayroll,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = ReportsStore();

  @override
  void initState() {
    super.initState();
    if (_store.reports.isEmpty) _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    // The backend sorts newest first.
    final ReportItem? latest = _store.reports.isEmpty
        ? null
        : _store.reports.first;

    return Container(
      color: colors.canvas,
      child: RefreshIndicator(
        onRefresh: _store.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _header(colors, latest),
            const SizedBox(height: 14),
            _datePill(colors),
            const SizedBox(height: 20),
            if (latest == null)
              _emptyState(colors)
            else
              ..._cards(colors, latest),
          ],
        ),
      ),
    );
  }

  List<Widget> _cards(AppColors colors, ReportItem latest) {
    final stage = _store.stageOf(latest);
    final stageKind = stage == 4
        ? StatusColorKind.success
        : StatusColorKind.info;
    final next = _nextAction(latest, stage);
    final nextColor = next.color(colors);

    return [
      SectionCard(
        title: 'Current Payroll Period',
        action: CardActionButton(label: 'Details', onTap: widget.onSeePayroll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latest.periodLabel,
              style: TextStyle(
                color: colors.text,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _stat(colors, 'DTR hours', _hours(latest.dtrTally)),
                ),
                Expanded(
                  child: _stat(colors, 'AR tasks', '${latest.arTaskTally}'),
                ),
              ],
            ),
          ],
        ),
      ),
      SectionCard(
        title: 'Submission Status',
        action: CardActionButton(
          label: 'Reports',
          onTap: () => widget.onSeeReports(reportId: latest.id),
        ),
        child: Column(
          children: [
            // AR and DTR are submitted and verified together, so
            // they share a single stage instead of two rows.
            _statusRow(
              colors,
              'AR & DTR',
              ReportsStore.stageLabels[stage - 1],
              stageKind,
            ),
            Divider(
              height: 28,
              thickness: 1,
              color: colors.border.withValues(alpha: 0.5),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSeePayroll,
              child: _statusRow(
                colors,
                'Payroll',
                latest.payrollStatus.label,
                latest.payrollStatus.colorKind,
                chevron: true,
              ),
            ),
          ],
        ),
      ),
      SectionCard(
        title: 'Next Action',
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: nextColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(next.icon, color: nextColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                next.text,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _emptyState(AppColors colors) {
    if (_store.loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_store.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              'Could not load your reports.\n${_store.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _store.load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No reports yet.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _header(AppColors colors, ReportItem? latest) {
    // Prefer the signed-in user; fall back to the report's professor.
    final full = (_store.auth?.user?.name.isNotEmpty ?? false)
        ? _store.auth!.user!.name
        : (latest?.professorName ?? '');
    final name = full.trim().split(RegExp(r'\s+')).first;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.accentActive,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Good morning' : 'Good morning, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back to ARIS',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _datePill(AppColors colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _formattedToday(),
              style: TextStyle(
                color: colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(AppColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.text,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _hours(double h) =>
      h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);

  Widget _statusRow(
    AppColors colors,
    String label,
    String value,
    StatusColorKind kind, {
    bool chevron = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        StatusBadge(label: value, kind: kind),
        if (chevron) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
        ],
      ],
    );
  }

  /// What to show in "Next Action": payroll first once it is available,
  /// otherwise the report's backend stage (1 pending .. 4 accounting).
  _NextAction _nextAction(ReportItem latest, int stage) {
    switch (latest.payrollStatus) {
      case PayrollStatus.available:
        return _NextAction(
          Icons.payments_outlined,
          'Payroll is available for release',
          (c) => c.info,
        );
      case PayrollStatus.received:
        return _NextAction(
          Icons.check_circle_outline,
          'No action required',
          (c) => c.accent,
        );
      case PayrollStatus.notAvailable:
        break;
    }

    return switch (stage) {
      1 => _NextAction(
        Icons.hourglass_empty,
        'Submitted — awaiting verification',
        (c) => c.warning,
      ),
      2 => _NextAction(
        Icons.hourglass_empty,
        'Awaiting Department Secretary verification',
        (c) => c.warning,
      ),
      3 => _NextAction(
        Icons.hourglass_empty,
        'Awaiting HR verification',
        (c) => c.warning,
      ),
      _ => _NextAction(
        Icons.hourglass_empty,
        'Awaiting Accounting verification',
        (c) => c.warning,
      ),
    };
  }

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _NextAction {
  final IconData icon;
  final String text;
  final Color Function(AppColors colors) color;

  const _NextAction(this.icon, this.text, this.color);
}
