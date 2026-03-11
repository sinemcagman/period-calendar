import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';
import 'reminders_screen.dart';

class SettingsInventoryScreen extends StatelessWidget {
  const SettingsInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.settingsInventoryTitle),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppStrings.darkMode, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        value: appProvider.isDarkMode,
                        activeColor: AppColors.brandPink,
                        onChanged: (val) {
                          appProvider.toggleTheme();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("İsmi Düzenle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        subtitle: Text(appProvider.currentUser?.name ?? "Belirtilmemiş", style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () => _showNameChangeDialog(context, appProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Su Hedefi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        subtitle: Text(appProvider.waterGoal < 100 ? "${appProvider.waterGoal * 250} ml" : "${appProvider.waterGoal} ml", style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                        trailing: const Icon(Icons.water_drop, size: 18, color: Colors.blue),
                        onTap: () => _showWaterGoalDialog(context, appProvider),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppStrings.remindersTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RemindersScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Inventory Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.inventoryTracking,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.brandPink),
                      onPressed: () => _showAddInventoryDialog(context, appProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ...appProvider.inventory.map((item) {
                  bool isLow = item.currentStock <= 3;
                  Color bgColor = isLow ? Colors.red.withOpacity(0.1) : Theme.of(context).cardColor;
                  Color borderColor = isLow ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.05);
                  Color btnColor = isLow ? Colors.red.shade400 : AppColors.brandPink;
                  String displayName = item.itemType;
                  if (item.itemType.toLowerCase() == 'ped') {
                    displayName = AppStrings.itemPad;
                  } else if (item.itemType.toLowerCase() == 'tampon') {
                    displayName = AppStrings.itemTampon;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (item.id != null) {
                                      appProvider.deleteInventoryItem(item.id!);
                                    }
                                  },
                                  child: Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 20),
                                ),
                              ],
                            ),
                            if (isLow)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  AppStrings.stockRunningLow,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade400),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              color: btnColor,
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                side: BorderSide(color: borderColor),
                              ),
                              onPressed: () {
                                appProvider.updateInventory(item.itemType, item.currentStock - 1);
                              },
                            ),
                            Container(
                              width: 60,
                              alignment: Alignment.center,
                              child: Text(
                                '${item.currentStock}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: btnColor,
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                side: BorderSide(color: borderColor),
                              ),
                              onPressed: () {
                                appProvider.updateInventory(item.itemType, item.currentStock + 1);
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddInventoryDialog(BuildContext context, AppProvider provider) {
    TextEditingController nameController = TextEditingController();
    TextEditingController stockController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Yeni Ürün Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Ürün adı (Örn: Günlük Ped)",
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Mevcut Stok",
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty && stockController.text.trim().isNotEmpty) {
                  int stock = int.tryParse(stockController.text.trim()) ?? 0;
                  await provider.addInventoryItem(nameController.text.trim(), stock);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Ekle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNameChangeDialog(BuildContext context, AppProvider provider) {
    TextEditingController controller = TextEditingController(text: provider.currentUser?.name ?? "");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("İsminizi Düzenleyin", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Yeni isminiz",
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await provider.updateUserName(controller.text.trim());
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showWaterGoalDialog(BuildContext context, AppProvider provider) {
    TextEditingController controller = TextEditingController(text: provider.waterGoal.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Su Hedefi (ml)", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Örn: 2000",
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  int goal = int.tryParse(controller.text.trim()) ?? 8;
                  if (goal > 0) {
                    await provider.setWaterGoal(goal);
                    if (context.mounted) Navigator.pop(context);
                  }
                }
              },
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
