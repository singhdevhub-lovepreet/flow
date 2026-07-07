import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(FSColors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(FSColors.bgCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }

    func screenPadding() -> some View {
        self.padding(.horizontal, FSSpacing.screenPadding)
    }
}
