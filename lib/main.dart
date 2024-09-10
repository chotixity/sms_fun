import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
  static const platform = MethodChannel('com.example.sms_fun/mpesa');
  static const EventChannel _eventChannel =
      EventChannel('com.example.sms_fun/mpesa_events');
  List<String> _mpesaMessages = [];
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _listenForNewMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  void _listenForNewMessages() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {
        _mpesaMessages = List<String>.from(_mpesaMessages)
          ..add(event as String);
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
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _getMessages();
    }
  }

  Future<void> _getMessages() async {
    if (!_hasPermission) {
      return;
    }
    try {
      final List<dynamic> result =
          await platform.invokeMethod('getMpesaMessages');
      setState(() {
        _mpesaMessages = List<String>.from(result);
      });
    } on PlatformException catch (e) {
      print("Failed to get MPESA messages: '${e.message}'.");
    }
  }

  Future<void> _clearMessages() async {
    if (!_hasPermission) {
      return;
    }
    try {
      await platform.invokeMethod('clearMpesaMessages');
      setState(() {
        _mpesaMessages.clear();
      });
    } on PlatformException catch (e) {
      print("Failed to clear MPESA messages: '${e.message}'.");
    }
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
