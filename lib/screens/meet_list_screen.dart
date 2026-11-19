import 'package:flutter/material.dart';

import '../models/meet_item.dart';
import '../services/meet_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

// ─── Public entry-point ────────────────────────────────────────────────────

/// Standalone scaffold used when navigating directly to the Meet records page.
class MeetListScreen extends StatelessWidget {
  const MeetListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Meet Records',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: const MeetRecordsView(),
    );
  }
}

// ─── Embeddable view (used inside RecordsScreen tab) ──────────────────────

class MeetRecordsView extends StatefulWidget {
  final String? selectedMonth; // e.g. "2026-11"

  const MeetRecordsView({super.key, this.selectedMonth});

  @override
  State<MeetRecordsView> createState() => _MeetRecordsViewState();
}

class _MeetRecordsViewState extends State<MeetRecordsView> {
  final _service = MeetService();

  @override
  void initState() {
    super.initState();
    if (_service.items.isEmpty && !_service.loading) {
      _service.load();
    }
  }

  bool _matchesMonth(String dateStr, String ym) {
    if (dateStr.isEmpty) return true;
    final parts = ym.split('-');
    if (parts.length < 2) return true;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return true;

    // 1. Try standard ISO parse
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null) {
      return parsed.year == year && parsed.month == month;
    }

