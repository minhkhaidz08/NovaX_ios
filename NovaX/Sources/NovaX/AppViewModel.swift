import SwiftUI
import Foundation
import Combine

// MARK: - Settings (mirrors com.novax.app.model.AppSettings)

struct AppSettings {
    var animationsEnabled: Bool = true
    var animationSpeed: AnimationSpeed = .normal
    var language: String = "English"
    var notificationsEnabled: Bool = true
    var themeDark: Bool = true
    var glassAlpha: Double = 0.06

    enum AnimationSpeed: String {
        case slow = "Slow", normal = "Normal", fast = "Fast"
    }
}

// MARK: - App State

@MainActor
final class AppViewModel: NSObject, ObservableObject {

    // MARK: Auth
    @Published var authState: AuthState = .splash
    @Published var licenseKey: String = ""
    @Published var hwid: String = DeviceUtils.hwid
    @Published var keyType: String = "basic"
    @Published var expiresAt: Date?
    @Published var errorMessage: String?

    enum AuthState: Equatable {
        case splash
        case idle
        case loading(String)
        case verified
        case error(String)
    }

    // MARK: Features
    @Published var featureStates: [String: Bool] = [:]

    // MARK: Settings
    @Published var settings = AppSettings()

    // MARK: Toast
    @Published var toastMessage: String?
    @Published var toastIsError: Bool = false
    private var toastTask: Task<Void, Never>?

    // MARK: Tabs (mirrors BottomNavItem: home / memory / profile / settings)
    @Published var selectedTab = 0

