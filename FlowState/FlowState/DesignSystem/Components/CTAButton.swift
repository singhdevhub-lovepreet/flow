import SwiftUI

struct CTAButton: View {
    let title: String
    let action: () -> Void
    var isPrimary: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isPrimary ? FSColors.bgPrimary : FSColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isPrimary ? FSColors.textPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    if !isPrimary {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FSColors.bgCardBorder, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
