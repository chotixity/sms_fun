import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_fun/src/android/incoming_sms.dart';
import 'package:sms_fun/src/android/sms_inbox.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MpesaReceiverPage(),
    );
  }
}

class MpesaReceiverPage extends StatefulWidget {
  const MpesaReceiverPage({super.key});

  @override
  _MpesaReceiverPageState createState() => _MpesaReceiverPageState();
}

class _MpesaReceiverPageState extends State<MpesaReceiverPage>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _incomingSubscription;
  List<String> _mpesaMessages = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomingSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  void _listenForNewMessages() {
    _incomingSubscription ??= incomingMpesaMessages().listen((message) {
      setState(() {
        // Newest first, matching readMpesaMessages().
        _mpesaMessages = [message, ..._mpesaMessages];
      });
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _getMessages();
      _listenForNewMessages();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _getMessages();
      _listenForNewMessages();
    }
  }

  Future<void> _getMessages() async {
    try {
      final List<String> messages = readMpesaMessages();
      setState(() {
        _mpesaMessages = messages;
      });
    }  catch (e) {
      print("Failed to read MPESA messages: '${e.toString()}'.");
    }
  }

  // SMS can't be deleted unless this is the default SMS app, so this only
  // clears the list; refresh reloads it from the inbox.
  void _clearMessages() {
    setState(() {
      _mpesaMessages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MPESA Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasPermission ? _getMessages : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _hasPermission ? _clearMessages : null,
          ),
        ],
      ),
      body: _hasPermission
          ? ListView.builder(
              itemCount: _mpesaMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_mpesaMessages[index]),
                );
              },
            )
          : Center(
              child: ElevatedButton(
                onPressed: _requestPermission,
                child: const Text('Request SMS Permission'),
              ),
            ),
    );
  }
}