    // MARK: Networking
    private let pinnedSession: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        return URLSession(configuration: config,
                          delegate: CertPinningDelegate.shared,
                          delegateQueue: nil)
    }()

    // MARK: Persistence (mirrors SharedPreferences in AuthRepository)
    private let defaults = UserDefaults.standard
    private let savedKeyKey = "novax_saved_key"

    // MARK: Monitor
    private var monitorTask: Task<Void, Never>?
    private var reVerifyFailCount = 0
    private let maxReVerifyRetries = 3

    override init() {
        super.init()
        if let saved = defaults.string(forKey: savedKeyKey), !saved.isEmpty {
            licenseKey = saved
        }
    }

    // MARK: - Derived helpers (mirrors com.novax.app.model.User)

    var username: String { String(licenseKey.prefix(8)) }

    var displayType: String {
        switch keyType.lowercased() {
        case "vip":  return "VIP"
        case "pro":  return "PRO"
        case "basic": return "BASIC"
        default:     return keyType.uppercased()
        }
    }

    var expiresLabel: String {
        guard let d = expiresAt else { return "N/A" }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: d)
    }

    // MARK: - Features (mirrors Constants.Basic/Pro/Vip)

    struct ModFeature: Identifiable, Equatable {
        let id: String
        let title: String
        let description: String
        let section: String   // "basic" | "pro" | "vip"
        var isEnabled: Bool = false
    }

    var allFeatures: [ModFeature] {
        basicFeatures + proFeatures + vipFeatures
    }

    var basicFeatures: [ModFeature] {
        [
            ModFeature(id: "aimlock", title: "Aimlock", description: "Precise target locking mechanism", section: "basic", isEnabled: isFeatureEnabled("aimlock"))
        ]
    }

    var proFeatures: [ModFeature] {
        [
            ModFeature(id: "aimbot_legit_safe", title: "Aimbot Legit Safe", description: "Smooth aim assist with human-like movement", section: "pro", isEnabled: isFeatureEnabled("aimbot_legit_safe"))
        ]
    }

    var vipFeatures: [ModFeature] {
        [
            ModFeature(id: "aimbot_body", title: "Aimbot Body", description: "High-accuracy body center tracking", section: "vip", isEnabled: isFeatureEnabled("aimbot_body"))
        ]
    }

    func canAccess(_ section: String) -> Bool {
        // Strict mapping: Each key only unlocks its own tier (mirrors HomeViewModel.canAccess)
        keyType.lowercased() == section
    }

    func isFeatureUnlocked(_ feature: ModFeature) -> Bool {
        canAccess(feature.section)
    }

    func toggleFeature(_ feature: ModFeature) {
        guard canAccess(feature.section) else { return }
        featureStates[feature.id] = !(featureStates[feature.id] ?? false)
        let on = featureStates[feature.id] ?? false
        showToast(on ? "\(feature.title) active" : "\(feature.title) off")
    }

    func isFeatureEnabled(_ id: String) -> Bool {
        featureStates[id] ?? false
    }

    // MARK: - Launch Game (mirrors HomeViewModel.launchGame)

    func launchGame() {
        if GameDetect.detectedGame != nil {
            GameDetect.launch()
            showToast("Injecting into \(GameDetect.detectedName ?? "Free Fire")...")
        } else {
            showToast("Free Fire not found", isError: true)
        }
    }

    // MARK: - Auth

    func login() async {
        guard !licenseKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Key cannot be empty"
            authState = .error("Key cannot be empty")
            return
        }

        authState = .loading("Authenticating...")

        let key = licenseKey.trimmingCharacters(in: .whitespaces)
        let hw = hwid

        let urlBase = Obf.s([219,199,199,195,192,137,156,156,195,223,214,203,198,192,158,210,198,199,219,158,210,195,218,158,220,131,130,219,157,220,221,193,214,221,215,214,193,157,208,220,222,156,210,195,218,156,197,214,193,218,213,202,140,216,214,202,142], 0xB3)
        let sepHwid = Obf.s([149,219,196,218,215,142], 0xB3)
        let sepSecret = Obf.s([149,192,214,208,193,214,199,142], 0xB3)
        let secret = Obf.s([204,202,214,136,196,208,209,205,136,206,192,220], 0xA5)

        guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedHw = hw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedSecret = secret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(urlBase)\(encodedKey)\(sepHwid)\(encodedHw)\(sepSecret)\(encodedSecret)")
        else {
            authState = .error("Authentication failed")
            return
        }

        let result = await performVerify(url: url)
        switch result {
        case .success(let type, let expires):
            applyVerified(type: type, expiresAt: expires)
            defaults.set(key, forKey: savedKeyKey)
            authState = .verified
            errorMessage = nil
            startMonitor()
        case .invalid(let status, let message):
            let msg = errorMessage(for: status, serverMessage: message)
            authState = .error(msg)
            errorMessage = msg
        case .networkError(let msg):
            authState = .error(msg)
            errorMessage = msg
        }
    }

    func performSplashFlow() async {
        // Splash progress ~2.5s (mirrors SplashScreen duration)
        try? await Task.sleep(nanoseconds: 2_500_000_000)

        guard !licenseKey.isEmpty else {
            authState = .idle
            return
        }
        // Server health check before auto-login (mirrors AuthRepository.tryAutoLogin)
        let ok = await checkServer()
        guard ok else {
            authState = .idle
            return
        }
        authState = .loading("Securing Session...")
        await login()
        if case .error = authState {
            // Auto-login failure -> clear saved key + go to login quietly (mirrors Android tryAutoLogin)
            defaults.removeObject(forKey: savedKeyKey)
            licenseKey = ""
            authState = .idle
            errorMessage = nil
        }
    }

    func logout() {
        stopMonitor()
        defaults.removeObject(forKey: savedKeyKey)
        licenseKey = ""
        keyType = "basic"
        expiresAt = nil
        errorMessage = nil
        featureStates = [:]
        authState = .idle
    }

    func clearLoginError() {
        if case .error = authState {
            authState = .idle
        }
    }

    // MARK: - Verify request

    private enum VerifyResult {
        case success(type: String, expiresAt: Date?)
        case invalid(status: String, message: String)
        case networkError(String)
    }

    private func performVerify(url: URL) async -> VerifyResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30   // Android OkHttp: 30s

        do {
            let (data, response) = try await pinnedSession.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else {
                return .networkError("Cannot connect to server")
            }

            // Check empty body BEFORE parsing (mirrors Android: body.isBlank() first)
            guard !data.isEmpty else {
                return .invalid("", "Server returned empty response (HTTP \(httpResp.statusCode))")
            }

            let json: [String: Any]
            do {
                guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return .invalid("", "Server response error (invalid JSON)")
                }
                json = obj
            } catch {
                return .invalid("", "Server response error (invalid JSON)")
            }

            let success = json["success"] as? Bool ?? false
            let status = json["status"] as? String ?? ""
            let message = json["message"] as? String ?? ""
            let expiresRaw = json["expires_at"] as? String ?? ""
            let type = json["type"] as? String ?? "basic"

            guard httpResp.statusCode == 200, success, status == "valid" else {
                return .invalid(status, message)
            }

            // HMAC verification (if server provides it)
            if let serverHmac = json["hmac"] as? String {
                let computed = HMACUtils.compute(
                    key: Obf.s([204,202,214,136,196,208,209,205,136,206,192,220], 0xA5),
                    message: "\(success)|\(type)|\(expiresRaw)"
                )
                guard serverHmac == computed else {
                    return .invalid("", "Authentication failed")
                }
            }

            return .success(type: type, expiresAt: parseISO(expiresRaw))
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .networkError("No internet connection")
            case .timedOut:
                return .networkError("Connection timeout")
            case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return .networkError("Cannot connect to server")
            case .secureConnectionFailed:
                return .networkError("SSL error: \(error.localizedDescription)")
            default:
                return .networkError("[\(error.code.rawValue)] \(error.localizedDescription)")
            }
        } catch {
            return .networkError("[\(type(of: error))] \(error.localizedDescription)")
        }
    }

    private func errorMessage(for status: String, serverMessage: String) -> String {
        switch status {
        case "invalid":       return "Key không hợp lệ"
        case "expired":       return "Key đã hết hạn"
        case "banned":        return "Key đã bị khóa"
        case "hwid_mismatch": return "Key không đúng thiết bị"
        case "max_devices":   return "Đã vượt quá số thiết bị cho phép"
        default:              return serverMessage.isEmpty ? "Authentication failed" : serverMessage
        }
    }

    private func checkServer() async -> Bool {
        // Obfuscated: https://plexus-auth-api-o01h.onrender.com/api/health
        let url = URL(string: Obf.s([219,199,199,195,192,137,156,156,195,223,214,203,198,192,158,210,198,199,219,158,210,195,218,158,220,131,130,219,157,220,221,193,214,221,215,214,193,157,208,220,222,156,210,195,218,156,219,214,210,223,199,219], 0xB3))!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (_, response) = try await pinnedSession.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private func applyVerified(type: String, expiresAt: Date?) {
        keyType = type.isEmpty ? "basic" : type
        self.expiresAt = expiresAt
    }

    private func parseISO(_ raw: String) -> Date? {
        guard !raw.isEmpty else { return nil }
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = df.date(from: raw) { return d }
        df.formatOptions = [.withInternetDateTime]
        return df.date(from: raw)
    }

    // MARK: - Re-verify monitor (mirrors AuthRepository.startMonitor: 60s, 3 fails -> logout)

    private func startMonitor() {
        stopMonitor()
        reVerifyFailCount = 0
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard let self else { return }
                await self.reVerify()
            }
        }
    }

    private func reVerify() async {
        guard !licenseKey.isEmpty else { return }
        let key = licenseKey.trimmingCharacters(in: .whitespaces)
        let hw = hwid

        let urlBase = Obf.s([219,199,199,195,192,137,156,156,195,223,214,203,198,192,158,210,198,199,219,158,210,195,218,158,220,131,130,219,157,220,221,193,214,221,215,214,193,157,208,220,222,156,210,195,218,156,197,214,193,218,213,202,140,216,214,202,142], 0xB3)
        let sepHwid = Obf.s([149,219,196,218,215,142], 0xB3)
        let sepSecret = Obf.s([149,192,214,208,193,214,199,142], 0xB3)
        let secret = Obf.s([204,202,214,136,196,208,209,205,136,206,192,220], 0xA5)

        guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedHw = hw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedSecret = secret.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(urlBase)\(encodedKey)\(sepHwid)\(encodedHw)\(sepSecret)\(encodedSecret)")
        else { return }

        await checkServer()

        let result = await performVerify(url: url)
        switch result {
        case .success(let type, let expires):
            // Any successfully parsed response resets failCount (mirrors Android)
            reVerifyFailCount = 0
            applyVerified(type: type, expiresAt: expires)
        case .invalid(let status, _):
            reVerifyFailCount = 0
            if isTerminalStatus(status) {
                forceLogout()
            }
        case .networkError:
            reVerifyFailCount += 1
            if reVerifyFailCount >= maxReVerifyRetries {
                forceLogout()
            }
        }
    }

    private func forceLogout() {
        stopMonitor()
        defaults.removeObject(forKey: savedKeyKey)
        licenseKey = ""
        keyType = "basic"
        expiresAt = nil
        featureStates = [:]
        authState = .idle
    }

    private func isTerminalStatus(_ status: String) -> Bool {
        ["expired", "banned", "invalid", "hwid_mismatch", "max_devices"].contains(status)
    }

    private func stopMonitor() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    // MARK: - Toast

    func showToast(_ message: String, isError: Bool = false, duration: TimeInterval = 2.5) {
        toastTask?.cancel()
        toastMessage = message
        toastIsError = isError
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            self?.toastMessage = nil
        }
    }

    // MARK: - Settings

    func setAnimationsEnabled(_ enabled: Bool) { settings.animationsEnabled = enabled }
    func setThemeDark(_ dark: Bool) { settings.themeDark = dark }
    func setNotificationsEnabled(_ enabled: Bool) { settings.notificationsEnabled = enabled }
    func setGlassAlpha(_ alpha: Double) { settings.glassAlpha = alpha }

    func resetPreferences() {
        settings = AppSettings()
    }
}
