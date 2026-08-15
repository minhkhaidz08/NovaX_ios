import SwiftUI

// MARK: - System Info / Memory (mirrors MemoryScreen.kt)

struct MemoryView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var refreshTick = 0
    @Environment(\.nova) private var nova

    // Android MemoryViewModel refreshes device info every 5s
    private let refreshTimer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var ramTotal: Double { Double(DeviceUtils.totalRAM) }
    private var ramAvail: Double { Double(DeviceUtils.availableRAM) }
    private var ramUsed: Double { max(ramTotal - ramAvail, 0) }

    private var storageTotal: Int64 { DeviceUtils.storageTotal }
    private var storageFree: Int64 { DeviceUtils.storageFree }
    private var storageUsed: Int64 { max(storageTotal - storageFree, 0) }

    var body: some View {
        let _ = refreshTick   // tick triggers re-evaluation -> recompute device values
        ZStack {
            nova.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    NovaToolbar(title: "System Info")

                    SectionHeader(title: "SYSTEM OVERVIEW")

                    // Overview cards: RAM / Disk / Batt
                    HStack(spacing: 10) {
                        StatusCardMini(
                            label: "RAM",
                            value: "\(Int(ramUsagePercent))%"
                        )
                        StatusCardMini(
                            label: "Disk",
                            value: "\(Int(diskUsagePercent))%"
                        )
                        StatusCardMini(
                            label: "Batt",
                            value: "\(DeviceUtils.batteryPercent)%"
                        )
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "DEVICE DETAILS")
                    NovaCard {
                        InfoRow(label: "Manufacturer", value: DeviceUtils.manufacturer)
                        InfoRow(label: "Model", value: DeviceUtils.deviceModel)
                        InfoRow(label: "iOS", value: DeviceUtils.osVersion)
                        InfoRow(label: "Screen", value: DeviceUtils.screenResolution)
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "HARDWARE")
                    NovaCard {
                        InfoRow(label: "CPU", value: DeviceUtils.chipName)
                        InfoRow(label: "Cores", value: "\(DeviceUtils.cpuCores)")
                        InfoRow(label: "GPU", value: DeviceUtils.gpuName)
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "STORAGE & RAM")
                    NovaCard {
                        InfoRow(label: "Total RAM", value: DeviceUtils.formatBytes(DeviceUtils.totalRAM))
                        InfoRow(label: "Available RAM", value: DeviceUtils.formatBytes(DeviceUtils.availableRAM))
                        InfoRow(label: "Total Storage", value: DeviceUtils.formatBytes(storageTotal))
                        InfoRow(label: "Used Storage", value: DeviceUtils.formatBytes(storageUsed))
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 110)
                }
            }
        }
        .onReceive(refreshTimer) { _ in
            refreshTick += 1
        }
    }

    private var ramUsagePercent: Double {
        guard ramTotal > 0 else { return 0 }
        return (ramUsed / ramTotal) * 100
    }

    private var diskUsagePercent: Double {
        guard storageTotal > 0 else { return 0 }
        return (Double(storageUsed) / Double(storageTotal)) * 100
    }
}

// MARK: - Mini status card (mirrors StatusCardMini)

private struct StatusCardMini: View {
    let label: String
    let value: String

    @Environment(\.nova) private var nova

    var body: some View {
        NovaCard(cornerRadius: 12) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(nova.textSecondary.opacity(0.6))
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(NovaTheme.primaryPurple)
            }
        }
    }
}
