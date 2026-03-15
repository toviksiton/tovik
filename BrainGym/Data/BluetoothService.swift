import Foundation
import CoreBluetooth

// MARK: - BluetoothService
// Detects connected Bluetooth device categories (earphones, watch, car).

@Observable
final class BluetoothService: NSObject {
    var connectedDevices: Set<BluetoothDevice> = []
    var isScanning = false

    private var centralManager: CBCentralManager?

    func start() {
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Device type inference from device name

    private static func infer(from name: String?) -> BluetoothDevice? {
        guard let name = name?.lowercased() else { return nil }
        let earphonesKeywords = ["airpod", "buds", "earphone", "headphone", "earbud", "wf-", "wh-", "jabra", "bose", "beats", "pixel buds"]
        let watchKeywords     = ["watch", "apple watch", "galaxy watch", "fitbit", "garmin"]
        let carKeywords       = ["car", "bmw", "mercedes", "toyota", "ford", "honda", "audi", "hands-free", "bluetooth audio"]

        if earphonesKeywords.contains(where: { name.contains($0) }) { return .earphones }
        if watchKeywords.contains(where: { name.contains($0) })     { return .watch }
        if carKeywords.contains(where: { name.contains($0) })       { return .car }
        return nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothService: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isScanning = central.state == .poweredOn
        guard central.state == .poweredOn else { return }
        // Retrieve already-connected peripherals for known categories
        let knownServices: [CBUUID] = [
            CBUUID(string: "0000111E-0000-1000-8000-00805F9B34FB"), // Handsfree
            CBUUID(string: "0000110B-0000-1000-8000-00805F9B34FB"), // A2DP sink
        ]
        for uuid in knownServices {
            let connected = central.retrieveConnectedPeripherals(withServices: [uuid])
            for peripheral in connected {
                if let device = Self.infer(from: peripheral.name) {
                    connectedDevices.insert(device)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let device = Self.infer(from: peripheral.name) {
            connectedDevices.insert(device)
        }
    }
}
