import CoreBluetooth

extension Data {
    func readUint16LE(from: Int) -> UInt16 {
        var value: UInt16

        value = UInt16(self[from])
        value |= UInt16(self[from + 1]) << 8

        return value
    }

    func readUint32LE(from: Int) -> UInt32 {
        var value: UInt32

        value = UInt32(self[from])
        value |= UInt32(self[from + 1]) << 8
        value |= UInt32(self[from + 2]) << 16
        value |= UInt32(self[from + 3]) << 24

        return value
    }

    func toHexString() -> String {
        return self.map { String(format: "%02hhx", $0) }.joined(separator: "-")
    }
}

private enum W2STID: String {
    case HWSenseService = "00000000-0001-11E1-9AB4-0002A5D5C51B"
    case Environmental  = "00000000-0001-11E1-AC36-0002A5D5C51B"
    // XXX: Environmental UUID is generated dynamically.
    case EnvTTBP        = "001D0000-0001-11E1-AC36-0002A5D5C51B"
    case AccEvent       = "00000400-0001-11E1-AC36-0002A5D5C51B"
    case Max            = "00008000-0001-11E1-AC36-0002A5D5C51B"
    case GG             = "00020000-0001-11E1-AC36-0002A5D5C51B"
    case AccGyroMag     = "00E00000-0001-11E1-AC36-0002A5D5C51B"
    case Arming         = "20000000-0001-11E1-AC36-0002A5D5C51B"

    case ConsoleService = "00000000-000E-11E1-9AB4-0002A5D5C51B"
    case STDInOut       = "00000001-000E-11E1-AC36-0002A5D5C51B"
    case STDErr         = "00000002-000E-11E1-AC36-0002A5D5C51B"

    case ConfigService  = "00000000-000F-11E1-9AB4-0002A5D5C51B"
    case Config         = "00000002-000F-11E1-AC36-0002A5D5C51B"
}

private func fmtUUID(_ uuid: CBUUID) -> String {
    let uuidDict:Dictionary<String,String> = [
        CBUUIDCharacteristicExtendedPropertiesString : "ExtendedProperty",
        CBUUIDCharacteristicUserDescriptionString: "UserDescription",
        CBUUIDClientCharacteristicConfigurationString: "CCCD",
        CBUUIDServerCharacteristicConfigurationString: "SCCD",
        CBUUIDCharacteristicFormatString: "CharacteristicFormat",
        CBUUIDCharacteristicAggregateFormatString: "CharacteristicAggregateFormat",

        W2STID.HWSenseService.rawValue: "W2ST.HWSenseService",
        W2STID.ConsoleService.rawValue: "W2ST.ConsoleService",
        W2STID.ConfigService.rawValue: "W2ST.ConfigService",

        W2STID.Environmental.rawValue: "W2ST.Environmental",
        W2STID.AccEvent.rawValue: "W2ST.AccEvent",
        W2STID.Max.rawValue: "W2ST.Max",
        W2STID.AccGyroMag.rawValue: "W2ST.AccGyroMag",
        W2STID.Arming.rawValue: "W2ST.Arming",
        W2STID.GG.rawValue: "W2ST.GG",
        W2STID.STDInOut.rawValue: "W2ST.STDOUT",
        W2STID.STDErr.rawValue: "W2ST.STDERR",
        W2STID.Config.rawValue: "W2ST.Config",

        // XXX: Environmental UUID is generated dynamically.
        W2STID.EnvTTBP.rawValue: "W2ST.Env(Temp,Temp,Battery,Pressure)",
    ]

    for key in uuidDict.keys {
        if uuid.uuidString == key, let value = uuidDict[key] {
            return value
        }
    }
    return uuid.uuidString
}

private func fmtProps(_ props: CBCharacteristicProperties) -> String {
    var result: [String] = []

    if props.contains(.broadcast) {
        result.append("broadcast")
    }
    if props.contains(.read) {
        result.append("read")
    }
    if props.contains(.writeWithoutResponse) {
        result.append("writeWithoutResponse")
    }
    if props.contains(.write) {
        result.append("write")
    }
    if props.contains(.notify) {
        result.append("notify")
    }
    if props.contains(.indicate) {
        result.append("indicate")
    }
    if props.contains(.authenticatedSignedWrites) {
        result.append("authenticatedSignedWrites")
    }
    if props.contains(.extendedProperties) {
        result.append("extendedProperties")
    }
    if props.contains(.notifyEncryptionRequired) {
        result.append("nofityEncryptionRequired")
    }
    if props.contains(.indicateEncryptionRequired) {
        result.append("indicateEncryptionRequired")
    }

    return result.joined(separator: "+")
}

private func fmtValueEnvTTBP(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Press \(value.readUint32LE(from: 2))"
    result += ", Batt \(value.readUint16LE(from: 6))"
    result += ", Temp \(value.readUint16LE(from: 8))"
    result += ", RSSI \(value.readUint16LE(from: 10))"

    return result
}

private func fmtValueAccGyroMag(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Acc.X \(value.readUint16LE(from: 2))"
    result += ", Acc.Y \(value.readUint16LE(from: 4))"
    result += ", Acc.Z \(value.readUint16LE(from: 6))"
    result += ", Gyro.X \(value.readUint16LE(from: 8))"
    result += ", Gyro.Y \(value.readUint16LE(from: 10))"
    result += ", Gyro.Z \(value.readUint16LE(from: 12))"
    result += ", Axis.X \(value.readUint16LE(from: 14))"
    result += ", Axis.Y \(value.readUint16LE(from: 16))"
    result += ", Axis.Z \(value.readUint16LE(from: 18))"
    return result
}

