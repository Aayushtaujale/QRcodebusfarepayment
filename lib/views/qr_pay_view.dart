import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'package:busfare/controller/qr_controller.dart';
import 'package:busfare/decoration.dart';
import 'package:busfare/model/qr_results_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrPayView extends StatefulWidget {
  const QrPayView({super.key});

  @override
  State<QrPayView> createState() => _QrPayViewState();
}

class _QrPayViewState extends State<QrPayView> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: context.watch<QrResultsProvider>().qrResults.isEmpty
          ? Stack(
              children: [
                _buildQrView(context),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // if (result != null)
                      //   Text(
                      //     'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}',
                      //     style: const TextStyle(fontSize: 20),
                      //   )
                      // else
                      const Text(
                        'Scan a code',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: IconButton(
                                onPressed: () async {
                                  await controller?.toggleFlash();
                                  setState(() {});
                                },
                                icon: FutureBuilder<bool?>(
                                  future: controller?.getFlashStatus(),
                                  builder: (context, snapshot) {
                                    return Icon(
                                      Icons.flash_on,
                                      color: snapshot.data ?? false
                                          ? Colors.blue
                                          : Colors.grey,
                                    );
                                  },
                                )),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: IconButton(
                                onPressed: () async {
                                  await controller?.flipCamera();
                                  setState(() {});
                                },
                                icon: FutureBuilder<CameraFacing>(
                                  future: controller?.getCameraInfo(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      return Icon(
                                        describeEnum(snapshot.data!)
                                                    .toString() ==
                                                "front"
                                            ? Icons.camera_front
                                            : Icons.camera_rear,
                                        color: Colors.blue,
                                      );
                                    } else {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                )),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await controller?.pauseCamera();
                              },
                              icon: const Icon(Icons.pause),
                              label: const Text('pause',
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await controller?.resumeCamera();
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('resume',
                                  style: TextStyle(fontSize: 20)),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _buildQrResults(context),
    );
  }

  Widget _buildQrResults(BuildContext context) {
    // Form the results into a list of widgets
    final userID = FirebaseAuth.instance.currentUser?.uid;

    var results = context.read<QrResultsProvider>().qrResults;
    var widgets = results
        .map((result) => ListTile(
              title:
                  Text('Bank Account No. ${math.Random().nextInt(1000000000)}'),
              subtitle: const Text('Bank Name: ABC Bank'),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Pay'),
                onPressed: () async {
                  // show Payment Dialog
                  showDialog(
                    context: context,
                    builder: (context) => PaymentDialog(
                      result: result,
                      userID: userID!,
                    ),
                  );
                },
              ),
            ))
        .toList();
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: widgets,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<QrResultsProvider>().clearQrResults();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Clear Payment', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    final QrResultsProvider provider = context.read<QrResultsProvider>();
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      final qrResults = QrResults.fromJson({
        'code': scanData.code,
        'format': describeEnum(scanData.format),
      }).toJson().toString();

      if (provider.qrResults.isNotEmpty) {
        for (QrResults value in provider.qrResults) {
          if (!(value.code!.contains(scanData.code ?? ''))) {
            provider.addQrResults(QrResults.fromJson({
              'code': scanData.code,
              'format': describeEnum(scanData.format),
            }));

            log(
              qrResults,
              name: 'QrResults',
            );
          } else {
            log(
              qrResults,
              name: 'Already Scanned',
            );
          }
        }
      } else {
        provider.addQrResults(QrResults.fromJson({
          'code': scanData.code,
          'format': describeEnum(scanData.format),
        }));

        log(
          qrResults,
          name: 'QrResults',
        );
      }

      setState(() {
        result = scanData;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      showToast(
        'No Permission',
        Colors.red,
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key, required this.result, required this.userID});
  final QrResults result;
  final String userID;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController amountField;
  @override
  void initState() {
    super.initState();
    amountField = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        title: const Text('Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Do you want to pay?'),
            const SizedBox(height: 10),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('balance')
                    .doc(widget.userID)
                    .get(),
                builder: (context, snapshot) {
                  return TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: amountField,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Amount',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      } else {
                        final currentBalance = int.tryParse(
                                '${snapshot.data?.data()?['value']}') ??
                            0;
                        final newBalance =
                            currentBalance - (int.tryParse(value) ?? 0);
                        if (newBalance.isNegative) {
                          return 'Insufficient Balance';
                        }
                      }
                      return null;
                    },
                  );
                }),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          ElevatedButton(
            onPressed: () async {
              final qrprovider =
                  Provider.of<QrResultsProvider>(context, listen: false);
              if (_formKey.currentState!.validate()) {
                // save data to firebase
                await FirebaseFirestore.instance
                    .collection('balance')
                    .doc(widget.userID)
                    .get()
                    .then((value) {
                  if (value.exists) {
                    final currentBalance =
                        int.tryParse('${value.data()?['value']}') ?? 0;
                    final newBalance =
                        currentBalance - int.parse(amountField.text);
                    if (newBalance.isNegative) {
                      showToast(
                        'Insufficient Balance',
                        Colors.red,
                      );
                    } else {
                      FirebaseFirestore.instance
                          .collection('balance')
                          .doc(widget.userID)
                          .update({
                        'value': newBalance,
                      });
                      showToast(
                        'Payment Successful',
                        Colors.green,
                      );

                      qrprovider.removeQrResults(widget.result);
                      Navigator.of(context).pop();
                    }
                  } else {
                    FirebaseFirestore.instance
                        .collection('balance')
                        .doc(widget.userID)
                        .set({
                      'value': amountField.text.isNotEmpty
                          ? int.parse(amountField.text)
                          : 0,
                    });
                    showToast(
                      'Payment Successful',
                      Colors.green,
                    );
                    qrprovider.removeQrResults(widget.result);
                    Navigator.of(context).pop();
                  }
                });
                // Remove the result from the list

              }
            },
            child: const Text('Pay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
