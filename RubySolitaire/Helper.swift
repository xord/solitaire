class Helper {

    static var isDebug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    static var isRelease: Bool {
        !isDebug
    }

    static var isUnitTest: Bool {
        NSClassFromString("XCTest") != nil
    }

    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static var isMac: Bool {
        ProcessInfo.processInfo.isiOSAppOnMac
    }

    static var language: String? {
        guard let lang = Locale.preferredLanguages.first else {
            return nil
        }
        guard let first = lang.split(separator: "-").first else {
            return lang
        }
        return String(first)
    }

    static func getInfoString(_ key: String, plistName: String? = nil) -> String? {
        guard let dic = getPlist(plistName) else {
            return nil
        }
        return dic[key] as? String
    }

    static func getPlist(_ name: String? = nil) -> [String: Any]? {
        guard let name = name else {
            return Bundle.main.infoDictionary
        }
        guard let path = Bundle.main.path(forResource: name, ofType: "plist") else {
            return nil
        }
        return NSDictionary(contentsOfFile: path) as? [String: Any]
    }

}// Helper
