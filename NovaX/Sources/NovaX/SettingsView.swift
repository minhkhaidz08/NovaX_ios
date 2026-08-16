import SwiftUI

// MARK: - Settings (mirrors SettingsScreen.kt)

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var showResetDialog = false
    @Environment(\.nova) private var nova

    private let appVersion = "1.0.0"

    var body: some View {
        ZStack {
            nova.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    NovaToolbar(title: "Settings")

                    Spacer().frame(height: 8)

                    SectionHeader(title: "APPEARANCE")
                    NovaCard {
                        SettingsToggleItem(
                            label: "Animations",
                            description: "Enable UI transitions",
                            checked: viewModel.settings.animationsEnabled,
                            onCheckedChange: { viewModel.setAnimationsEnabled($0) }
                        )
                        Divider().background(nova.border.opacity(0.5)).padding(.vertical, 12)
                        SettingsSelectItem(
                            label: "Theme Mode",
                            value: viewModel.settings.themeDark ? "Dark" : "Light",
                            onClick: {
                                Haptics.light()
                                viewModel.setThemeDark(!viewModel.settings.themeDark)
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "SYSTEM")
                    NovaCard {
                        SettingsToggleItem(
                            label: "Notifications",
                            description: "Push alerts",
                            checked: viewModel.settings.notificationsEnabled,
                            onCheckedChange: { viewModel.setNotificationsEnabled($0) }
                        )
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "ABOUT")
                    NovaCard {
                        InfoRow(label: "Version", value: appVersion)
                            .padding(.bottom, 12)
                        InfoRow(label: "Developer", value: "NovaX Team")
                    }
                    .padding(.horizontal, 20)

                    NovaButton(
                        text: "RESET ALL SETTINGS",
                        onClick: {
                            Haptics.medium()
                            showResetDialog = true
                        },
                        height: 52
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    Spacer().frame(height: 110)
                }
            }
        }
        .overlay(
            Group {
                if showResetDialog {
                    ConfirmDialog(
                        title: "Reset Settings",
                        message: "This will restore all preferences to default. Proceed?",
                        confirmText: "RESET",
                        onConfirm: {
                            viewModel.resetPreferences()
                            showResetDialog = false
                        },
                        showCancel: true,
                        cancelText: "CANCEL",
                        onCancel: { showResetDialog = false }
                    )
                }
            }
        )
    }
}

// MARK: - Toggle item (mirrors SettingsToggleItem)

private struct SettingsToggleItem: View {
    let label: String
    let description: String
    let checked: Bool
    let onCheckedChange: (Bool) -> Void

    @Environment(\.nova) private var nova

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(nova.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(nova.textSecondary.opacity(0.6))
            }
            Spacer()
            NovaSwitch(checked: Binding(
                get: { checked },
                set: { onCheckedChange($0) }
            ))
        }
    }
}

// MARK: - Select item (mirrors SettingsSelectItem)

private struct SettingsSelectItem: View {
    let label: String
    let value: String
    let onClick: () -> Void

    @Environment(\.nova) private var nova

    var body: some View {
        Button(action: onClick) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(nova.textPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(NovaTheme.primaryPurple)
            }
        }
    }
}
