import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(selectedTab == tab ? FSColors.textPrimary : FSColors.textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(FSColors.bgPrimary)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(FSColors.bgCardBorder)
                .frame(height: 0.5)
        }
    }
}
