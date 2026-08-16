import SwiftUI

// MARK: - Profile (mirrors ProfileScreen.kt)

struct ProfileView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var showLogoutDialog = false
    @Environment(\.nova) private var nova

    var body: some View {
        ZStack {
            nova.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    NovaToolbar(title: "Profile")

                    // Header
                    VStack(spacing: 12) {
                        Image.novaLogo()
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 84, height: 84)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(nova.border, lineWidth: 1))

                        Text(viewModel.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(nova.textPrimary)

                        Text(viewModel.displayType)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(NovaTheme.primaryPurple)
                    }
                    .padding(.top, 16)

                    Spacer().frame(height: 32)

                    SectionHeader(title: "ACCOUNT DETAILS")
                    NovaCard {
                        InfoRow(label: "License Key", value: maskKey(viewModel.licenseKey))
                        InfoRow(label: "Expires", value: viewModel.expiresLabel)
                        InfoRow(label: "Status", value: viewModel.authState == .verified ? "Active" : "Inactive")
                    }
                    .padding(.horizontal, 20)

                    SectionHeader(title: "SECURITY")
                    NovaCard {
                        InfoRow(label: "Hardware ID", value: maskHwid(viewModel.hwid))
                        InfoRow(label: "Region", value: "Global")
                    }
                    .padding(.horizontal, 20)

                    NovaButton(
                        text: "LOGOUT ACCOUNT",
                        onClick: {
                            Haptics.heavy()
                            showLogoutDialog = true
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
                if showLogoutDialog {
                    ConfirmDialog(
                        title: "Logout",
                        message: "Are you sure you want to exit your session?",
                        confirmText: "LOGOUT",
                        onConfirm: {
                            viewModel.logout()
                            showLogoutDialog = false
                        },
                        showCancel: true,
                        cancelText: "CANCEL",
                        onCancel: { showLogoutDialog = false }
                    )
                }
            }
        )
    }

    private func maskKey(_ key: String) -> String {
        if key.count > 16 { return "\(key.prefix(16))..." }
        return key
    }

    private func maskHwid(_ hwid: String) -> String {
        if hwid.count > 12 { return "\(hwid.prefix(12))..." }
        return hwid
    }
}
