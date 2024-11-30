import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESP32 Wi-Fi Config',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BluetoothDevicesPage(),
    );
  }
}

class BluetoothDevicesPage extends StatefulWidget {
  @override
  _BluetoothDevicesPageState createState() => _BluetoothDevicesPageState();
}

class _BluetoothDevicesPageState extends State<BluetoothDevicesPage> {
  List<ScanResult> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => startScan());
  }

  Future<void> requestPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      print("All permissions granted");
    } else {
      print("Permissions not granted");
    }
  }

  void startScan() {
    setState(() {
      devices = [];
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    FlutterBluePlus.onScanResults.listen((results) {
      setState(() {
        devices = results;
      });
    }).onDone(() {
      setState(() {
        isScanning = false;
      });
      print("Scanning completed");
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WiFiConfigPage(device: device)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select ESP32 Device"),
        actions: [
          if (!isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: startScan,
            ),
        ],
      ),
      body: devices.isEmpty
          ? const Center(child: Text("No devices found"))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index].device;
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : "Unknown"),
                  subtitle: Text(device.id.toString()),
                  onTap: () => connectToDevice(device),
                );
              },
            ),
    );
  }
}

class WiFiConfigPage extends StatelessWidget {
  final BluetoothDevice device;
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  WiFiConfigPage({required this.device});

  Future<void> sendCredentials() async {
    // Discover services and characteristics
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        // Match the characteristic UUIDs for SSID and password
        if (characteristic.uuid.toString() ==
            "beb5483e-36e1-4688-b7f5-ea07361b26a8") {
          await characteristic.write(ssidController.text.codeUnits);
          print("SSID sent: ${ssidController.text}");
        } else if (characteristic.uuid.toString() ==
            "d7f5483e-36e1-4688-b7f5-ea07361b26b9") {
          await characteristic.write(passwordController.text.codeUnits);
          print("Password sent: ${passwordController.text}");
        }
      }
    }
    print("Wi-Fi credentials sent!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configure Wi-Fi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(labelText: "Wi-Fi SSID"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Wi-Fi Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendCredentials,
              child: const Text("Send to ESP32"),
            ),
          ],
        ),
      ),
    );
  }
}
