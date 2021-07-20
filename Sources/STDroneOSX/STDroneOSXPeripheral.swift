//
//  STDroneOSXPeripheral.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/20.
//

import Foundation
import CoreBluetooth

open class STDronePeripheral: NSObject, CBPeripheralDelegate {
    // ID
    public var name: String = "(uninitialized)"
    public var identifier: UUID = UUID()
    // Back pointers
    public var central: STDroneCentralManager!
    public var peripheral: CBPeripheral!
    // Telemetry(=RX) Data Store
    public var telemetry: W2STTelemetry
    // Flight Control(=TX) Data Store
    public var joydata: CBCharacteristic?
    public var joyDataToSend: Data = Data(count: 7)
    public var joyTimer: Timer?
    public var joyInterval: Double = 0.1
    public var joyVerbose: Bool = false
    // state of discovery process
    public var inDiscovery: Bool = false
    public var inProgress: Int = 0
    // state of console handling
    public var stdin: CBCharacteristic?
    public var stdoutNotTerm: String? = nil
    public var stderrNotTerm: String? = nil
    // callback holders
    public var discoverCallback: (() -> Void)?
    public var notifyCallback: ((W2STTelemetry) -> Void)?
    public var disconnectCallback: (() -> Void)?

    override init () {
	self.telemetry = W2STTelemetry()
	super.init()
    }

    convenience init(peripheral: CBPeripheral, withCentral: STDroneCentralManager) {
	self.init()
	self.central = withCentral
	self.peripheral = peripheral
	self.peripheral.delegate = self
	self.name = peripheral.name ?? "(NO NAME)"
	self.identifier = peripheral.identifier
    }

    //
    // Interface: CBPeripheralDelegate
    //

