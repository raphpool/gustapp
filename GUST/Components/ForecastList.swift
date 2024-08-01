import SwiftUI
import MapKit

struct ForecastList: View {
    @ObservedObject var viewModel: ForecastListViewModel
    @ObservedObject var selectedLocation: SelectedLocation
    @State private var selectedSpot: KiteSpotFields?
    
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
                                    .onTapGesture {
                                        print("Tapped on spot: \(spotField.spotName ?? "Unknown"), spotId: \(spotField.spotId)")
                                        selectedSpot = spotField
                                        print("Set selectedSpot to \(spotField.spotName ?? "Unknown")")
                                    }
                                
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
        .sheet(item: $selectedSpot) { spot in
            ZStack {
                Color.clear.onAppear {
                    print("Sheet presentation triggered for spot: \(spot.spotName ?? "Unknown")")
                }
                
                SpotDetailBottomSheet(kiteSpot: spot)
                    .onAppear {
                        print("SpotDetailBottomSheet appeared for spot: \(spot.spotName ?? "Unknown")")
                    }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
