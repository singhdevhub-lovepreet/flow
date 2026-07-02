import SwiftUI

struct BreathingCircleView: View {
    var rate: Double = 6.0 // seconds per cycle
    var isAnimating: Bool = true

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0.6
    @State private var dotScale: CGFloat = 1.0
    @State private var dotOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(scale)
                .opacity(opacity)

            // Main circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)

            // Inner ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(width: 60, height: 60)
                .scaleEffect(scale)

            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .scaleEffect(dotScale)
                .opacity(dotOpacity)
        }
        .onAppear {
            if isAnimating { startBreathing() }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue { startBreathing() }
        }
        .onChange(of: rate) { _, _ in
            if isAnimating { startBreathing() }
        }
    }

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: rate)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.15
            opacity = 1.0
            dotScale = 1.5
            dotOpacity = 1.0
        }
    }
}
