import SwiftUI

struct DotGridView: View {
    let columns = 14
    let rows = 5
    let data: [Double] // values 0.0 - 1.0, indexed by day

    var body: some View {
        let gridItems = Array(repeating: GridItem(.fixed(8), spacing: 3), count: columns)

        LazyVGrid(columns: gridItems, spacing: 3) {
            ForEach(0..<(rows * columns), id: \.self) { index in
                let value = index < data.count ? data[index] : 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(dotColor(for: value))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private func dotColor(for value: Double) -> Color {
        switch value {
        case 0: FSColors.dotL1
        case 0.01..<0.25: FSColors.dotL2
        case 0.25..<0.5: FSColors.dotL3
        case 0.5..<0.75: FSColors.dotL4
        default: FSColors.dotL5
        }
    }
}
