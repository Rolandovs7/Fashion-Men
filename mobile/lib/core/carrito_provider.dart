import 'package:flutter/material.dart';

class CarritoProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void agregarAlCarrito(Map<String, dynamic> producto) {
    _items.add(producto);
    notifyListeners();
  }

  void eliminarDelCarrito(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void vaciarCarrito() {
    _items.clear();
    notifyListeners();
  }

  double get total =>
      _items.fold(0, (suma, item) => suma + (item['precio'] * item['cantidad']));
}