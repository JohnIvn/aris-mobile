import 'package:flutter/material.dart';

import '../models/report_item.dart';
import '../stores/report_stores.dart';
import '../theme/app_colors.dart';
import '../theme/theme_scope.dart';
import '../widgets/section_card.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final _store = ReportsStore();
  String? _selectedReportId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (_store.reports.isEmpty) _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final colors = ThemeScope.colorsOf(context);
        final report = _selectedReportId == null
            ? (_store.reports.isEmpty ? null : _store.reports.first)
            : _store.byId(_selectedReportId!);

        return Container(
          color: colors.canvas,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                'Submit',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose what you want to send for review.',
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              _choiceCard(
                colors,
                icon: Icons.access_time_rounded,
                title: 'DTR',
                description: 'Submit all attendance records for one month.',
                enabled: true,
                onTap: () => _submitDtr(context, report),
              ),
              const SizedBox(height: 12),
              _choiceCard(
                colors,
                icon: Icons.description_outlined,
                title: 'AR',
                description: 'AR submission will be available soon.',
                enabled: false,
              ),
              if (report != null) ...[
                const SizedBox(height: 20),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DTR month',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: report.id,
                          isExpanded: true,
                          dropdownColor: colors.surface,
                          items: [
                            for (final item in _store.reports)
                              DropdownMenuItem(
                                value: item.id,
                                child: Text(item.periodLabel),
                              ),
                          ],
                          onChanged: _submitting
                              ? null
                              : (id) => setState(() {
                                  _selectedReportId = id;
                                }),
                        ),
                      ),
                      Text(
                        '${_store.dtrEntriesOf(report).length} daily records will be submitted together.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_store.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_store.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _store.error!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _choiceCard(
    AppColors colors, {
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return SectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: enabled ? colors.accentActive : colors.textSecondary,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(description),
        trailing: enabled
            ? Icon(Icons.chevron_right, color: colors.accentActive)
            : const Text('Soon'),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Future<void> _submitDtr(BuildContext context, ReportItem? report) async {
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No monthly DTR records available.')),
      );
      return;
    }
    final entries = _store.dtrEntriesOf(report);
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No DTR records for ${report.periodLabel}.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _store.submitDtrMonth(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${report.periodLabel} DTR submitted for review.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
