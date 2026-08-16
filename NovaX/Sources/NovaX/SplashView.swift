import SwiftUI

// MARK: - Splash (mirrors SplashScreen.kt)

struct SplashView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var progress: CGFloat = 0
    @State private var glowAlpha: Double = 0.3
    @State private var showLoading = false

    @Environment(\.nova) private var nova

    var body: some View {
        ZStack {
            nova.background.ignoresSafeArea()

            ParticleBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo with glow ring
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [NovaTheme.primaryPurple.opacity(0.15 * glowAlpha), .clear],
                                center: .center, startRadius: 0, endRadius: 90
                            )
                        )
                        .frame(width: 140, height: 140)

                    Circle()
                        .stroke(NovaTheme.primaryPurple.opacity(0.1), lineWidth: 1)
                        .frame(width: 120, height: 120)

                    Image("nova_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                }
                .frame(width: 160, height: 160)

                Text("NovaX")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(2)
                    .foregroundColor(nova.textPrimary)
                    .padding(.top, 32)

                Text("PREMIUM INTELLIGENCE")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(3)
                    .foregroundColor(nova.textPrimary.opacity(0.4))
                    .padding(.top, 4)

                if showLoading {
                    Text("Securing Session...")
                        .font(.system(size: 12))
                        .tracking(1)
                        .foregroundColor(nova.textPrimary.opacity(0.6))
                        .padding(.top, 64)

                    // Progress bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(nova.border.opacity(0.1))
                            .frame(width: 180, height: 3)
                        Capsule()
                            .fill(
                                LinearGradient(colors: [NovaTheme.primaryPurple, NovaTheme.secondaryPurple],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: 180 * progress, height: 3)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .onAppear {
            showLoading = true
            withAnimation(.linear(duration: 2.5)) {
                progress = 1
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowAlpha = 1
            }
        }
    }
}

// MARK: - Particle background (mirrors NovaXParticleBackground)

struct ParticleBackground: View {
    @State private var particles: [ParticleState] = ParticleState.make(40)
    @State private var time: Double = 0

    struct ParticleState {
        var x: Double
        var y: Double
        var speed: Double
        var size: Double
        var alpha: Double
        var phase: Double

        static func make(_ count: Int) -> [ParticleState] {
            (0..<count).map { _ in
                ParticleState(
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...1),
                    speed: Double.random(in: 0.001...0.004),
                    size: Double.random(in: 1.5...4),
                    alpha: Double.random(in: 0.2...0.6),
                    phase: Double.random(in: 0...(2 * .pi))
                )
            }
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                for p in particles {
                    // Deterministic drift from time (no state mutation during render)
                    let dx = sin(t * p.speed + p.phase)
                    let dy = cos(t * p.speed * 0.7 + p.phase)
                    var x = p.x + dx * 0.02
                    var y = p.y + dy * 0.02
                    x = x.truncatingRemainder(dividingBy: 1)
                    if x < 0 { x += 1 }
                    y = y.truncatingRemainder(dividingBy: 1)
                    if y < 0 { y += 1 }

                    let pulse = (sin(t * 0.005 + p.phase) + 1) * 0.5
                    let currentAlpha = p.alpha * (0.5 + pulse * 0.5)

                    let center = CGPoint(x: w * CGFloat(x), y: h * CGFloat(y))

                    ctx.fill(
                        Path(ellipseIn: glowRect(center: center, size: p.size)),
                        with: .color(NovaTheme.primaryPurple.opacity(currentAlpha * 0.15))
                    )
                    ctx.fill(
                        Path(ellipseIn: particleRect(center: center, size: p.size)),
                        with: .color(NovaTheme.primaryPurple.opacity(currentAlpha))
                    )
                }
            }
        }
    }

    private func glowRect(center: CGPoint, size: Double) -> CGRect {
        let s = CGFloat(size)
        return CGRect(x: center.x - s * 3, y: center.y - s * 3,
                      width: s * 6, height: s * 6)
    }

    private func particleRect(center: CGPoint, size: Double) -> CGRect {
        let s = CGFloat(size)
        return CGRect(x: center.x - s / 2, y: center.y - s / 2,
                      width: s, height: s)
    }
}
