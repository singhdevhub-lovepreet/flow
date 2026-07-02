import SwiftUI

struct GhostedTimerView: View {
    let time: String // e.g. "25:00"
    let ghostTime: String // e.g. "25:00" (the total/max time)

    var body: some View {
        ZStack {
            // Ghost (background) — the full time
            Text(ghostTime)
                .font(FSTypography.monoFallbackTimer)
                .foregroundStyle(FSColors.textPrimary.opacity(0.06))
                .monospacedDigit()

            // Actual time
            Text(time)
                .font(FSTypography.monoFallbackTimer)
                .foregroundStyle(FSColors.textPrimary)
                .monospacedDigit()
        }
    }
}
