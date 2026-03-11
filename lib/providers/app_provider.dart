import 'dart:core';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../models/inventory_item.dart';
import '../services/notification_service.dart';
import '../constants/app_strings.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  User? currentUser;
  bool isDarkMode = true;
  bool hasCompletedOnboarding = false;
  int waterGoal = 8;
  
  List<InventoryItem> inventory = [];

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    waterGoal = prefs.getInt('water_goal') ?? 8;
    await loadUser();
    await loadInventory();
  }

  Future<void> loadUser() async {
    final db = await _db.database;
    final res = await db.query('users', limit: 1);
    
    if (res.isNotEmpty) {
      currentUser = User.fromMap(res.first);
      isDarkMode = currentUser!.isDarkMode;
      hasCompletedOnboarding = true;
    } else {
      hasCompletedOnboarding = false;
    }
    notifyListeners();
  }

  Future<void> saveUser(String name) async {
    final db = await _db.database;
    final newUser = User(name: name, isDarkMode: isDarkMode);
    int id = await db.insert('users', newUser.toMap());
    currentUser = User(id: id, name: name, isDarkMode: isDarkMode);
    hasCompletedOnboarding = true;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    if (currentUser != null) {
      final db = await _db.database;
      final updatedUser = User(
        id: currentUser!.id, 
        name: currentUser!.name, 
        isDarkMode: isDarkMode
      );
      await db.update('users', updatedUser.toMap(), where: 'id = ?', whereArgs: [currentUser!.id]);
      currentUser = updatedUser;
    }
    notifyListeners();
  }
  
  Future<void> updateUserName(String newName) async {
    if (currentUser != null) {
      final db = await _db.database;
      final updatedUser = User(
        id: currentUser!.id, 
        name: newName, 
        isDarkMode: isDarkMode
      );
      await db.update('users', updatedUser.toMap(), where: 'id = ?', whereArgs: [currentUser!.id]);
      currentUser = updatedUser;
      notifyListeners();
    }
  }

  Future<void> setWaterGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_goal', goal);
    waterGoal = goal;
    notifyListeners();
  }
  
  // INVENTORY LOGIC
  Future<void> loadInventory() async {
    final db = await _db.database;
    final res = await db.query('inventory');
    inventory = res.map((item) => InventoryItem.fromMap(item)).toList();
    notifyListeners();
    _checkInventoryThreshold();
  }

  Future<void> updateInventory(String itemType, int newAmount) async {
    if (newAmount < 0) newAmount = 0;
    
    final db = await _db.database;
    await db.update(
      'inventory', 
      {'current_stock': newAmount}, 
      where: 'item_type = ?', 
      whereArgs: [itemType]
    );
    
    await loadInventory();
  }
  
  Future<void> addInventoryItem(String itemType, int initialStock) async {
    final db = await _db.database;
    // Check if exists first
    final res = await db.query('inventory', where: 'item_type = ?', whereArgs: [itemType]);
    if (res.isEmpty) {
      await db.insert('inventory', {'item_type': itemType, 'current_stock': initialStock});
      await loadInventory();
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    final db = await _db.database;
    await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
    await loadInventory();
  }
  
  void _checkInventoryThreshold() {
    for (var item in inventory) {
      if (item.currentStock <= 3) { // Threshold is 3
        NotificationService.showNotification(
          id: 200 + item.id!,
          title: "Stok Uyarısı: ${item.itemType}",
          body: AppStrings.stockRunningLow,
        );
      }
    }
  }
}
