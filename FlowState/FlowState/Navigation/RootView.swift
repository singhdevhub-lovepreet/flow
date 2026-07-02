import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        VStack(spacing: 0) {
            // Notch pill indicator
            NotchPillView()
                .padding(.top, 8)

            // Screen content with cross-fade
            ZStack {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                        .transition(.opacity)
                case .todos:
                    TodosView()
                        .transition(.opacity)
                case .habits:
                    HabitsView()
                        .transition(.opacity)
                case .flow:
                    FlowModeView()
                        .transition(.opacity)
                case .pomodoro:
                    PomodoroView()
                        .transition(.opacity)
                case .insights:
                    InsightsView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            // Bottom tab bar
            TabBar(selectedTab: $selectedTab)
        }
        .frame(width: 440, height: 540)
        .background(FSColors.bgPrimary)
        .onReceive(NotificationCenter.default.publisher(for: .quickAddRequested)) { _ in
            selectedTab = .todos
        }
    }
}
