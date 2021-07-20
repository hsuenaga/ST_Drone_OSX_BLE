//
//  STDroneOSXCentral.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/20.
//

import Foundation
import CoreBluetooth

open class STDroneCentralManager: NSObject, CBCentralManagerDelegate {
    var manager: CBCentralManager!
    var peripherals: Dictionary<UUID, STDronePeripheral> = [:]
    var enable: Bool
    let targetLocalNames: [String] = ["DRN1110", "DRN1120"]
    var onFound: (([STDronePeripheral]) -> Void)?
    var onConnect: ((Error?) -> Void)?
    var onDisconnect: (() -> Void)?

    override public init () {
	enable = false
	super.init()
	manager = CBCentralManager(delegate: self, queue: nil)
    }

    //
    // CBCentralManagerDelegate
    //

    // state
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

    // peripheral
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
	guard let name = peripheral.name else {
	    // Ignore anoymous peripherals
	    return
	}
	if targetLocalNames.contains(name) {
	    if peripherals[peripheral.identifier] == nil {
		peripherals[peripheral.identifier] = STDronePeripheral(peripheral: peripheral, withCentral: self)
		onFound?(peripherals.map {$1})
	    }
	}
    }

    // connection
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
	if onConnect != nil {
	    onConnect!(nil)
	}
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
	if onConnect != nil {
	    onConnect!(error)
	}
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
	if onDisconnect != nil {
	    onDisconnect!()
	}
	guard let target = peripherals[peripheral.identifier] else {
	    return
	}
	target.disconnectComplete()
    }

    //
    // open method
    //
    open func triggerScan() {
	if manager.isScanning == false {
	    manager.scanForPeripherals(withServices: nil, options: nil)
	}
    }

    open func start(_ callback: (([STDronePeripheral]) -> Void)? = nil) {
	self.enable = true
	self.onFound = callback
	if manager.state == .poweredOn {
	    self.triggerScan()
	}
	if peripherals.count > 0 {
	    onFound?(peripherals.map{$1})
	}
    }

    open func stop() {
	self.enable = false
	if manager.isScanning {
	    manager.stopScan()
	}
    }

    open func connect(_ peripheral: CBPeripheral, _ callback: ((Error?) -> Void)? = nil) {
	onConnect = callback
	manager.connect(peripheral, options: nil)
    }

    open func disconnect(_ peripheral: CBPeripheral, _ callback: (() -> Void)? = nil) {
	onDisconnect = callback
	manager.cancelPeripheralConnection(peripheral)
    }
}
