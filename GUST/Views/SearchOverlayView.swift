import SwiftUI

struct SearchOverlayView: View {
    @Binding var shouldAutoFocus: Bool
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @StateObject private var forecastListViewModel = ForecastListViewModel()
    @State private var isFocused: Bool
    @State private var isViewLoaded = false
    @State private var isSpotPagePresented = false
    
    init(shouldAutoFocus: Binding<Bool>) {
        self._shouldAutoFocus = shouldAutoFocus
        self._isFocused = State(initialValue: shouldAutoFocus.wrappedValue)
    }
    
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
                        ForecastList(viewModel: forecastListViewModel,
                                     selectedLocation: searchViewModel.selectedLocation,
                                     isSpotPagePresented: $isSpotPagePresented)
                    }
                } else {
                    ProgressView()
                }
            }
            .searchable(
                text: $searchViewModel.searchText,
                isPresented: Binding(
                    get: { self.isFocused },
                    set: { newValue in
                        self.isFocused = newValue
                        if !newValue {
                            self.shouldAutoFocus = false
                        }
                    }
                ),
                prompt: "Paris, Almanarre, Montpellier..."
            )
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("Trouver et comparer des spots proches")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if shouldAutoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isFocused = true
                }
            }
        }
        .onChange(of: isSpotPagePresented) { oldValue, newValue in
            if newValue {
                isFocused = false
            }
        }
        .onDisappear {
            shouldAutoFocus = false
            isFocused = false
        }
        .task {
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
