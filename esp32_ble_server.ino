/*
 * ESP32-S3 BLE Server for Flutter Communication
 * 
 * This Arduino sketch creates a BLE server on the ESP32-S3 that can communicate
 * with the Flutter app. It provides BLE characteristics for:
 * - Receiving commands from Flutter app
 * - Sending sensor data and responses
 * - LED control
 * - Device status reporting
 * 
 * Hardware Setup:
 * - LED connected to GPIO 2 (built-in LED)
 * - Optional: Temperature sensor, light sensor, etc.
 * 
 * Libraries needed:
 * - BLE (ESP32 Core)
 * - ArduinoJson
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>

// BLE Service and Characteristic UUIDs - MUST match Flutter app
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"

// Hardware pins
const int LED_PIN = 2;  // Built-in LED on most ESP32 boards
const int SENSOR_PIN = A0;  // Analog sensor (optional)

// BLE variables
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// Global variables
bool ledState = false;
unsigned long lastSensorRead = 0;
float sensorValue = 0.0;
String deviceName = "ESP32-BLE-Device";

// Function declarations
void handleCommand(String jsonCommand);
void handleLEDCommand(DynamicJsonDocument& doc);
void handleBlinkCommand(DynamicJsonDocument& doc);
void sendSensorData();
void sendDeviceStatus();
void sendResponse(String key, String value);
void readSensors();
String getChipInfo();

// BLE Server Callbacks
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected");
    }
};

// BLE Characteristic Callbacks
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String value = pCharacteristic->getValue().c_str();
      
      if (value.length() > 0) {
        Serial.println("Received: " + value);
        handleCommand(value);
      }
    }
};

void setup() {
  Serial.begin(115200);
  
  // Initialize hardware
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Initialize BLE
  BLEDevice::init(deviceName.c_str());
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);  // set value to 0x00 to not advertise this parameter
  BLEDevice::startAdvertising();
  
  Serial.println("ESP32 BLE Server started!");
  Serial.println("Device name: " + deviceName);
  Serial.println("Waiting for client connection...");
}

void loop() {
  // Handle connection state changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }
  
  // Read sensors periodically
  if (millis() - lastSensorRead > 2000) {
    readSensors();
    lastSensorRead = millis();
  }
  
  delay(100);
}

void handleCommand(String jsonCommand) {
  DynamicJsonDocument doc(512);
  DeserializationError error = deserializeJson(doc, jsonCommand);
  
  if (error) {
    Serial.println("Failed to parse JSON command");
    sendResponse("error", "Invalid JSON format");
    return;
  }
  
  String command = doc["command"];
  Serial.println("Processing command: " + command);
  
  if (command == "led") {
    handleLEDCommand(doc);
  } else if (command == "sensors") {
    sendSensorData();
  } else if (command == "status") {
    sendDeviceStatus();
  } else if (command == "restart") {
    sendResponse("message", "Restarting ESP32...");
    delay(1000);
    ESP.restart();
  } else if (command == "blink") {
    handleBlinkCommand(doc);
  } else {
    sendResponse("error", "Unknown command: " + command);
  }
}

void handleLEDCommand(DynamicJsonDocument& doc) {
  String state = doc["state"];
  
  if (state == "ON") {
    ledState = true;
    digitalWrite(LED_PIN, HIGH);
    sendResponse("ledState", "ON");
    Serial.println("LED turned ON");
  } else if (state == "OFF") {
    ledState = false;
    digitalWrite(LED_PIN, LOW);
    sendResponse("ledState", "OFF");
    Serial.println("LED turned OFF");
  } else {
    sendResponse("error", "Invalid LED state. Use ON or OFF");
  }
}

void handleBlinkCommand(DynamicJsonDocument& doc) {
  int times = doc["times"] | 3;  // Default 3 times
  
  sendResponse("message", "Blinking LED " + String(times) + " times");
  
  // Save current LED state
  bool originalState = ledState;
  
  // Blink LED
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }
  
  // Restore original state
  digitalWrite(LED_PIN, originalState ? HIGH : LOW);
}

void sendSensorData() {
  DynamicJsonDocument doc(512);
  
  doc["sensors"]["temperature"] = random(20, 35);  // Simulated temperature
  doc["sensors"]["humidity"] = random(40, 80);     // Simulated humidity
  doc["sensors"]["light"] = sensorValue;           // Actual analog reading
  doc["sensors"]["ledState"] = ledState ? "ON" : "OFF";
  doc["sensors"]["uptime"] = millis();
  doc["sensors"]["timestamp"] = millis();
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  if (deviceConnected) {
    pCharacteristic->setValue(jsonString.c_str());
    pCharacteristic->notify();
    Serial.println("Sent sensor data: " + jsonString);
  }
}

void sendDeviceStatus() {
  DynamicJsonDocument doc(512);
  
  doc["status"]["chipModel"] = ESP.getChipModel();
  doc["status"]["chipRevision"] = ESP.getChipRevision();
  doc["status"]["cpuFreq"] = ESP.getCpuFreqMHz();
  doc["status"]["freeHeap"] = ESP.getFreeHeap();
  doc["status"]["totalHeap"] = ESP.getHeapSize();
  doc["status"]["uptime"] = millis();
  doc["status"]["deviceName"] = deviceName;
  doc["status"]["macAddress"] = String((uint32_t)ESP.getEfuseMac(), HEX);
  doc["status"]["ledState"] = ledState ? "ON" : "OFF";
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  if (deviceConnected) {
    pCharacteristic->setValue(jsonString.c_str());
    pCharacteristic->notify();
    Serial.println("Sent device status: " + jsonString);
  }
}

void sendResponse(String key, String value) {
  DynamicJsonDocument doc(256);
  doc[key] = value;
  
  String jsonString;
  serializeJson(doc, jsonString);
  
  if (deviceConnected) {
    pCharacteristic->setValue(jsonString.c_str());
    pCharacteristic->notify();
    Serial.println("Sent response: " + jsonString);
  }
}

void readSensors() {
  // Read analog sensor (0-4095 on ESP32)
  int rawValue = analogRead(SENSOR_PIN);
  sensorValue = (rawValue / 4095.0) * 100.0;  // Convert to percentage
  
  // You can add more sensors here
  // Example:
  // float temperature = readTemperatureSensor();
  // float humidity = readHumiditySensor();
}

// Helper function to get chip info
String getChipInfo() {
  String info = "ESP32 Chip: ";
  info += ESP.getChipModel();
  info += " Rev ";
  info += ESP.getChipRevision();
  info += " (";
  info += ESP.getCpuFreqMHz();
  info += " MHz)";
  return info;
}

// Optional: Add sensor reading functions
/*
float readTemperatureSensor() {
  // Add your temperature sensor reading code here
  // Example for DS18B20, DHT22, etc.
  return 25.0; // placeholder
}

float readHumiditySensor() {
  // Add your humidity sensor reading code here
  return 50.0; // placeholder
}
*/
