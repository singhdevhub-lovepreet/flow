import SwiftUI

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FSTypography.uiLabel)
            .foregroundStyle(FSColors.textMuted)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}