    // Service
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
	if let e = error {
	    print(e)
	    decProgress()
	    return
	}
	for service in peripheral.services! {
	    addProgress()
	    peripheral.discoverCharacteristics(nil, for: service)
	}
	decProgress()
    }

    // Characteristics
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
	if let e = error {
	    decProgress()
	    print(e)
	    return
	}
	for characteristic in service.characteristics! {
	    // Discover Descriptors
	    addProgress()
	    peripheral.discoverDescriptors(for: characteristic)

	    // Handle Values
	    if characteristic.properties.contains(.read) {
		addProgress()
		peripheral.readValue(for: characteristic)
	    }

	    // Keep some characteristic for writing.
	    let id = W2STID(rawValue: characteristic.uuid.uuidString)
	    switch (id) {
	    case .STDInOut:
		stdin = characteristic
	    case .Max:
		joydata = characteristic
	    default:
		break
	    }
	}
	decProgress()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
	if let e = error {
	    decProgress()
	    print(e)
	    return
	}
	parseCharValue(characteristic)
	decProgress()
	if inDiscovery == false, notifyCallback != nil {
	    notifyCallback!(telemetry)
	}
    }

    public func peripheral(_ peripheral: CBPeripheral,
			   didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
	if let e = error {
	    print("Write Error: \(e)")
	    return
	}
    }

    // Descritors
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
	if let e = error {
	    decProgress()
	    print(e)
	    return
	}
	guard let descriptors = characteristic.descriptors else {
	    decProgress()
	    return
	}
	for descriptor in descriptors {
	    addProgress()
	    peripheral.readValue(for: descriptor)
	}
	decProgress()
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
	if let e = error {
	    decProgress()
	    print(e)
	    return
	}
	decProgress()
    }

    // Notification
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
	if let e = error {
	    print(e)
	    return
	}
    }

    //
    // private utilities
    //
    private func addProgress() {
	if inDiscovery {
	    inProgress += 1
	}
    }

    private func decProgress() {
	if inDiscovery {
	    inProgress -= 1
	    if inProgress == 0, discoverCallback != nil {
		discoverCallback!()
		inDiscovery = false
		discoverCallback = nil
	    }
	}
    }

    private func parseConsole(_ rawString: String?, addTo:inout [String], reminder:inout String?) {
	guard var inputString = rawString else {
		return
	}
	if reminder != nil {
		inputString = reminder! + inputString
		reminder = nil
	}
	var token = inputString.components(separatedBy: .newlines).filter {
		$0.count > 0
	}
	if inputString.last != "\n", inputString.last != "\r\n" {
		if (token.count > 0) {
			reminder = token.removeLast()
		}
		else {
			reminder = inputString
		}
	}
	guard token.count > 0 else {
		return
	}
	addTo.append(contentsOf: token)
    }

    private func parseCharValue(_ characteristic: CBCharacteristic) {
	guard let value = characteristic.value else {
	    return
	}
	let id = W2STID(rawValue: characteristic.uuid.uuidString)

	switch id {
	case .EnvTTBP:
	    telemetry.environment.tick =
		value.readUint16LE(from: 0)
	    telemetry.environment.pressure =
		value.readInt32LE(from: 2)
	    telemetry.environment.battery =
		value.readUint16LE(from: 6)
	    telemetry.environment.temprature =
		value.readInt16LE(from: 8)
	    telemetry.environment.RSSI =
		value.readInt16LE(from: 10)
	case .AccGyroMag:
	    telemetry.AHRS.tick = value.readUint16LE(from: 0)
	    telemetry.AHRS.acceleration.x =
		value.readInt16LE(from: 2)
	    telemetry.AHRS.acceleration.y =
		value.readInt16LE(from: 4)
	    telemetry.AHRS.acceleration.z =
		value.readInt16LE(from: 6)
	    telemetry.AHRS.gyrometer.x =
		value.readInt16LE(from: 8)
	    telemetry.AHRS.gyrometer.y =
		value.readInt16LE(from: 10)
	    telemetry.AHRS.gyrometer.z =
		value.readInt16LE(from: 12)
	    telemetry.AHRS.mag.x =
		value.readInt16LE(from: 14)
	    telemetry.AHRS.mag.y =
		value.readInt16LE(from: 16)
	    telemetry.AHRS.mag.z =
		value.readInt16LE(from: 18)
	case .Arming:
	    telemetry.arming.tick = value.readUint16LE(from: 0)
	    telemetry.arming.enabled = (value[2] != 0)
	case .STDInOut:
	    parseConsole(String(data: value, encoding: .ascii), addTo: &telemetry.stdout, reminder: &stdoutNotTerm)
	case .STDErr:
	    parseConsole(String(data: value, encoding: .ascii), addTo:&telemetry.stderr, reminder: &stderrNotTerm)
	default:
	    break
	}
    }

    private func setNotifyAll(_ enable: Bool) {
	guard peripheral.state == .connected else {
	    return
	}
	guard let services = peripheral.services else {
	    return
	}
	for service in services {
	    guard let characteristics = service.characteristics else {
		continue
	    }

	    for characteristic in characteristics {
		if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
		    peripheral.setNotifyValue(enable, for: characteristic)
		}
	    }
	}
    }

    //
    // open methods
    //
    open func connect(_ callback: ((Error?) -> Void)? = nil) {
	self.central.stop()
	self.joyDataToSend = Data(count: 7)
	self.central.connect(peripheral) { error in
	    guard error == nil else {
		callback?(error)
		return
	    }
	    self.joyTimer = Timer.scheduledTimer(withTimeInterval: self.joyInterval, repeats: true, block: { timer in
		guard self.peripheral.state == .connected else {
		    return
		}
		guard let characteristic = self.joydata else {
		    return
		}
		self.peripheral.writeValue(self.joyDataToSend, for: characteristic, type: .withoutResponse)
		if self.joyVerbose {
		    print("Sent joyData: \(self.joyDataToSend)")
		}
	    })
	    callback?(nil)
	}
    }

    open func disconnectComplete() {
	disconnectCallback?()
    }

    open func disconnect() {
	setNotifyAll(false)
	self.joyTimer?.invalidate()
	if self.peripheral.state == .connected {
	    self.central.disconnect(peripheral)
	}
    }

    open func discoverAll(_ callback: (() -> Void)? = nil) {
	self.discoverCallback = callback
	inDiscovery = true
	addProgress()
	peripheral.discoverServices(nil)
    }

    open func onUpdate(_ callback: @escaping ((W2STTelemetry) -> Void)) {
	notifyCallback = callback
	setNotifyAll(true)
    }

    open func onDisconnect(_ callback: @escaping (() -> Void)) {
	disconnectCallback = callback
    }

    open func writeJoydata(data: Data) {
	if data.count == 0 {
	    print("writeJoydata: invalid data size \(data.count).")
	    return
	}
	self.joyDataToSend.replaceSubrange(0...6, with: data)
    }

    open func writeStdin(text: String) {
	guard peripheral.state == .connected else {
	    return
	}
	if text.count == 0 {
	    print("writeStdin: invalid data size \(text.count).")
	    return
	}
	guard let characteristic = stdin else {
	    print("no characteristic found.")
	    return
	}
	let data = text.data(using: .ascii)
	if data != nil {
	    peripheral.writeValue(data!, for: characteristic, type: .withResponse)
	}
    }

    open func showServices() {
	guard let services = peripheral.services else {
		return
	}
	for service in services {
	    print("service: \(fmtUUID(service.uuid))")
	    guard let characteristics = service.characteristics else {
		return
	    }
	    for characteristic in characteristics {
		print("  -> characteristic: \(fmtUUID(characteristic.uuid))")
		if characteristic.properties.contains(.read) {
		    print("     -> value: \(fmtValue(characteristic))")
		}
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
}
