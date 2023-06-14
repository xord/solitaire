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

}// Helper
