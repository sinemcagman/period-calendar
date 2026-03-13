import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import '../models/daily_log.dart';
import 'daily_log_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isOvulationDay(DateTime day, DateTime? predictedOvulation) {
    if (predictedOvulation == null) return false;
    return isSameDay(day, predictedOvulation);
  }

  bool _isExpectedPeriod(DateTime day, DateTime? predictedNext) {
    if (predictedNext == null) return false;
    DateTime next = predictedNext;
    DateTime endExpected = next.add(const Duration(days: 4));
    
    DateTime check = DateTime(day.year, day.month, day.day);
    next = DateTime(next.year, next.month, next.day);
    endExpected = DateTime(endExpected.year, endExpected.month, endExpected.day);

    if ((check.isAtSameMomentAs(next) || check.isAfter(next)) && 
        (check.isAtSameMomentAs(endExpected) || check.isBefore(endExpected))) {
      return true;
    }
    return false;
  }

  DailyLog? _getLogForDay(DateTime day, List<DailyLog> logs) {
    String dayStr = day.toIso8601String().substring(0, 10);
    try {
      return logs.firstWhere((log) => log.date.toIso8601String().substring(0, 10) == dayStr);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cycleProvider = Provider.of<CycleProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat.yMMMM('tr_TR').format(_focusedDay), 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bugün: ${DateFormat('EEEE, d MMMM', 'tr_TR').format(DateTime.now())}",
                        style: const TextStyle(fontSize: 14, color: AppColors.brandPink, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: AppColors.textSecondaryDark, size: 20),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
                                });
                              },
                            ),
                            Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.1)),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark, size: 20),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            // Calendar Body
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      locale: 'tr_TR',
                      headerVisible: false,
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondaryDark, fontWeight: FontWeight.w600, fontSize: 12),
                        weekendStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondaryDark, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          bool isPeriod = cycleProvider.isDayPeriod(day);
                          bool isOvu = _isOvulationDay(day, cycleProvider.predictedOvulation);
                          bool isExpected = _isExpectedPeriod(day, cycleProvider.predictedNextPeriod);

                          if (isPeriod) {
                            return _buildCell(day, AppColors.periodPink, AppColors.periodPink, Colors.white, false);
                          } else if (isOvu) {
                            return _buildCell(day, AppColors.ovulationLight, AppColors.periodPink, AppColors.periodPink, true);
                          } else if (isExpected) {
                            return _buildCell(day, Colors.transparent, Colors.grey.shade600, Colors.grey.shade400, true);
                          }

                          Color defaultTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
                          return Center(child: Text('${day.day}', style: TextStyle(color: defaultTextColor)));
                        },
                        todayBuilder: (context, day, focusedDay) {
                          bool isPeriod = cycleProvider.isDayPeriod(day);
                          if (isPeriod) {
                            return _buildCell(day, AppColors.periodPink, AppColors.periodPink, Colors.white, false);
                          }
                          Color todayTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
                          return _buildCell(day, Theme.of(context).cardColor, Theme.of(context).disabledColor.withValues(alpha: 0.1), todayTextColor, false);
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          bool isPeriod = cycleProvider.isDayPeriod(day);
                          if (isPeriod) {
                            // Period day selected: solid red/pink
                            return _buildCell(day, AppColors.periodPink, Colors.white, Colors.white, false);
                          }
                          // Non-period day selected: neutral highlight with thin border
                          Color textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
                          return _buildCell(day, Colors.transparent, AppColors.brandPink, textColor, false);
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return Center(child: Text('${day.day}', style: TextStyle(color: Theme.of(context).disabledColor)));
                        },
                      ),
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                    const Spacer(),
                    
                    // Legend
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLegendItem(AppStrings.legendPeriod, AppColors.periodPink, true),
                          _buildLegendItem(AppStrings.legendOvulation, AppColors.periodPink, false, true),
                          _buildLegendItem(AppStrings.legendExpected, Colors.grey.shade600, false, true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Daily Log Viewer
            _buildLogViewer(cycleProvider),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  // Toggle Period Day Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          cycleProvider.isDayPeriod(_selectedDay ?? DateTime.now())
                              ? Icons.remove_circle_outline
                              : Icons.water_drop,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          cycleProvider.isDayPeriod(_selectedDay ?? DateTime.now())
                              ? "Regl Sil"
                              : "Regl İşaretle",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          DateTime selected = _selectedDay ?? now;
                          if (selected.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gelecek tarihler için kayıt giremezsiniz.'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          await cycleProvider.togglePeriodDay(selected);
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cycleProvider.isDayPeriod(_selectedDay ?? DateTime.now())
                              ? Colors.grey.shade700
                              : AppColors.periodPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Daily Log Button
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          _getLogForDay(_selectedDay ?? DateTime.now(), cycleProvider.dailyLogs) != null
                              ? Icons.edit_note
                              : Icons.note_add,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          _getLogForDay(_selectedDay ?? DateTime.now(), cycleProvider.dailyLogs) != null
                              ? "Günlüğü Düzenle"
                              : "Günlük Ekle",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        onPressed: () async {
                          DateTime now = DateTime.now();
                          DateTime selected = _selectedDay ?? now;
                          if (selected.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59))) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gelecek tarihler için günlük giremezsiniz.'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DailyLogScreen(selectedDate: selected),
                            ),
                          );
                          // Reload data when returning from daily log screen
                          if (result == true && mounted) {
                            await cycleProvider.loadData();
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogViewer(CycleProvider provider) {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    DailyLog? log = _getLogForDay(_selectedDay!, provider.dailyLogs);
    if (log == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_document, color: AppColors.brandPink, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.MMMMd('tr_TR').format(_selectedDay!),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, provider, _selectedDay!);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (log.moodTypes.isNotEmpty) ...[
            Wrap(
              spacing: 6.0,
              runSpacing: 4.0,
              children: log.moodTypes.map((m) => Chip(
                label: Text(m, style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.periodPink.withValues(alpha: 0.15),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
              )).toList(),
            ),
          ],
          if (log.physicalSymptoms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: log.physicalSymptoms.map((sym) => Chip(
                label: Text(sym, style: const TextStyle(fontSize: 10)),
                backgroundColor: AppColors.brandPink.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: -4),
              )).toList(),
            ),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Not: ${log.notes}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
          ]
        ],
      ),
    );
  }

  Widget _buildCell(DateTime day, Color bgColor, Color borderColor, Color textColor, bool isDashed) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.0),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color, bool isFilled, [bool isDashed = false]) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
      ],
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, CycleProvider provider, DateTime date) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Kaydı Sil", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Bu güne ait günlüğü silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await provider.deleteDailyLog(date);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Günlük kayıt silindi.'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Sil', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
