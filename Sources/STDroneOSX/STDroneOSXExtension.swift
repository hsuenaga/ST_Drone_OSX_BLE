//
//  STDroneOSXExtension.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/20.
//

import Foundation

extension Data {
    func readInt16LE(from: Int) -> Int16 {
	var value: Int16
	var signed = false
	var uvalue: UInt16 = self.readUint16LE(from: from)

	signed = ((uvalue & 0x8000) != 0)
	if signed {
	    uvalue = ~uvalue + 1
	    value = -Int16(uvalue)
	}
	else {
	    value = Int16(uvalue)
	}

	return value
    }

    func readInt32LE(from: Int) -> Int32 {
	var value: Int32
	var signed = false
	var uvalue: UInt32 = self.readUint32LE(from: from)

	signed = ((uvalue & 0x8000_0000) != 0)
	if signed {
	    uvalue = ~uvalue + 1
	    value = -Int32(uvalue)
	}
	else {
	    value = Int32(uvalue)
	}

	return value
    }

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
