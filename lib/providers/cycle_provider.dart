import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/cycle.dart';
import '../models/daily_log.dart';

class CycleProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  List<Cycle> cycles = [];
  List<DailyLog> dailyLogs = [];
  int waterGlassesToday = 0;
  
  /// Set of individual period day strings (yyyy-MM-dd) for manual marking
  Set<String> periodDays = {};
  
  int averageCycleLength = 28;
  
  CycleProvider() {
    loadData();
  }

  Future<void> loadData() async {
    final db = await _db.database;
    
    // Cycles
    final cyclesRes = await db.query('cycles', orderBy: 'start_date DESC');
    cycles = cyclesRes.map((c) => Cycle.fromMap(c)).toList();
    
    if (cycles.length >= 2) {
      // Calculate real average
      int totalDays = 0;
      int validCycles = 0;
      for (int i = 0; i < cycles.length - 1; i++) {
        totalDays += cycles[i].startDate.difference(cycles[i+1].startDate).inDays;
        validCycles++;
      }
      if (validCycles > 0) averageCycleLength = (totalDays / validCycles).round();
    }
    
    // Build periodDays set from cycles
    periodDays.clear();
    for (var cycle in cycles) {
      DateTime start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      DateTime end = cycle.endDate != null
          ? DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day)
          : start; // Only the start day itself, no auto 5-day assumption
      for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        periodDays.add(d.toIso8601String().substring(0, 10));
      }
    }
    
    // Daily Logs
    final logsRes = await db.query('daily_logs');
    dailyLogs = logsRes.map((l) => DailyLog.fromMap(l)).toList();
    
    // Water
    String today = DateTime.now().toIso8601String().substring(0, 10);
    final waterRes = await db.query('water_intake', where: 'date = ?', whereArgs: [today]);
    if (waterRes.isNotEmpty) {
      waterGlassesToday = waterRes.first['amount'] as int;
    } else {
      waterGlassesToday = 0;
    }
    
    notifyListeners();
  }

  /// Toggle a single day as period day.
  /// If the day is already marked, unmark it.
  /// If the day is new, add it to the latest cycle or create a new one.
  Future<void> togglePeriodDay(DateTime day) async {
    final db = await _db.database;
    DateTime normalized = DateTime(day.year, day.month, day.day);
    String dayStr = normalized.toIso8601String().substring(0, 10);

    if (periodDays.contains(dayStr)) {
      // UNMARK: Remove this day from its cycle
      await _removeDayFromCycle(db, normalized);
    } else {
      // MARK: Add this day to an existing adjacent cycle or create a new one
      await _addDayToCycle(db, normalized);
    }
    await loadData();
  }

  Future<void> _addDayToCycle(Database db, DateTime day) async {
    // Find if there's a cycle whose range is adjacent to or contains this day
    Cycle? matchingCycle;
    for (var cycle in cycles) {
      DateTime start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      DateTime end = cycle.endDate != null
          ? DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day)
          : start;
      
      DateTime dayBefore = day.subtract(const Duration(days: 1));
      DateTime dayAfter = day.add(const Duration(days: 1));

      // If this day is adjacent to or within an existing cycle's range
      bool isAdjacent = (day.isAtSameMomentAs(dayBefore) || 
                         day.isAtSameMomentAs(dayAfter) ||
                         (day.isAfter(start.subtract(const Duration(days: 1))) && 
                          day.isBefore(end.add(const Duration(days: 2)))));
      
      if (isAdjacent) {
        matchingCycle = cycle;
        break;
      }
    }

    if (matchingCycle != null) {
      // Expand the existing cycle
      DateTime start = DateTime(matchingCycle.startDate.year, matchingCycle.startDate.month, matchingCycle.startDate.day);
      DateTime end = matchingCycle.endDate != null
          ? DateTime(matchingCycle.endDate!.year, matchingCycle.endDate!.month, matchingCycle.endDate!.day)
          : start;

      DateTime newStart = day.isBefore(start) ? day : start;
      DateTime newEnd = day.isAfter(end) ? day : end;

      await db.update('cycles', {
        'start_date': newStart.toIso8601String(),
        'end_date': newEnd.toIso8601String(),
      }, where: 'id = ?', whereArgs: [matchingCycle.id]);
    } else {
      // Create a brand new cycle for this single day
      await db.insert('cycles', {
        'start_date': day.toIso8601String(),
        'end_date': day.toIso8601String(),
      });
    }
  }

  Future<void> _removeDayFromCycle(Database db, DateTime day) async {
    // Find the cycle containing this day
    for (var cycle in cycles) {
      DateTime start = DateTime(cycle.startDate.year, cycle.startDate.month, cycle.startDate.day);
      DateTime end = cycle.endDate != null
          ? DateTime(cycle.endDate!.year, cycle.endDate!.month, cycle.endDate!.day)
          : start;

      if ((day.isAtSameMomentAs(start) || day.isAfter(start)) &&
          (day.isAtSameMomentAs(end) || day.isBefore(end))) {
        // This cycle contains the day
        if (start.isAtSameMomentAs(end)) {
          // Single day cycle, delete entirely
          await db.delete('cycles', where: 'id = ?', whereArgs: [cycle.id]);
        } else if (day.isAtSameMomentAs(start)) {
          // Shrink from start
          await db.update('cycles', {
            'start_date': start.add(const Duration(days: 1)).toIso8601String(),
          }, where: 'id = ?', whereArgs: [cycle.id]);
        } else if (day.isAtSameMomentAs(end)) {
          // Shrink from end
          await db.update('cycles', {
            'end_date': end.subtract(const Duration(days: 1)).toIso8601String(),
          }, where: 'id = ?', whereArgs: [cycle.id]);
        } else {
          // Day is in the middle — split into two cycles
          await db.update('cycles', {
            'end_date': day.subtract(const Duration(days: 1)).toIso8601String(),
          }, where: 'id = ?', whereArgs: [cycle.id]);
          await db.insert('cycles', {
            'start_date': day.add(const Duration(days: 1)).toIso8601String(),
            'end_date': end.toIso8601String(),
          });
        }
        break;
      }
    }
  }

  /// Legacy addCycle — now with duplicate prevention.
  /// If a cycle already exists that overlaps this date range, update it instead.
  Future<void> addCycle(DateTime start, DateTime? end) async {
    final db = await _db.database;
    
    // Check if another cycle in the same ~30 day window already exists
    DateTime windowStart = start.subtract(const Duration(days: 15));
    DateTime windowEnd = start.add(const Duration(days: 15));
    
    final existing = await db.rawQuery(
      'SELECT * FROM cycles WHERE start_date >= ? AND start_date <= ? ORDER BY start_date DESC LIMIT 1',
      [windowStart.toIso8601String(), windowEnd.toIso8601String()]
    );
    
    if (existing.isNotEmpty) {
      // Update existing cycle's start_date to the new one
      int existingId = existing.first['id'] as int;
      await db.update('cycles', {
        'start_date': start.toIso8601String(),
        'end_date': end?.toIso8601String(),
      }, where: 'id = ?', whereArgs: [existingId]);
    } else {
      final newCycle = Cycle(startDate: start, endDate: end);
      await db.insert('cycles', newCycle.toMap());
    }
    await loadData();
  }

  Future<void> updateCycleEnd(int id, DateTime end) async {
    final db = await _db.database;
    final cycle = cycles.firstWhere((c) => c.id == id);
    final updatedCycle = Cycle(id: id, startDate: cycle.startDate, endDate: end);
    await db.update('cycles', updatedCycle.toMap(), where: 'id = ?', whereArgs: [id]);
    await loadData();
  }
  
  Future<void> deleteCycle(int id) async {
    final db = await _db.database;
    await db.delete('cycles', where: 'id = ?', whereArgs: [id]);
    await loadData();
  }

  // Core Algorithms
  DateTime? get predictedNextPeriod {
    if (cycles.isEmpty) return null;
    return cycles.first.startDate.add(Duration(days: averageCycleLength));
  }

  DateTime? get predictedOvulation {
    DateTime? next = predictedNextPeriod;
    if (next == null) return null;
    return next.subtract(const Duration(days: 14));
  }

  int get currentCycleGap {
    if (cycles.isEmpty) return 0;
    Cycle current = cycles.first;
    if (current.endDate == null) {
      return DateTime.now().difference(current.startDate).inDays + 1;
    } else {
      return DateTime.now().difference(current.endDate!).inDays;
    }
  }

  /// Check if a specific day is marked as a period day
  bool isDayPeriod(DateTime day) {
    String dayStr = DateTime(day.year, day.month, day.day).toIso8601String().substring(0, 10);
    return periodDays.contains(dayStr);
  }

  // Water Tracker
  Future<void> addWaterGlass() async {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await _db.database;
    final waterRes = await db.query('water_intake', where: 'date = ?', whereArgs: [today]);
    
    if (waterRes.isEmpty) {
      await db.insert('water_intake', {'date': today, 'amount': 1});
    } else {
      int current = waterRes.first['amount'] as int;
      await db.update('water_intake', {'amount': current + 1}, where: 'date = ?', whereArgs: [today]);
    }
    await loadData();
  }
  
  Future<void> removeWaterGlass() async {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await _db.database;
    final waterRes = await db.query('water_intake', where: 'date = ?', whereArgs: [today]);
    
    if (waterRes.isNotEmpty) {
      int current = waterRes.first['amount'] as int;
      if (current > 0) {
        await db.update('water_intake', {'amount': current - 1}, where: 'date = ?', whereArgs: [today]);
        await loadData();
      }
    }
  }
  
  // Daily Logs
  Future<void> saveDailyLog(DateTime date, List<String> moods, List<String> symptoms, String notes) async {
    final db = await _db.database;
    final log = DailyLog(
      date: date, 
      moodTypes: moods, 
      physicalSymptoms: symptoms, 
      notes: notes
    );
    
    String dateStr = date.toIso8601String().substring(0, 10);
    
    // UPSERT logic
    int count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM daily_logs WHERE date = ?', [dateStr])
    ) ?? 0;
    
    if (count > 0) {
      await db.update('daily_logs', log.toMap(), where: 'date = ?', whereArgs: [dateStr]);
    } else {
      await db.insert('daily_logs', log.toMap());
    }
    await loadData();
  }

  Future<void> deleteDailyLog(DateTime date) async {
    final db = await _db.database;
    String dateStr = date.toIso8601String().substring(0, 10);
    await db.delete('daily_logs', where: 'date = ?', whereArgs: [dateStr]);
    await loadData();
  }
}
