import SwiftUI

struct CompletionRingView: View {
    let progress: Double // 0.0 - 1.0
    var size: CGFloat = 64
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(FSColors.bgCardBorder, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    FSColors.textPrimary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center percentage
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .semibold, design: .monospaced))
                .foregroundStyle(FSColors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}
