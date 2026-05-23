import SwiftUI

enum MainTab: Hashable {
    case home
    case activity
    case settings
}

struct MainTabView: View {
    @Binding var selectedTab: MainTab

    let homeContent: AnyView
    let activityContent: AnyView
    let settingsContent: AnyView

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:
                    homeContent
                case .activity:
                    activityContent
                case .settings:
                    settingsContent
                }
            }

            // Custom tab bar
            tabBar
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill", label: "Home", tab: .home)
            tabItem(icon: "chart.bar.fill", label: "Activity", tab: .activity)
            tabItem(icon: "gearshape.fill", label: "Settings", tab: .settings)
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color(hex: "111118")
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)
                }
        )
    }

    private func tabItem(icon: String, label: String, tab: MainTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        selectedTab == tab
                            ? Color(hex: "A78BFA")
                            : Color.white.opacity(0.35)
                    )

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        selectedTab == tab
                            ? Color(hex: "A78BFA")
                            : Color.white.opacity(0.35)
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
