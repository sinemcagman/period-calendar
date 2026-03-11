class InventoryItem {
  final int? id;
  final String itemType; // e.g., 'ped', 'tampon'
  final int currentStock;

  InventoryItem({this.id, required this.itemType, required this.currentStock});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_type': itemType,
      'current_stock': currentStock,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      itemType: map['item_type'],
      currentStock: map['current_stock'],
    );
  }
}
