import UIKit
import CryptoKit
import Darwin

// MARK: - Device info (mirrors com.novax.app.utils.DeviceInfoUtil)

struct DeviceUtils {

    // HWID: SHA-256 of stable device id, first 8 bytes => 16 hex chars (mirrors Android)
    static var hwid: String {
        if let cached = KeychainUtils.read(key: "novax_device_hwid") {
            return cached
        }
        var source = ""
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            source = vendorId
        } else {
            source = UUID().uuidString
        }
        let newHwid = String(sha256Hex(source).prefix(16)).lowercased()
        _ = KeychainUtils.save(key: "novax_device_hwid", value: newHwid)
        return newHwid
    }

    static var manufacturer: String { "Apple" }

    static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let bytes = mirror.children.compactMap { $0.value as? Int8 }
        return String(cString: bytes).trimmingCharacters(in: .whitespaces)
    }

    static var osVersion: String { UIDevice.current.systemVersion }

    static var chipName: String {
        let model = deviceModel
        if model.contains("iPhone17") || model.contains("iPhone16,6") { return "A18 / A18 Pro" }
        if model.contains("iPhone15") { return "A17 Pro" }
        if model.contains("iPhone14,7") || model.contains("iPhone14,8") { return "A15 Bionic" }
        if model.contains("iPhone14") { return "A15 Bionic" }
        if model.contains("iPhone13") { return "A15 / A14 Bionic" }
        if model.contains("iPhone12") { return "A14 / A13 Bionic" }
        if model.contains("iPhone11") { return "A13 Bionic" }
        return "Apple Silicon"
    }

    static var gpuName: String {
        "Apple GPU (\(chipName))"
    }

    static var cpuCores: Int { ProcessInfo.processInfo.processorCount }

    static var totalRAM: UInt64 { ProcessInfo.processInfo.physicalMemory }

    static var availableRAM: UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let host = mach_host_self()
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(host, HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let pageSize = UInt64(vm_kernel_page_size)
        return UInt64(stats.free_count + stats.inactive_count) * pageSize
    }

    static var screenResolution: String {
        let s = UIScreen.main.nativeBounds
        return "\(Int(s.width))x\(Int(s.height))"
    }

    static var refreshRate: Int {
        Int(UIScreen.main.maximumFramesPerSecond)
    }

    static var screenDensity: Int {
        Int(UIScreen.main.scale * 160)
    }

    static var batteryPercent: Int {
        if !UIDevice.current.isBatteryMonitoringEnabled {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        let level = UIDevice.current.batteryLevel
        return level < 0 ? 0 : Int(level * 100)
    }

    static var batteryTemperature: Double {
        // iOS does not expose battery temperature publicly
        return 0
    }

    // MARK: - Storage

    static var storageTotal: Int64 {
        guard let (_, total) = storageValues() else { return 0 }
        return total
    }

    static var storageFree: Int64 {
        guard let (free, _) = storageValues() else { return 0 }
        return free
    }

    static func storageValues() -> (free: Int64, total: Int64)? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let url = paths.first else { return nil }
        do {
            let keys: Set<URLResourceKey> = [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ]
            let values = try url.resourceValues(forKeys: keys)
            if let free = values.volumeAvailableCapacityForImportantUsage,
               let total = values.volumeTotalCapacity {
                return (Int64(free), Int64(total))
            }
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Format

    // Mirrors Android MemoryScreen.formatBytes: "#,##0.#" + B/KB/MB/GB/TB, "0 B" for <= 0
    static func formatBytes(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 B" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        let digitGroups = min(Int(log10(Double(bytes)) / log10(1024.0)), units.count - 1)
        let value = Double(bytes) / pow(1024.0, Double(digitGroups))
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        nf.minimumFractionDigits = 0
        let formatted = nf.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formatted) \(units[digitGroups])"
    }

    static func formatBytes(_ bytes: UInt64) -> String {
        formatBytes(Int64(bytes))
    }

    // MARK: - Private

    private static func sha256Hex(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Free Fire detection (mirrors com.novax.app.utils.Constants)

struct GameDetect {
    static let ffPackage   = "com.dts.freefireth"
    static let ffMaxPackage = "com.dts.freefiremax"

    static var detectedGame: String? {
        if canOpen("freefiremax://") { return ffMaxPackage }
        if canOpen("freefire://") { return ffPackage }
        return nil
    }

    static var detectedName: String? {
        guard let pkg = detectedGame else { return nil }
        return pkg == ffMaxPackage ? "FF MAX" : "Free Fire"
    }

    static func launch() {
        let scheme: String
        if canOpen("freefiremax://") { scheme = "freefiremax://" }
        else if canOpen("freefire://") { scheme = "freefire://" }
        else { return }
        if let url = URL(string: scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private static func canOpen(_ scheme: String) -> Bool {
        guard let url = URL(string: scheme) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
