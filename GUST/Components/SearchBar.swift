import SwiftUI
import MapKit

import CoreLocation


struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
    }
}

struct ForecastList: View {
    @ObservedObject var viewModel: ForecastListViewModel
    @ObservedObject var selectedLocation: SelectedLocation
    
    var body: some View {
        ScrollView {
            LazyVStack {
                if viewModel.isLoadingForecasts {
                    SpinningImage()
                } else {
                    ForEach(viewModel.displayedSpotFields, id: \.spotId) { spotField in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(spotField.spotName ?? "Unknown Spot")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: "%.2f km", spotField.distance ?? 0))
                                    .font(.system(size: 14, weight: .medium, design: .default))
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 8)
                            ForecastTable(
                                records: viewModel.forecasts[spotField.spotId] ?? [],
                                bestWindDirection: spotField.bestWindDirection ?? [],
                                lowTide: spotField.lowTide ?? "",
                                midTide: spotField.midTide ?? "",
                                highTide: spotField.highTide ?? ""
                            )
                        }
                        .padding(.vertical, 20)
                    }
                    if viewModel.hasMoreSpots {
                        loadMoreButton
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadMoreButton: some View {
        if viewModel.isLoadingMore {
            SpinningImage()
        } else {
            Button("Afficher plus") {
                Task {
                    await viewModel.loadMoreSpots()
                }
            }
            .padding(.vertical, 8)
        }
    }
}
