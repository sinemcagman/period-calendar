import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/reminder.dart';
import '../services/notification_service.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final db = await _db.database;
    final res = await db.query('reminders', orderBy: 'trigger_time ASC');
    setState(() {
      _reminders = res.map((r) => Reminder.fromMap(r)).toList();
    });
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final db = await _db.database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [reminder.id]);
    await NotificationService.cancelTask(reminder.id!);
    _loadReminders();
  }

  Future<void> _addReminder() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    TextEditingController controller = TextEditingController();
    String recurrenceTypeLocal = 'none';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(dialogContext).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(AppStrings.addReminder, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Örn: İlaç saati',
                      filled: true,
                      fillColor: Theme.of(dialogContext).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  const Text("Tekrar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: recurrenceTypeLocal,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(dialogContext).scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'none', child: Text('Tek Seferlik')),
                      DropdownMenuItem(value: 'daily', child: Text('Her gün')),
                      DropdownMenuItem(value: 'weekly', child: Text('Her hafta')),
                      DropdownMenuItem(value: 'monthly', child: Text('Her ay')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          recurrenceTypeLocal = val;
                        });
                      }
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false), 
                  child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );

    // After dialog closes, check result and save
    if (saved == true && controller.text.isNotEmpty && mounted) {
      DateTime schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (schedule.isBefore(DateTime.now()) && recurrenceTypeLocal == 'none') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geçmiş zamana hatırlatıcı kurulamaz.'), backgroundColor: AppColors.error),
          );
        }
        return;
      }

      final db = await _db.database;
      int id = await db.insert('reminders', {
        'text': controller.text,
        'trigger_time': schedule.toIso8601String(),
        'is_active': 1,
        'recurrence_type': recurrenceTypeLocal,
      });

      await NotificationService.scheduleNotification(
        id: id, 
        title: 'Hatırlatıcı', 
        body: controller.text, 
        scheduledDate: schedule,
        recurrenceType: recurrenceTypeLocal,
      );

      // Explicitly reload and setState to refresh the list immediately
      if (mounted) {
        final db2 = await _db.database;
        final res = await db2.query('reminders', orderBy: 'trigger_time ASC');
        setState(() {
          _reminders = res.map((r) => Reminder.fromMap(r)).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.remindersTitle),
      ),
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  Text(AppStrings.noReminders, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandPink.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.alarm, color: AppColors.brandPink),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(reminder.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (reminder.recurrenceType != 'none') 
                          const Icon(Icons.repeat, size: 14, color: AppColors.brandPink)
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(reminder.triggerTime),
                          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        ),
                        if (reminder.recurrenceType != 'none')
                          Text(
                            _getRecurrenceLabel(reminder.recurrenceType),
                            style: const TextStyle(color: AppColors.brandPink, fontSize: 10, fontWeight: FontWeight.bold),
                          )
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteReminder(reminder),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPink,
        onPressed: _addReminder,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getRecurrenceLabel(String type) {
    switch (type) {
      case 'daily': return 'Her gün';
      case 'weekly': return 'Her hafta';
      case 'monthly': return 'Her ay';
      default: return '';
    }
  }
}
