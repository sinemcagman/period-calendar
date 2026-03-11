import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class DailyLogScreen extends StatefulWidget {
  final DateTime? selectedDate;
  const DailyLogScreen({super.key, this.selectedDate});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  late DateTime _logDate;
  String _selectedMood = '';
  final List<String> _selectedSymptoms = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logDate = widget.selectedDate ?? DateTime.now();
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

    if (_selectedMood.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ruh halinizi seçin.'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    await Provider.of<CycleProvider>(context, listen: false).saveDailyLog(
      _logDate, 
      _selectedMood, 
      _selectedSymptoms, 
      _notesController.text
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Günlük kaydedildi.'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context); // Optional: close the screen after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Spacer for centering
                  const Expanded(
                    child: Text(
                      AppStrings.dailyLogTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: AppStrings.notesHint,
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(AppStrings.saveBtn, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodItem(String label, String emoji) {
    bool isSelected = _selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMood = label);
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimaryDark.withOpacity(0.2) : Theme.of(context).cardColor,
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
          color: isSelected ? AppColors.brandPrimaryDark.withOpacity(0.2) : Theme.of(context).cardColor,
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
