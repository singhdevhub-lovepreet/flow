import SwiftUI

struct GhostTextView: View {
    let text: String
    var font: Font = FSTypography.displayFallbackXL
    var opacity: Double = 0.06

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(FSColors.textPrimary.opacity(opacity))
            .lineLimit(1)
    }
}
