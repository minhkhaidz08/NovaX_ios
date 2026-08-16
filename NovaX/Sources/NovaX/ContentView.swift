import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        ZStack {
            switch viewModel.authState {
            case .splash:
                SplashView(viewModel: viewModel)
            case .verified:
                MainContainer(viewModel: viewModel)
            default:
                LoginView(viewModel: viewModel)
            }
        }
        .environment(\.nova, NovaPalette.current(viewModel.settings.themeDark))
        .preferredColorScheme(viewModel.settings.themeDark ? .dark : .light)
        .overlay(
            VStack {
                Spacer()
                ToastView(message: viewModel.toastMessage, isError: viewModel.toastIsError)
            }
            .animation(.spring(response: 0.3), value: viewModel.toastMessage)
            .allowsHitTesting(false)
        )
        .onAppear {
            Task { await viewModel.performSplashFlow() }
        }
    }
}
