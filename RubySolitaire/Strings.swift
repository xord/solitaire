enum Strings : String, CaseIterable {
    case appName

    case close

    case menuPrivacyPolicy
    case menuLicenses

    var s: String {
        return getString(rawValue) ?? getBaseString(rawValue)
    }

    func format(_ args: CVarArg...) -> String {
        return String.init(format: s, arguments: args)
    }

    private func getString(_ key: String) -> String? {
        let string = NSLocalizedString(key, value: Strings.NOT_FOUND, comment: "")
        if string == Strings.NOT_FOUND {
            return nil
        }

        return string
    }

    private func getBaseString(_ key: String) -> String {
        guard let bundle = Strings.BASE_BUNDLE else {
            fatalError("Base bundle not found")
        }

        let string = NSLocalizedString(key, bundle: bundle, value: Strings.NOT_FOUND, comment: "")
        if string == Strings.NOT_FOUND {
            fatalError("'\(key)' not found")
        }

        return string
    }

    static private let NOT_FOUND = "__NOT_FOUND__"

    static private let BASE_BUNDLE: Bundle? = {
        guard let path = Bundle.main.path(forResource: "Base", ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
    }()
}
