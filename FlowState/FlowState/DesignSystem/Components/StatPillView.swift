import SwiftUI

struct StatPillView: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(FSColors.textPrimary)
            Text(label)
                .font(FSTypography.uiLabel)
                .foregroundStyle(FSColors.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FSColors.bgCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(FSColors.bgCardBorder, lineWidth: 1)
        )
    }
}