private func fmtValueArming(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Arming \(value[2])"

    return result
}

private func fmtValue(_ characteristic: CBCharacteristic) -> String {
    guard let value = characteristic.value else {
        return "(N/A)"
    }
    let hex = value.toHexString()
    switch W2STID(rawValue: characteristic.uuid.uuidString) {
        case .STDInOut:
            fallthrough
        case .STDErr:
            return "\(value): \(hex): '" + (String(data: value, encoding: String.Encoding.ascii) ?? "(invalid)") + "'";
        case .EnvTTBP:
            return "\(value): \(hex): \(fmtValueEnvTTBP(value))"
        case .AccGyroMag:
            return "\(value): \(hex): \(fmtValueAccGyroMag(value))"
        case .Arming:
            return "\(value): \(hex): \(fmtValueArming(value))"
        default:
            break;
    }
    return "\(value): \(hex)"
}

private func fmtDescriptor(_ descriptor: CBDescriptor) -> String {
    guard let value = descriptor.value as? Data else {
        return "(N/A)"
    }
    let hex = value.toHexString()

    switch (descriptor.uuid.uuidString) {
    case CBUUIDClientCharacteristicConfigurationString:
        return "\(value): \(hex): \(String(value[0]))"
    default:
        break
    }

    return "\(value): \(hex)"
}

open class STDronePeripheral: NSObject, CBPeripheralDelegate {
    public var name: String = "(uninitialized)"
    public var identifier: UUID = UUID()
    public var central: CBCentralManager!
    public var peripheral: CBPeripheral!
    public var services: [CBService]

    override init () {
        self.services = []
        super.init()
    }

    convenience init(peripheral: CBPeripheral, withCentral: CBCentralManager) {
        self.init()
        self.central = withCentral
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.name = peripheral.name ?? "(NO NAME)"
        self.identifier = peripheral.identifier
    }

    // CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error {
            print(e)
            return
        }
        print("didDiscoverServices called.")
        for service in peripheral.services! {
            print("found service: \(service.uuid.uuidString)")
            self.services.append(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let e = error {
            print(e)
            return
        }
        for characteristic in service.characteristics! {
            peripheral.discoverDescriptors(for: characteristic)
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                print("Enable Notification: \(fmtUUID(characteristic.uuid))")
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print(e)
            return
        }
        showService()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let e = error {
            print(e)
            return
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print(e)
            return
        }
        guard let descriptors = characteristic.descriptors else {
            return
        }
        for descriptor in descriptors {
            peripheral.readValue(for: descriptor)
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            print(e)
            return
        }
        print("Notification State changed: \(fmtUUID(characteristic.uuid))")
    }

    // open
    open func dump() {
        peripheral.discoverServices(nil)
    }

    open func showService() {
        for service in services {
            print("service: \(fmtUUID(service.uuid))")
            guard let characteristics = service.characteristics else {
                return
            }
            for characteristic in characteristics {
                print("  -> characteristic: \(fmtUUID(characteristic.uuid))")
                print("     -> value: \(fmtValue(characteristic))")
                print("     -> property: \(fmtProps(characteristic.properties))")

                if let descriptors = characteristic.descriptors {
                    for descriptor in descriptors {
                        print("     -> descriptor: \(fmtUUID(descriptor.uuid))")
                        print("        -> value: \(fmtDescriptor(descriptor))")
                    }
                }
            }
        }
    }

    open func connect() {
        self.central.stopScan()
        self.central.connect(peripheral, options: nil)
    }
}

open class STDroneCentralManager: NSObject, CBCentralManagerDelegate {
    var manager: CBCentralManager!
    var peripherals: Dictionary<UUID, STDronePeripheral> = [:]
    var enable: Bool
    let targetLocalNames: [String] = ["DRN1110", "DRN1120"]
    var onFound: (([STDronePeripheral]) -> Void)?

    override public init () {
        enable = false
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    // CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
            case .poweredOff:
                print("poweredOff")
            case .poweredOn:
                print("poweredOn")
                if (enable) {
                    self.triggerScan()
                }
            case .resetting:
                print("poweredOn")
            case .unauthorized:
                print("unauthorized")
            case .unknown:
                print("unknown")
            case .unsupported:
                print("unsupportred")
            @unknown default:
                print("Unknown State")
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else {
            // Ignore anoymous peripherals
            return
        }
        if targetLocalNames.contains(name) {
            if peripherals[peripheral.identifier] == nil {
                peripherals[peripheral.identifier] = STDronePeripheral(peripheral: peripheral, withCentral: manager)
                onFound?(peripherals.map {$1})
            }
        }
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected.")
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connection error.")
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected.")
    }

    // open
    open func triggerScan() {
        if manager.isScanning == false {
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    open func start(_ callback: @escaping ([STDronePeripheral]) -> Void) {
        self.enable = true
        self.onFound = callback
        if manager.state == .poweredOn {
            self.triggerScan()
        }
    }

    open func stop() {
        self.enable = false
        if manager.isScanning {
            manager.stopScan()
        }
    }
}
