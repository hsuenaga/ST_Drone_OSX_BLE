//
//  File.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/07.
//

import Foundation
import CoreBluetooth
import STDroneOSX

let central = STDroneCentralManager()
central.start { devices in
    for device in devices {
        print("DevList: \(device.name) (\(device.identifier))")
    }
    devices[0].connect()
}

RunLoop.main.run()
