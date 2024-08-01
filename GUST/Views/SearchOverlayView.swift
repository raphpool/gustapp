import SwiftUI

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @StateObject private var forecastListViewModel = ForecastListViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchViewModel.searchText, placeholder: "Search for an address")
                    .padding()
                    .background(Color.white)
                    .zIndex(2)
                
                // Suggestions list
                if searchViewModel.showSuggestions {
                    List(searchViewModel.suggestions, id: \.self) { suggestion in
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
                    .listStyle(PlainListStyle())
                }
                
                // Error message or Forecast list
                if let error = forecastListViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ForecastList(viewModel: forecastListViewModel, selectedLocation: searchViewModel.selectedLocation)
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
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
