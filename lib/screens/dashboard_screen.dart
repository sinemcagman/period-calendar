import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/cycle_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

// Screens
import 'calendar_screen.dart';
import 'daily_log_screen.dart';
import 'statistics_screen.dart';
import 'settings_inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  List<Widget> _screens(void Function(int) onTabChange) => [
    _HomeTab(onSettingsTabRequested: () => onTabChange(4)),
    const CalendarScreen(),
    const DailyLogScreen(),
    const StatisticsScreen(),
    const SettingsInventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens((index) => setState(() => _currentIndex = index))[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).cardColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.brandPink,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: AppStrings.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_month_outlined),
              label: AppStrings.navCalendar,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.edit_document),
              label: AppStrings.navDiary,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.pie_chart_outline),
              label: AppStrings.navStats,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: AppStrings.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback onSettingsTabRequested;
  const _HomeTab({required this.onSettingsTabRequested});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _dripController;

  @override
  void initState() {
    super.initState();
    _dripController = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _dripController.dispose();
    super.dispose();
  }

  Widget _buildDripEffect(double left, double delay) {
    return Positioned(
      left: left,
      top: 0,
      child: AnimatedBuilder(
        animation: _dripController,
        builder: (context, child) {
          // Calculate an offset and opacity based on controller mixed with delay
          double rawVal = (_dripController.value + delay) % 1.0;
          
          double height = 0;
          double opacity = 0;
          double transformY = 0;

          if (rawVal < 0.5) {
            height = 60 * (rawVal / 0.5);
            opacity = rawVal / 0.5;
          } else {
            height = 80 - 20 * ((rawVal - 0.5) / 0.5);
            opacity = 1.0 - ((rawVal - 0.5) / 0.5);
            transformY = 20 * ((rawVal - 0.5) / 0.5);
          }

          return Transform.translate(
            offset: Offset(0, transformY),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.brandPink, Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final cycleProvider = Provider.of<CycleProvider>(context);

    // Check if today falls in an active period
    bool isActivePeriod = false;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    for (var cycle in cycleProvider.cycles) {
      DateTime start = cycle.startDate;
      DateTime end = cycle.endDate ?? start.add(const Duration(days: 4)); // Fallback length
      start = DateTime(start.year, start.month, start.day);
      end = DateTime(end.year, end.month, end.day);
      
      if ((today.isAtSameMomentAs(start) || today.isAfter(start)) &&
          (today.isAtSameMomentAs(end) || today.isBefore(end))) {
        isActivePeriod = true;
        break;
      }
    }

    return Stack(
      children: [
        if (isActivePeriod) ...[
          _buildDripEffect(MediaQuery.of(context).size.width * 0.1, 0.0),
          _buildDripEffect(MediaQuery.of(context).size.width * 0.4, 0.4),
          _buildDripEffect(MediaQuery.of(context).size.width * 0.85, 0.2),
        ],
        
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: widget.onSettingsTabRequested,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.hello}, ${appProvider.currentUser?.name ?? "..."}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                          ),
                          Text(
                            AppStrings.lookingGreat,
                            style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.person_outline, color: AppColors.brandPink),
                    )
                  ],
                ),
                const SizedBox(height: 48),

                // Circular Indicator
                _buildCycleIndicator(context, cycleProvider),
                
                const SizedBox(height: 32),

                // Gap Metric
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync, size: 16, color: AppColors.textSecondaryDark),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.cycleGap.replaceAll('{days}', cycleProvider.averageCycleLength.toString()),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Water Tracker
                _buildWaterTracker(context, cycleProvider, appProvider)
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleIndicator(BuildContext context, CycleProvider cycleProvider) {
    int currentDay = cycleProvider.currentCycleGap;
    bool isOvulation = currentDay == 14; 
    
    DateTime now = DateTime.now();
    DateTime? nextPeriod = cycleProvider.predictedNextPeriod;
    int daysLeft = nextPeriod != null ? nextPeriod.difference(now).inDays : 28;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor.withValues(alpha: 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPink.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
        border: Border.all(color: AppColors.brandPink.withValues(alpha: 0.2), width: 4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simplified progress arc placeholder using CustomPaint or circular progress
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: currentDay / 28.0,
              strokeWidth: 4,
              color: AppColors.brandPink,
              backgroundColor: Colors.transparent,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                AppStrings.cyclePrefix,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.cycleDayTemplate.replaceAll('{day}', currentDay.toString()),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isOvulation)
                const Text(
                  AppStrings.ovulationPeriod,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPink,
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.brandPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.brandPink.withValues(alpha: 0.3)),
                ),
                child: Text(
                  AppStrings.daysToPeriod.replaceAll('{days}', daysLeft.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandPink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(BuildContext context, CycleProvider cycleProvider, AppProvider appProvider) {
    int consumedUnits = cycleProvider.waterGlassesToday;
    int consumedMl = consumedUnits * 250; // 250ml per increment

    // If goal is stored as glasses (e.g. 8), convert to ML (2000). Otherwise assume it's already ML.
    int goalMl = appProvider.waterGoal < 100 ? appProvider.waterGoal * 250 : appProvider.waterGoal;
    
    double progress = goalMl > 0 ? (consumedMl / goalMl).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                AppStrings.waterTrackerTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "Hedef: ${(goalMl / 1000).toStringAsFixed(1)} L",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 14,
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${(consumedMl / 1000).toStringAsFixed(2)} L içildi",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      cycleProvider.removeWaterGlass();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade600),
                      ),
                      child: Icon(Icons.remove, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      cycleProvider.addWaterGlass();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade500,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ]
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
