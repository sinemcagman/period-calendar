import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class DailyLogScreen extends StatefulWidget {
  /// If provided, the screen opens for this specific date (pushed as a route from calendar).
  /// If null, it opens for today (used as a tab in dashboard).
  final DateTime? selectedDate;
  const DailyLogScreen({super.key, this.selectedDate});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late DateTime _logDate;
  final List<String> _selectedMoods = [];
  final List<String> _selectedSymptoms = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isEditing = false; // true if editing an existing log

  /// Whether this screen was pushed as a separate route (from calendar) or used as a tab
  bool get _isPushedRoute => widget.selectedDate != null;

  @override
  void initState() {
    super.initState();
    _logDate = widget.selectedDate ?? DateTime.now();
    // Load existing log for this date after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingLog();
    });
  }

  void _loadExistingLog() {
    final provider = Provider.of<CycleProvider>(context, listen: false);
    String dayStr = DateTime(_logDate.year, _logDate.month, _logDate.day)
        .toIso8601String()
        .substring(0, 10);
    
    try {
      final existingLog = provider.dailyLogs.firstWhere(
        (log) => log.date.toIso8601String().substring(0, 10) == dayStr,
      );
      // Pre-fill the form with existing data
      setState(() {
        _isEditing = true;
        _selectedMoods.clear();
        _selectedMoods.addAll(existingLog.moodTypes);
        _selectedSymptoms.clear();
        _selectedSymptoms.addAll(existingLog.physicalSymptoms);
        _notesController.text = existingLog.notes;
      });
    } catch (_) {
      // No existing log for this date — fresh entry
      _isEditing = false;
    }
  }
  
  final List<Map<String, String>> _moods = [
    {'label': AppStrings.moodHappy, 'emoji': '😊'},
    {'label': AppStrings.moodTired, 'emoji': '😴'},
    {'label': AppStrings.moodAngry, 'emoji': '😠'},
    {'label': AppStrings.moodSensitive, 'emoji': '🥺'},
    {'label': AppStrings.moodEnergetic, 'emoji': '⚡'},
    {'label': AppStrings.moodAnxious, 'emoji': '😟'},
    {'label': AppStrings.moodCalm, 'emoji': '🧘‍♀️'},
    {'label': AppStrings.moodSad, 'emoji': '😢'},
    {'label': AppStrings.moodStressed, 'emoji': '😫'},
    {'label': AppStrings.moodEmotional, 'emoji': '🤧'},
    {'label': AppStrings.moodDemotivated, 'emoji': '📉'},
    {'label': AppStrings.moodUnhappy, 'emoji': '🙍‍♀️'},
  ];
  
  final List<String> _symptomsAvailable = [
    AppStrings.symptomHeadache,
    AppStrings.symptomCramps,
    AppStrings.symptomAcne,
    AppStrings.symptomBreastPain,
    AppStrings.symptomBackPain,
    AppStrings.symptomBloating,
    AppStrings.symptomNausea,
    AppStrings.symptomInsomnia,
    AppStrings.symptomCravings,
    AppStrings.symptomHotFlashes,
    AppStrings.symptomLossOfAppetite,
    AppStrings.symptomConstipation,
    AppStrings.symptomDiarrhea,
    AppStrings.symptomShoulderPain,
    AppStrings.symptomJointPain,
    AppStrings.symptomHeartburn,
    AppStrings.symptomChills,
  ];

  void _saveLog() async {
    if (_logDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gelecek tarihler için günlük kaydedilemez.'), backgroundColor: AppColors.error),
      );
      return;
    }

    // At least one piece of info must be provided
    if (_selectedMoods.isEmpty && _selectedSymptoms.isEmpty && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir bilgi girin (ruh hali, belirti veya not).'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    await Provider.of<CycleProvider>(context, listen: false).saveDailyLog(
      _logDate, 
      _selectedMoods, 
      _selectedSymptoms, 
      _notesController.text
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Günlük kaydedildi ✓'), backgroundColor: AppColors.success),
      );
      
      if (_isPushedRoute) {
        // Pushed from calendar — go back to calendar
        Navigator.pop(context, true); // return true to signal that data was saved
      } else {
        // Used as a tab — reset form for next entry
        setState(() {
          _selectedMoods.clear();
          _selectedSymptoms.clear();
          _notesController.clear();
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateLabel = DateFormat('d MMMM EEEE', 'tr_TR').format(_logDate);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // Back button only when pushed as a route
                  if (_isPushedRoute)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _isEditing ? 'Günlüğü Düzenle' : AppStrings.dailyLogTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.brandPink, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood Selector
                    Text(AppStrings.howDoYouFeel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 12.0,
                      children: _moods.map((mood) => _buildMoodItem(mood['label']!, mood['emoji']!)).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Physical Symptoms
                    Text(AppStrings.physicalSymptoms, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 12.0,
                      children: _symptomsAvailable.map((sym) => _buildSymptomChip(sym)).toList(),
                    ),

                    const SizedBox(height: 32),
                    
                    // Notes
                    Text(AppStrings.notes, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      enableSuggestions: true,
                      autocorrect: true,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppStrings.notesHint,
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.brandPrimaryDark),
                        )
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saveLog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _isEditing ? 'Güncelle' : AppStrings.saveBtn, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodItem(String label, String emoji) {
    bool isSelected = _selectedMoods.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedMoods.remove(label);
          } else {
            _selectedMoods.add(label);
          }
        });
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimaryDark.withValues(alpha: 0.2) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimaryDark : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.brandPrimaryDark : AppColors.textSecondaryDark
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomChip(String label) {
    bool isSelected = _selectedSymptoms.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSymptoms.remove(label);
          } else {
            _selectedSymptoms.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimaryDark.withValues(alpha: 0.2) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimaryDark : Theme.of(context).cardColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.brandPrimaryDark : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}