    // 2. Try matching full month name and year (e.g. "November 15, 2026")
    const monthNames = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final lower = dateStr.toLowerCase();
    final targetMonth = monthNames[month - 1];
    return lower.contains(targetMonth) && lower.contains('$year');
  }

  String _monthLabel(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    const fullMonths = [
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
    return '${fullMonths[month - 1]} $year';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);

    if (_service.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_service.error != null) {
      return _errorState(colors);
    }

    final filtered = widget.selectedMonth == null ||
            widget.selectedMonth!.isEmpty
        ? _service.items
        : _service.items
            .where((m) => _matchesMonth(m.date, widget.selectedMonth!))
            .toList();

    if (filtered.isEmpty) {
      return _emptyState(colors, widget.selectedMonth);
    }

    return RefreshIndicator(
      onRefresh: _service.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final m in filtered) ...[
            _MeetCard(item: m, colors: colors),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _errorState(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Could not load Meet records.\n${_service.error}',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.error, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _service.load,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColors colors, [String? selectedMonth]) {
    final periodText = selectedMonth != null && selectedMonth.isNotEmpty
        ? ' for ${_monthLabel(selectedMonth)}'
        : '';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                size: 40, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No Meet sessions found$periodText.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Individual card ───────────────────────────────────────────────────────

class _MeetCard extends StatelessWidget {
  final MeetItem item;
  final AppColors colors;

  const _MeetCard({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course + status chip (compact header)
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.course,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: item.status, colors: colors),
              ],
            ),

            const SizedBox(height: 8),

            // Meta row
            Row(
              children: [
                _metaItem(colors, Icons.calendar_today_outlined, item.date,
                    flexible: false),
                const SizedBox(width: 14),
                _metaItem(colors, Icons.access_time_outlined, item.duration,
                    flexible: false),
                if (item.meetingCode != null) ...[
                  const SizedBox(width: 14),
                  Flexible(
                    child: _metaItem(
                        colors, Icons.link_outlined, item.meetingCode!,
                        ellipsis: true),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Overview preview
            Text(
              item.overview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            // Footer: words + participants + tap hint
            Row(
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: _pill(colors, item.words)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _participantPill(
                            colors, item.participants.length),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap to expand',
                      style: TextStyle(
                        color: colors.accentActive,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        size: 14, color: colors.accentActive),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(AppColors colors, IconData icon, String label,
      {bool flexible = true, bool ellipsis = false}) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
      style: TextStyle(color: colors.textSecondary, fontSize: 12),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 4),
        flexible ? Flexible(child: text) : text,
      ],
    );
  }

  Widget _pill(AppColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
      ),
    );
  }

  Widget _participantPill(AppColors colors, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(width: 4),
          Icon(Icons.people_outline, size: 13, color: colors.textSecondary),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MeetDetailSheet(item: item),
    );
  }
}

// ─── Detail bottom-sheet ───────────────────────────────────────────────────

class _MeetDetailSheet extends StatefulWidget {
  final MeetItem item;

  const _MeetDetailSheet({required this.item});

  @override
  State<_MeetDetailSheet> createState() => _MeetDetailSheetState();
}

class _MeetDetailSheetState extends State<_MeetDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeScope.colorsOf(context);
    final m = widget.item;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _StatusChip(label: m.status, colors: colors),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.course,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // Info grid
                  Row(
                    children: [
                      _InfoField(
                          label: 'Date', value: m.date, colors: colors),
                      const SizedBox(width: 24),
                      _InfoField(
                          label: 'Time', value: m.time, colors: colors),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoField(
                          label: 'Duration',
                          value: m.duration,
                          colors: colors),
                      const SizedBox(width: 24),
                      _InfoField(
                          label: 'Transcript',
                          value: m.words,
                          colors: colors),
                    ],
                  ),

                  if (m.meetingCode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: colors.accentActive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'Code: ${m.meetingCode}',
                        style: TextStyle(
                          color: colors.accentActive,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],

                  if (m.participants.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Participants: ${m.participants.join(' · ')}',
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Tabs
                  TabBar(
                    controller: _tab,
                    labelColor: colors.accentActive,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: colors.accentActive,
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Full Transcript'),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _SummaryView(item: m, colors: colors),
                  _TranscriptView(item: m, colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary tab ─────────────────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  final MeetItem item;
  final AppColors colors;

  const _SummaryView({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        // Overview
        SectionCard(
          title: 'Overview',
          child: Text(
            item.overview,
            style: TextStyle(
                color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 12),

        // Key Points
        if (item.keyPoints.isNotEmpty)
          SectionCard(
            title: 'Key Points',
            child: Column(
              children: [
                for (final kp in item.keyPoints) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.accentActive,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          kp,
                          style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Decisions
        if (item.decisions.isNotEmpty)
          SectionCard(
            title: 'Decisions & Takeaways',
            child: Column(
              children: [
                for (final d in item.decisions) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle_outline,
                            size: 15, color: colors.accentActive),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d,
                          style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Action Items
        if (item.actions.isNotEmpty)
          SectionCard(
            title: 'Action Items',
            child: Column(
              children: [
                for (var i = 0; i < item.actions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 16,
                      thickness: 1,
                      color: colors.border.withValues(alpha: 0.5),
                    ),
                  _ActionRow(
                      action: item.actions[i], colors: colors),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final MeetActionItem action;
  final AppColors colors;

  const _ActionRow({required this.action, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action.owner,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.task,
                style:
                    TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          action.due,
          style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Transcript tab ───────────────────────────────────────────────────────

class _TranscriptView extends StatelessWidget {
  final MeetItem item;
  final AppColors colors;

  const _TranscriptView({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.videocam_outlined,
                  size: 16, color: colors.accentActive),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recorded via Google Meet · ${item.duration} · ${item.words}',
                  style: TextStyle(
                      color: colors.accentActive, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Lines
        if (item.transcript.isEmpty)
          Text(
            'No transcript available for this session.',
            style:
                TextStyle(color: colors.textSecondary, fontSize: 13),
          )
        else
          for (final line in item.transcript) ...[
            _TranscriptLine(line: line, colors: colors),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _TranscriptLine extends StatelessWidget {
  final MeetTranscriptLine line;
  final AppColors colors;

  const _TranscriptLine({required this.line, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            line.t,
            style: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.6),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.who,
                style: TextStyle(
                  color: colors.accentActive,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                line.text,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final AppColors colors;

  const _StatusChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: colors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.success,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;

  const _InfoField({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: colors.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
