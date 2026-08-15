import SwiftUI

// MARK: - Nova Card (mirrors GamingCard)

struct NovaCard<Content: View>: View {
    let borderColor: Color?
    let backgroundColor: Color?
    let cornerRadius: CGFloat
    let content: Content

    @Environment(\.nova) private var nova

    init(
        borderColor: Color? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(backgroundColor ?? nova.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? nova.border, lineWidth: 1)
            )
    }
}

// MARK: - Nova Button (mirrors GamingButton)

struct NovaButton: View {
    let text: String
    let onClick: () -> Void
    var enabled: Bool = true
    var height: CGFloat = 56

    @State private var isPressed = false
    @Environment(\.nova) private var nova

    var body: some View {
        Button(action: onClick) {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(enabled ? .white : nova.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    Group {
                        if enabled {
                            LinearGradient(colors: [NovaTheme.primaryPurple, NovaTheme.secondaryPurple],
                                           startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.gray.opacity(0.35)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                )
                .scaleEffect(isPressed && enabled ? 0.98 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PressScaleButtonStyle(isPressed: $isPressed))
        .disabled(!enabled)
    }
}

private struct PressScaleButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed = $0 }
    }
}

// MARK: - Nova TextField (mirrors GamingTextField)

struct NovaTextField: View {
    let value: Binding<String>
    let label: String
    var isPassword: Bool = false
    var isError: Bool = false
    var errorMessage: String?

    @State private var passwordVisible = false
    @State private var isFocused = false
    @Environment(\.nova) private var nova

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                ZStack(alignment: .leading) {
                    if value.wrappedValue.isEmpty {
                        Text(label)
                            .font(.system(size: 15))
                            .foregroundColor(nova.textSecondary.opacity(0.6))
                    }
                    Group {
                        if isPassword && !passwordVisible {
                            SecureField("", text: value)
                        } else {
                            TextField("", text: value)
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(nova.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                }

                if isPassword {
                    Button(action: { passwordVisible.toggle() }) {
                        Image(systemName: passwordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundColor(passwordVisible ? NovaTheme.primaryPurple : nova.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isFocused ? nova.surface : nova.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(strokeColor, lineWidth: (isFocused || isError) ? 1.5 : 1)
            )
            .onTapGesture { isFocused = true }

            if isError, let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundColor(NovaTheme.statusRed)
                    .padding(.leading, 8)
                    .padding(.top, 2)
            }
        }
    }

    private var strokeColor: Color {
        if isError { return NovaTheme.statusRed }
        if isFocused { return NovaTheme.primaryPurple }
        return nova.border
    }
}

// MARK: - Nova Switch (mirrors GamingSwitch)

struct NovaSwitch: View {
    let checked: Binding<Bool>
    var enabled: Bool = true

    var body: some View {
        Toggle("", isOn: checked)
            .labelsHidden()
            .tint(NovaTheme.primaryPurple)
            .scaleEffect(0.8)
            .disabled(!enabled)
    }
}

// MARK: - Nova Toolbar (mirrors GamingToolbar)

struct NovaToolbar: View {
    let title: String
    var showProfile: Bool = true

    @Environment(\.nova) private var nova

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.5)
                    .foregroundColor(nova.textPrimary)
                Capsule()
                    .fill(NovaTheme.primaryPurple)
                    .frame(width: 20, height: 3)
            }

            Spacer()

            if showProfile {
                Image("nova_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(nova.background)
    }
}

// MARK: - Nova Tab Bar (mirrors GamingBottomBar)

struct NovaTabBar: View {
    @Binding var selectedTab: Int
    let items: [(icon: String, label: String)]

    @Environment(\.nova) private var nova

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let isSelected = selectedTab == i
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                    Haptics.light()
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: isSelected ? "\(items[i].icon).fill" : items[i].icon)
                            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? NovaTheme.primaryPurple : nova.textSecondary.opacity(0.5))
                        if isSelected {
                            Circle()
                                .fill(NovaTheme.primaryPurple)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
            }
        }
        .padding(.horizontal, 8)
        .background(nova.card)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            LinearGradient(colors: [Color.clear, nova.background],
                           startPoint: .top, endPoint: .bottom)
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var icon: String? = nil

    @Environment(\.nova) private var nova

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(NovaTheme.primaryPurple)
            }
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundColor(nova.textPrimary.opacity(0.4))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    @Environment(\.nova) private var nova

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(nova.textSecondary.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(nova.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tier Badge

struct TierBadge: View {
    let tier: String
    let color: Color

    var body: some View {
        Text(tier.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(1)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Toast (mirrors ToastNotification in HomeScreen)

struct ToastView: View {
    let message: String?
    let isError: Bool

    @Environment(\.nova) private var nova

    var body: some View {
        if let message {
            HStack(spacing: 12) {
                Image(systemName: isError ? "exclamationmark.triangle.fill" : "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(isError ? NovaTheme.statusRed : NovaTheme.primaryPurple)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(nova.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(nova.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(nova.border, lineWidth: 1))
            .padding(.horizontal, 24)
            .padding(.bottom, 90)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Confirm Dialog (mirrors GamingDialog)

struct ConfirmDialog: View {
    let title: String
    let message: String
    let confirmText: String
    let onConfirm: () -> Void
    var showCancel: Bool = true
    var cancelText: String = "CANCEL"
    var onCancel: () -> Void = {}

    @Environment(\.nova) private var nova

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture {
                    if showCancel { onCancel() }
                }

            NovaCard(cornerRadius: 24) {
                VStack(spacing: 16) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(NovaTheme.primaryPurple)

                    Text(message)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .foregroundColor(nova.textSecondary)

                    HStack(spacing: 12) {
                        if showCancel {
                            Button(action: {
                                onCancel()
                            }) {
                                Text(cancelText)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(nova.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(nova.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        NovaButton(text: confirmText, onClick: {
                            onConfirm()
                        }, height: 48)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Loading (mirrors GamingLoading)

struct NovaLoading: View {
    let text: String

    @State private var rotation: Double = 0
    @State private var pulse: Double = 0.5
    @Environment(\.nova) private var nova

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    let angle = rotation + Double(i) * 30
                    let rad = angle * .pi / 180
                    let r: CGFloat = 28
                    let size = (3.0 + pulse * 2.0) * (1.0 - Double(i) / 12.0)
                    let alpha = 1.0 - Double(i) / 12.0

                    Circle()
                        .fill(NovaTheme.primaryPurple.opacity(alpha * pulse))
                        .frame(width: size, height: size)
                        .offset(x: r * cos(rad), y: r * sin(rad))
                }
                Circle()
                    .stroke(
                        AngularGradient(colors: [NovaTheme.primaryPurple.opacity(0.1), .clear],
                                        center: .center),
                        lineWidth: 1
                    )
                    .frame(width: 64, height: 64)

                Image("nova_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(nova.textSecondary)
                .padding(.top, 14)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}
