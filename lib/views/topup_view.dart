import 'package:busfare/decoration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopupView extends StatefulWidget {
  const TopupView({
    Key? key,
  }) : super(key: key);

  @override
  State<TopupView> createState() => _TopupViewState();
}

class _TopupViewState extends State<TopupView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amount;
  late TextEditingController _bankName;
  late TextEditingController _bankNumber;
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController();
    _bankName = TextEditingController();
    _bankNumber = TextEditingController();
  }

  clear() {
    _amount.clear();
    _bankName.clear();
    _bankNumber.clear();
  }

  @override
  Widget build(BuildContext context) {
    final userID = FirebaseAuth.instance.currentUser?.uid;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            // Label
            const Text(
              'Bus Fare Payment',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 10,
            ),
            // Amount
            TextFormField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (String? fieldContent) {
                if (fieldContent!.isEmpty) {
                  return 'Please enter an amount';
                } else {
                  return null;
                }
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bankName,
              decoration: const InputDecoration(labelText: 'Bank Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a bank name';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bankNumber,
              decoration: const InputDecoration(labelText: 'Bank Number'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a bank number';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await FirebaseFirestore.instance
                      .collection('balance')
                      .doc('$userID')
                      .get()
                      .then((value) {
                    if (value.exists) {
                      final currentBalance =
                          int.tryParse('${value.data()?['value']}') ?? 0;
                      final newBalance =
                          currentBalance + int.parse(_amount.text);
                      FirebaseFirestore.instance
                          .collection('balance')
                          .doc('$userID')
                          .update({
                        'value': newBalance,
                      });
                      clear();
                      showToast(
                        'Topup successful',
                        Colors.green,
                      );
                      FocusScope.of(context).unfocus();
                    } else {
                      FirebaseFirestore.instance
                          .collection('balance')
                          .doc('$userID')
                          .set({
                        'value': _amount.text.isNotEmpty
                            ? int.parse(_amount.text)
                            : 0,
                      });
                      clear();
                      showToast(
                        'Topup successful',
                        Colors.green,
                      );
                      // keyboard close
                      FocusScope.of(context).unfocus();
                    }
                  });

                  // Perform pay action with the entered amount, bank name, and bank number
                }
              },
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
