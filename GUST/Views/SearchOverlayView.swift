import SwiftUI

struct SearchOverlayView: View {
    @Binding var isPresented: Bool
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @StateObject private var forecastListViewModel = ForecastListViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Dismiss handle
            Rectangle()
                .fill(Color.gray)
                .frame(width: 40, height: 5)
                .cornerRadius(3)
                .padding(.top, 10)
            
            // Search bar
            SearchBar(text: $searchViewModel.searchText, placeholder: "Search for an address")
                .padding()
                .background(Color.white)
                .zIndex(2)
            
            // Suggestions list
            if searchViewModel.showSuggestions {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
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
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .zIndex(1)
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
        .background(Color.white)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 50 {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
        )
        .onChange(of: searchViewModel.selectedLocation.coordinate) { oldValue, newValue in
            if let coordinate = newValue {
                Task {
                    await forecastListViewModel.fetchSpotsAndCalculateDistances(coordinate: coordinate)
                }
            }
        }
    }
}
