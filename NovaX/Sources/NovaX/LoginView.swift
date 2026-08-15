import SwiftUI

// MARK: - Login (mirrors LoginScreen.kt)

struct LoginView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var showKey = false
    @Environment(\.nova) private var nova

    var body: some View {
        ZStack {
            nova.background.ignoresSafeArea()

            // Soft ambient glow (mirrors top radial glow)
            Circle()
                .fill(RadialGradient(colors: [NovaTheme.primaryPurple.opacity(0.08), .clear],
                                     center: .center, startRadius: 0, endRadius: 150))
                .frame(width: 300, height: 300)
                .offset(y: -250)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo
                    Image("nova_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(nova.border, lineWidth: 1))

                    Text("NovaX")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(-1)
                        .foregroundColor(nova.textPrimary)
                        .padding(.top, 24)

                    Text("Secure Premium Intelligence")
                        .font(.system(size: 14))
                        .foregroundColor(nova.textPrimary.opacity(0.6))
                        .padding(.top, 4)

                    // Authentication card
                    NovaCard(cornerRadius: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Authentication")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(nova.textPrimary)

                            Text("Enter your license key to activate")
                                .font(.system(size: 13))
                                .foregroundColor(nova.textSecondary.opacity(0.6))
                                .padding(.top, 4)
                                .padding(.bottom, 20)

                            HStack {
                                if showKey {
                                    TextField("License Key", text: $viewModel.licenseKey)
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(nova.textPrimary)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("License Key", text: $viewModel.licenseKey)
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(nova.textPrimary)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                Button(action: { showKey.toggle() }) {
                                    Image(systemName: showKey ? "eye.slash" : "eye")
                                        .font(.system(size: 15))
                                        .foregroundColor(nova.textSecondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(nova.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isError ? NovaTheme.statusRed : nova.border, lineWidth: 1)
                            )
                            .onChange(of: viewModel.licenseKey) { _ in
                                if isError { viewModel.clearLoginError() }
                            }

                            if isError {
                                Text(errorText)
                                    .font(.system(size: 12))
                                    .foregroundColor(NovaTheme.statusRed)
                                    .padding(.leading, 8)
                                    .padding(.top, 8)
                            }

                            if isLoading {
                                NovaLoading(text: loadingText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 16)
                            } else {
                                NovaButton(
                                    text: "LOGIN",
                                    onClick: {
                                        Haptics.medium()
                                        Task { await viewModel.login() }
                                    },
                                    enabled: !viewModel.licenseKey.trimmingCharacters(in: .whitespaces).isEmpty
                                )
                                .padding(.top, 24)
                            }

                            Button(action: {
                                openURL("https://zalo.me/g/i1bffsvvb6wijb3l0gc8")
                            }) {
                                Text("Contact Support")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(NovaTheme.primaryPurple)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(.top, 48)

                    Spacer().frame(height: 48)

                    // Footer links
                    HStack(spacing: 12) {
                        footerLink("Community", "https://zalo.me/g/i1bffsvvb6wijb3l0gc8")
                        footerLink("Administrator", "https://zalo.me/0342145707")
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 80)
            }
        }
    }

    private var isError: Bool {
        if case .error = viewModel.authState { return true }
        return false
    }

    private var errorText: String {
        if case .error(let msg) = viewModel.authState { return msg }
        return ""
    }

    private var isLoading: Bool {
        if case .loading = viewModel.authState { return true }
        return false
    }

    private var loadingText: String {
        if case .loading(let text) = viewModel.authState { return text }
        return "Authenticating..."
    }

    private func footerLink(_ text: String, _ url: String) -> some View {
        Button(action: { openURL(url) }) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(nova.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(nova.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func openURL(_ url: String) {
        guard let u = URL(string: url) else { return }
        UIApplication.shared.open(u, options: [:], completionHandler: nil)
    }
}
