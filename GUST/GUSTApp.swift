import SwiftUI

@main
struct GUSTApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var forecastListViewModel = ForecastListViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    SplashScreenView()
                } else {
                    ContentView()
                        .environmentObject(forecastListViewModel)
                }
            }
            .environmentObject(appState)
            .onAppear {
                Task {
                    await loadInitialData()
                }
            }
        }
    }

    private func loadInitialData() async {
        // Fetch forecasts
        await forecastListViewModel.fetchForecasts()
        
        // Perform any other necessary initial data loading here
        
        // When all loading is complete, update the app state
        await MainActor.run {
            appState.isLoading = false
        }
    }
}
