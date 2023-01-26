import 'package:busfare/views/topup_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'qr_pay_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ValueNotifier<int> _selectedIndex;
  late Future<DocumentSnapshot<Map<String, dynamic>>> getBalance;
  @override
  void initState() {
    super.initState();
    _selectedIndex = ValueNotifier(0);
    reloadBalance();
  }

  reloadBalance() {
    final userID = FirebaseAuth.instance.currentUser?.uid;
    getBalance =
        FirebaseFirestore.instance.collection('balance').doc('$userID').get();
    setState(() {});
  }

  ///

  @override
  Widget build(BuildContext context) {
    final userID = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home'),
        actions: [
          //Profile button
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getBalance,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${snapshot.error} occurred',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final data = snapshot.data;
                    if (data?.exists ?? false) {
                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('balance')
                            .doc('$userID')
                            .snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<
                                    DocumentSnapshot<Map<String, dynamic>>>
                                streamSnapshot) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'Available Balance: \$${streamSnapshot.data?.data()?.entries.first.value}',
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.account_balance),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('balance')
                              .doc('$userID')
                              .set({
                            'value': 0,
                          });
                          await reloadBalance();
                        },
                        label: const Text('Load balance'),
                      );
                    }
                  } else {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.account_balance),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('balance')
                            .doc('$userID')
                            .set({
                          'value': 0,
                        });
                        await reloadBalance();
                      },
                      label: const Text('Load balance'),
                    );
                  }
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }),
        ),
      ),
      body: ValueListenableBuilder<int>(
          valueListenable: _selectedIndex,
          builder: (context, value, child) {
            if (value == 0) {
              return const TopupView();
            } else {
              return const QrPayView();
            }
          }),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (context, value, child) => BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.money),
              label: 'Topup',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner),
              label: 'Scan',
            ),
          ],
          currentIndex: value,
          onTap: (int value) {
            _selectedIndex.value = value;
          },
        ),
      ),
    );
  }
}
