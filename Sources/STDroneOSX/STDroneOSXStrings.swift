//
//  STDroneOSXStrings.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/20.
//

import Foundation
import CoreBluetooth

internal func fmtUUID(_ uuid: CBUUID) -> String {
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

internal func fmtProps(_ props: CBCharacteristicProperties) -> String {
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

internal func fmtValueEnvTTBP(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Press \(value.readUint32LE(from: 2))"
    result += ", Batt \(value.readUint16LE(from: 6))"
    result += ", Temp \(value.readUint16LE(from: 8))"
    result += ", RSSI \(value.readInt16LE(from: 10))"

    return result
}

internal func fmtValueAccGyroMag(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Acc.X \(value.readInt16LE(from: 2))"
    result += ", Acc.Y \(value.readInt16LE(from: 4))"
    result += ", Acc.Z \(value.readInt16LE(from: 6))"
    result += ", Gyro.X \(value.readInt16LE(from: 8))"
    result += ", Gyro.Y \(value.readInt16LE(from: 10))"
    result += ", Gyro.Z \(value.readInt16LE(from: 12))"
    result += ", Mag.X \(value.readInt16LE(from: 14))"
    result += ", Mag.Y \(value.readInt16LE(from: 16))"
    result += ", Mag.Z \(value.readInt16LE(from: 18))"
    return result
}

internal func fmtValueArming(_ value: Data) -> String {
    var result = ""

    result += "Tick \(value.readUint16LE(from: 0))"
    result += ", Arming \(value[2])"

    return result
}

internal func fmtValue(_ characteristic: CBCharacteristic) -> String {
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

internal func fmtDescriptor(_ descriptor: CBDescriptor) -> String {
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
