import 'package:busfare/model/qr_results_model.dart';
import 'package:flutter/material.dart';

class QrResultsProvider extends ChangeNotifier {
  final List<QrResults> _qrResults = [];

  List<QrResults> get qrResults => _qrResults;

  void addQrResults(QrResults qr) {
    for (var e in _qrResults) {
      if (e.code == qr.code) {
        return;
      }
    }
    _qrResults.add(qr);
    notifyListeners();
  }

  void removeQrResults(QrResults qr) {
    _qrResults.remove(qr);
    notifyListeners();
  }

  void clearQrResults() {
    _qrResults.clear();
    notifyListeners();
  }
}
