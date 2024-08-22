import SwiftUI

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @StateObject private var forecastListViewModel = ForecastListViewModel()
    @State private var isFocused = true
    @State private var isViewLoaded = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isViewLoaded {
                    if searchViewModel.showSuggestions {
                        List {
                            ForEach(searchViewModel.suggestions, id: \.self) { suggestion in
                                Button(action: {
                                    searchViewModel.selectSuggestion(suggestion)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(suggestion.title)
                                        Text(suggestion.subtitle)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else if let error = forecastListViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                    } else {
                        ForecastList(viewModel: forecastListViewModel, selectedLocation: searchViewModel.selectedLocation)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Trouver et comparer des spots proches")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchViewModel.searchText,
                isPresented: $isFocused,
                prompt: "Paris, Almanarre, Montpellier..."
            )
            .toolbarBackground(.white, for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            // Delay to ensure the view is fully loaded
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isViewLoaded = true
        }
        .onChange(of: searchViewModel.selectedLocation.coordinate) { oldValue, newValue in
            if let coordinate = newValue {
                Task {
                    await forecastListViewModel.fetchSpotsAndCalculateDistances(coordinate: coordinate)
                }
            }
        }
    }
}
