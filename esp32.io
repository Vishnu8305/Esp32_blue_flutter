#include <WiFi.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// BLE Service and Characteristic UUIDs
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define SSID_CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define PASSWORD_CHARACTERISTIC_UUID "d7f5483e-36e1-4688-b7f5-ea07361b26b9"

// BLE server and characteristics
BLEServer *pServer = nullptr;
BLECharacteristic *ssidCharacteristic;
BLECharacteristic *passwordCharacteristic;

String ssid = "";
String password = "";
bool deviceConnected = false;

// Function to connect to Wi-Fi
void connectToWiFi() {
  ssid.trim();
  password.trim();
  Serial.println("\nAttempting to connect to Wi-Fi...");
  WiFi.disconnect(true);  // Clear previous credentials
  delay(1000);
  WiFi.begin(ssid.c_str(), password.c_str());

  int timeout = 30; // Timeout after 30 seconds
  while (WiFi.status() != WL_CONNECTED && timeout > 0) {
    delay(1000);
    Serial.print(".");
    timeout--;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nConnected to Wi-Fi!");
    Serial.print("SSID: ");
    Serial.println(ssid);
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nFailed to connect to Wi-Fi. Debugging status...");
    printWiFiStatus();
  }
}

void printWiFiStatus() {
  switch (WiFi.status()) {
    case WL_NO_SSID_AVAIL:
      Serial.println("SSID not available.");
      break;
    case WL_CONNECT_FAILED:
      Serial.println("Connection failed. Check password.");
      break;
    case WL_DISCONNECTED:
      Serial.println("Disconnected from Wi-Fi.");
      break;
    case WL_IDLE_STATUS:
      Serial.println("Wi-Fi is in idle state.");
      break;
    default:
      Serial.println("Unknown error.");
      break;
  }
}


// BLE server callbacks
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *pServer) {
    deviceConnected = true;
    Serial.println("Device connected");
  }

  void onDisconnect(BLEServer *pServer) {
    deviceConnected = false;
    Serial.println("Device disconnected");
  }
};

// BLE characteristic callbacks
class WiFiConfigCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = String(pCharacteristic->getValue().c_str());
    if (value.length() > 0) {
      if (pCharacteristic == ssidCharacteristic) {
        ssid = value;
        Serial.println("Received SSID: " + ssid);
      } else if (pCharacteristic == passwordCharacteristic) {
        password = value;
        Serial.println("Received Password: " + password);
        // Connect to Wi-Fi after receiving password
        connectToWiFi();
      }
    }
  }
};

void setup() {
  Serial.begin(115200);

  // Initialize BLE
  BLEDevice::init("ESP32-WiFi-Setup");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristics
  ssidCharacteristic = pService->createCharacteristic(
      SSID_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_WRITE);
  passwordCharacteristic = pService->createCharacteristic(
      PASSWORD_CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_WRITE);

  ssidCharacteristic->setCallbacks(new WiFiConfigCallbacks());
  passwordCharacteristic->setCallbacks(new WiFiConfigCallbacks());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->start();
  Serial.println("BLE server is ready and advertising.");
}

void loop() {
  // Handle device connection status
  if (deviceConnected) {
    // Additional logic if needed
  }
}