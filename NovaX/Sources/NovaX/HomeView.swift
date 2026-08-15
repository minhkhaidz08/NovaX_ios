import SwiftUI

// MARK: - Home / Dashboard (mirrors HomeScreen.kt)

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel

    @Environment(\.nova) private var nova

    var body: some View {
        ZStack {
            nova.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    NovaToolbar(title: "Dashboard")

                    LauncherCard(
                        username: viewModel.username.uppercased(),
                        userKey: viewModel.licenseKey,
                        expiry: viewModel.expiresLabel,
                        detectedGame: GameDetect.detectedGame,
                        onLaunch: {
                            Haptics.medium()
                            viewModel.launchGame()
                        }
                    )

                    SectionHeader(title: "AVAILABLE MODULES")

                    let all = viewModel.allFeatures
                    ForEach(Array(all.enumerated()), id: \.element.id) { index, feature in
                        FeatureRow(
                            feature: feature,
                            isUnlocked: viewModel.isFeatureUnlocked(feature),
                            index: index,
                            onToggle: { viewModel.toggleFeature(feature) }
                        )
                    }

                    UsageGuideCard()

                    Spacer().frame(height: 110)
                }
            }
        }
    }
}

// MARK: - Launcher Card (mirrors FreeFireLauncherCard)

private struct LauncherCard: View {
    let username: String
    let userKey: String
    let expiry: String
    let detectedGame: String?
    let onLaunch: () -> Void

    @Environment(\.nova) private var nova

    private var gameStatusText: String {
        if let detectedGame {
            return detectedGame == GameDetect.ffMaxPackage ? "FF MAX Detected" : "Free Fire Detected"
        }
        return "Game Not Found"
    }

    private var statusColor: Color {
        detectedGame != nil ? NovaTheme.statusGreen : NovaTheme.statusRed
    }

    var body: some View {
        NovaCard(cornerRadius: 20) {
            HStack(spacing: 16) {
                // Game icon / avatar
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NovaTheme.primaryPurple.opacity(0.05))
                    Text("FF")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(NovaTheme.primaryPurple)
                }
                .frame(width: 64, height: 64)

                // Center info
                VStack(alignment: .leading, spacing: 3) {
                    Text(username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(nova.textPrimary)

                    Text("Key: \(String(userKey.prefix(12)))...")
                        .font(.system(size: 11))
                        .foregroundColor(nova.textSecondary.opacity(0.7))

                    Text("Expires: \(expiry)")
                        .font(.system(size: 11))
                        .foregroundColor(nova.textSecondary.opacity(0.7))

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(gameStatusText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            NovaButton(
                text: detectedGame != nil ? "INJECT & LAUNCH" : "GAME NOT FOUND",
                onClick: onLaunch,
                enabled: detectedGame != nil,
                height: 48
            )
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Feature Row (mirrors FeatureItem)

private struct FeatureRow: View {
    let feature: AppViewModel.ModFeature
    let isUnlocked: Bool
    let index: Int
    let onToggle: () -> Void

    @State private var appeared = false
    @Environment(\.nova) private var nova

    private var isOn: Bool { feature.isEnabled && isUnlocked }

    var body: some View {
        NovaCard(cornerRadius: 14) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isOn ? NovaTheme.primaryPurple.opacity(0.1) : nova.surface)
                    Image(systemName: iconFor(feature.title))
                        .font(.system(size: 20))
                        .foregroundColor(isOn ? NovaTheme.primaryPurple : nova.textSecondary)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isOn ? NovaTheme.primaryPurple : nova.textPrimary)
                    Text(feature.description)
                        .font(.system(size: 12))
                        .foregroundColor(nova.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(nova.textSecondary.opacity(0.4))
                } else {
                    NovaSwitch(checked: Binding(
                        get: { feature.isEnabled },
                        set: { _ in onToggle() }
                    ))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(Double(index) * 0.05)) {
                appeared = true
            }
        }
    }

    private func iconFor(_ title: String) -> String {
        if title.contains("Aimlock", caseSensitive: false) { return "target" }
        if title.contains("Safe", caseSensitive: false) { return "checkmark.shield" }
        if title.contains("Body", caseSensitive: false) { return "figure.walk" }
        return "puzzlepiece"
    }
}

// MARK: - Usage Guide (mirrors UsageGuideCard)

private struct UsageGuideCard: View {
    @Environment(\.nova) private var nova

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HƯỚNG DẪN SỬ DỤNG")
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(nova.textPrimary.opacity(0.4))

            NovaCard(cornerRadius: 16, backgroundColor: nova.card.opacity(0.5)) {
                VStack(alignment: .leading, spacing: 10) {
                    guideStep(1, "Vào game -> vào 1 trận bất kì -> out ra xóa tab game")
                    guideStep(2, "Bật chức năng lên -> bấm nút Inject & Launch để mở game")
                    guideStep(3, "Trải nghiệm")
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guideStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(NovaTheme.primaryPurple.opacity(0.1))
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(NovaTheme.primaryPurple)
            }
            .frame(width: 20, height: 20)

            Text(text)
                .font(.system(size: 13))
                .lineSpacing(5)
                .foregroundColor(nova.textPrimary.opacity(0.8))
        }
    }
}
