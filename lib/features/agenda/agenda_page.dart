import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/widgets/ui.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/repositories/os_repository.dart';
import '../os/widgets/os_card.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  CalendarFormat _format = CalendarFormat.month;
  Map<DateTime, List<OrdemServico>> _events = {};
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(_focused);
  }

  Future<void> _load(DateTime month) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final start = DateTime(month.year, month.month - 1, 20);
    final end = DateTime(month.year, month.month + 1, 10);
    try {
      final list = await context.read<OsRepository>().calendario(start, end);
      final map = <DateTime, List<OrdemServico>>{};
      for (final os in list) {
        final from = os.dataInicial;
        if (from == null) continue;
        final to = os.dataFinal != null && !os.dataFinal!.isBefore(from) ? os.dataFinal! : from;
        // Exibe a OS em todos os dias do período (limitado a 60 dias).
        var d = DateUtils.dateOnly(from);
        for (var i = 0; i < 60 && !d.isAfter(to); i++) {
          (map[d] ??= []).add(os);
          d = d.add(const Duration(days: 1));
        }
      }
      if (mounted) setState(() => _events = map);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrdemServico> _eventsFor(DateTime day) => _events[DateUtils.dateOnly(day)] ?? const [];

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsFor(_selected);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _focused = now;
                _selected = DateUtils.dateOnly(now);
              });
              _load(now);
            },
            child: const Text('Hoje'),
          ),
        ],
        bottom: _loading
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: ContentWidth(
        maxWidth: 820,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.xs, Gaps.lg, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Gaps.sm),
                    child: TableCalendar<OrdemServico>(
                      locale: 'pt_BR',
                      firstDay: DateTime(2015),
                      lastDay: DateTime(2100),
                      focusedDay: _focused,
                      calendarFormat: _format,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Mês',
                        CalendarFormat.twoWeeks: '2 semanas',
                        CalendarFormat.week: 'Semana',
                      },
                      selectedDayPredicate: (d) => isSameDay(d, _selected),
                      eventLoader: _eventsFor,
                      onDaySelected: (sel, foc) => setState(() {
                        _selected = DateUtils.dateOnly(sel);
                        _focused = foc;
                      }),
                      onFormatChanged: (f) => setState(() => _format = f),
                      onPageChanged: (f) {
                        _focused = f;
                        _load(f);
                      },
                      headerStyle: HeaderStyle(
                        titleCentered: true,
                        titleTextStyle: context.text.titleMedium!,
                        formatButtonDecoration: BoxDecoration(
                          border: Border.all(color: context.tokens.border),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        formatButtonTextStyle: context.text.labelMedium!,
                        leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                        rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: context.text.labelSmall!.copyWith(color: context.tokens.muted),
                        weekendStyle: context.text.labelSmall!.copyWith(color: context.tokens.muted),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                        selectedDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        defaultTextStyle: context.text.bodyMedium!,
                        weekendTextStyle: context.text.bodyMedium!,
                        markersMaxCount: 3,
                        markerSize: 5,
                        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (events.isEmpty) return null;
                          return Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final os in events.take(3))
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(color: StatusColors.of(os.status), shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
                child: SectionHeader(
                  '${Fmt.dateShort(_selected)} · ${dayEvents.length} ${dayEvents.length == 1 ? 'ordem' : 'ordens'}',
                ),
              ),
            ),
            if (_error != null)
              SliverToBoxAdapter(child: ErrorView(error: _error!, onRetry: () => _load(_focused)))
            else if (dayEvents.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyView(icon: Icons.event_available_outlined, title: 'Nenhuma OS neste dia'),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.xxl + Gaps.systemBottom(context)),
                sliver: SliverList.separated(
                  itemCount: dayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Gaps.sm),
                  itemBuilder: (context, i) => OsCard(os: dayEvents[i], onChanged: () => _load(_focused)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
