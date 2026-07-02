import SwiftUI

struct BarChartView: View {
    let data: [(label: String, value: Double)] // 0.0 - 1.0 normalized
    var highlightIndex: Int? = nil
    var barHeight: CGFloat = 70

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            index == highlightIndex
                                ? FSColors.textPrimary
                                : FSColors.textMuted.opacity(0.4)
                        )
                        .frame(height: max(4, barHeight * item.value))
                        .frame(maxWidth: .infinity)

                    Text(item.label)
                        .font(.system(size: 9))
                        .foregroundStyle(FSColors.textMuted)
                }
            }
        }
        .frame(height: barHeight + 16)
    }
}
