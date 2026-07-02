import SwiftUI

struct NotchPillView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(FSColors.textMuted.opacity(0.5))
            .frame(width: 40, height: 5)
    }
}
