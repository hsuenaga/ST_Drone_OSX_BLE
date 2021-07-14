//
//  File.swift
//  
//
//  Created by SUENAGA Hiroki on 2021/07/07.
//

import Foundation
import CoreBluetooth
import STDroneOSX

var readTelemetry = false
if (CommandLine.arguments.contains("-f")) {
    readTelemetry = true
}


let central = STDroneCentralManager()
central.start { devices in
    for device in devices {
        print("DevList: \(device.name) (\(device.identifier))")
    }

    let dev = devices[0]

    dev.joyVerbose = true
    dev.connect { error in
        if error != nil {
            print("connection error: \(error!)")
            return
        }
        print("conected.")

        dev.discoverAll {
            dev.showServices()
            if readTelemetry {
                dev.onUpdate {telemetry in
                    print(telemetry)
                }
            }
            else {
                exit(0)
            }
        }
    }
}

RunLoop.main.run()
