import SwiftUI

// MARK: - Main Container (mirrors MainScreen.kt)

struct MainContainer: View {
    @ObservedObject var viewModel: AppViewModel

    @Environment(\.nova) private var nova

    var body: some View {
        ZStack(alignment: .bottom) {
            nova.background.ignoresSafeArea()

            // Content
            ZStack {
                switch viewModel.selectedTab {
                case 0:
                    HomeView(viewModel: viewModel)
                case 1:
                    MemoryView(viewModel: viewModel)
                case 2:
                    ProfileView(viewModel: viewModel)
                default:
                    SettingsView(viewModel: viewModel)
                }
            }
            .transition(.opacity)

            // Bottom tab bar (mirrors GamingBottomBar)
            NovaTabBar(
                selectedTab: $viewModel.selectedTab,
                items: [
                    (icon: "house",        label: "Home"),
                    (icon: "memorychip",   label: "Memory"),
                    (icon: "person",       label: "Profile"),
                    (icon: "gearshape",    label: "Settings"),
                ]
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}
