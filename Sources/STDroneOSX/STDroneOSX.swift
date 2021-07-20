import CoreBluetooth

internal enum W2STID: String {
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


public struct W2STTelemetry {
    public struct W2STEnvironment {
        public var tick: UInt16 = 0
        public var pressure: Int32 = 0
        public var battery: UInt16 = 0
        public var temprature: Int16 = 0
        public var RSSI: Int16 = 0
    }
    public var environment: W2STEnvironment = W2STEnvironment()

    public struct W2STAHRS {
        public var tick: UInt16 = 0
        public struct W2STAcceleration {
            public var x: Int16 = 0
            public var y: Int16 = 0
            public var z: Int16 = 0
        }
        public var acceleration: W2STAcceleration = W2STAcceleration()

        public struct W2STGyrometer {
            public var x: Int16 = 0
            public var y: Int16 = 0
            public var z: Int16 = 0
        }
        public var gyrometer: W2STGyrometer = W2STGyrometer()

        public struct W2STMag {
            public var x: Int16 = 0
            public var y: Int16 = 0
            public var z: Int16 = 0
        }
        public var mag: W2STMag = W2STMag()
    }
    public var AHRS: W2STAHRS = W2STAHRS()

    public struct W2STArming {
        public var tick: UInt16 = 0
        public var enabled: Bool = false
    }
    public var arming: W2STArming = W2STArming()

    public var stdout: [String] = []
    public var stderr: [String] = []

    public init() {
        self.environment = W2STEnvironment()
	self.AHRS = W2STAHRS()
        self.arming = W2STArming()
    }
}

