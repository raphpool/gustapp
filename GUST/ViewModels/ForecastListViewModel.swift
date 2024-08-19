import Foundation
import Combine
import CoreLocation

extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
}

func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
    let R = 6371.0 // Radius of the Earth in kilometers
    let dLat = (lat2 - lat1).degreesToRadians
    let dLon = (lon2 - lon1).degreesToRadians
    let a = sin(dLat/2) * sin(dLat/2) +
    cos(lat1.degreesToRadians) * cos(lat2.degreesToRadians) *
    sin(dLon/2) * sin(dLon/2)
    let c = 2 * atan2(sqrt(a), sqrt(1-a))
    return R * c
}

class ForecastListViewModel: ObservableObject {
    @Published var spotFields = [KiteSpotFields]()
    @Published var displayedSpotFields = [KiteSpotFields]()
    @Published var forecasts: [String: [Record]] = [:]
    @Published var isLoadingForecasts = false
    @Published var isLoadingMore = false
    @Published var error: String?
    @Published var hasMoreSpots = false
    
    var forecastCache: [String: [Record]] = [:]
    
    private let spotFetcher = SpotFetcher()
    private let forecastFetcher = ForecastFetcher()
    private let loadMoreThreshold = 4
    private let numberOfSpotsToLoad = 4
    
    func fetchForecasts() async {
        print("ForecastListViewModel: fetchForecasts started")
        let startTime = Date()
        await MainActor.run { self.isLoadingForecasts = true }
        do {
            print("ForecastListViewModel: Fetching kite spots")
            let spotsFetchStartTime = Date()
            let allSpots = try await SpotFetcher().fetchKiteSpots()
            print("ForecastListViewModel: Kite spots fetched in \(Date().timeIntervalSince(spotsFetchStartTime)) seconds")
            let spotIds = allSpots.map { $0.spotId }
            print("ForecastListViewModel: Fetching forecast records for \(spotIds.count) spots")
            let recordsFetchStartTime = Date()
            let records = try await forecastFetcher.fetchAllRecords(spotIds: spotIds)
            print("ForecastListViewModel: Forecast records fetched in \(Date().timeIntervalSince(recordsFetchStartTime)) seconds")
            print("ForecastListViewModel: Total records fetched: \(records.count)")

            print("ForecastListViewModel: Grouping records")
            let groupingStartTime = Date()
            let groupedRecords = Dictionary(grouping: records, by: { $0.fields.spotId })
            print("ForecastListViewModel: Records grouped in \(Date().timeIntervalSince(groupingStartTime)) seconds")
            print("ForecastListViewModel: Number of spots with records: \(groupedRecords.count)")
            
            await MainActor.run {
                self.forecasts = groupedRecords
                self.isLoadingForecasts = false
            }
        } catch {
            print("Error fetching forecasts: \(error)")
            await MainActor.run { self.isLoadingForecasts = false }
        }
        print("ForecastListViewModel: fetchForecasts completed in \(Date().timeIntervalSince(startTime)) seconds")
    }
    
    
    func fetchSpotsAndCalculateDistances(coordinate: CLLocationCoordinate2D?) async {
        guard let searchCoordinates = coordinate else {
            await MainActor.run { self.resetFields() }
            return
        }
        
        await MainActor.run {
            self.isLoadingForecasts = true
            self.error = nil
        }
        
        do {
            let fetchedSpotFields = try await spotFetcher.fetchKiteSpots()
            
            guard !fetchedSpotFields.isEmpty else {
                await MainActor.run {
                    self.resetFields()
                    self.error = "No spots found"
                }
                return
            }
            
            let updatedSpotFields = await withTaskGroup(of: KiteSpotFields.self, returning: [KiteSpotFields].self) { group in
                for spotField in fetchedSpotFields {
                    group.addTask {
                        var mutableSpotField = spotField
                        mutableSpotField.distance = calculateDistance(
                            lat1: searchCoordinates.latitude,
                            lon1: searchCoordinates.longitude,
                            lat2: mutableSpotField.lat,
                            lon2: mutableSpotField.lon
                        )
                        return mutableSpotField
                    }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }
                .sorted { ($0.distance ?? Double.infinity) < ($1.distance ?? Double.infinity) }
            
            await fetchForecastsForDisplayedSpots(updatedSpotFields)
            
            await MainActor.run {
                self.spotFields = updatedSpotFields
                self.displayedSpotFields = Array(updatedSpotFields.prefix(self.numberOfSpotsToLoad))
                self.hasMoreSpots = updatedSpotFields.count > self.numberOfSpotsToLoad
                self.isLoadingForecasts = false
            }
        } catch {
            await MainActor.run {
                self.isLoadingForecasts = false
                self.error = "Error fetching spots: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchForecastsForDisplayedSpots(_ spots: [KiteSpotFields]) async {
        let displayedSpotIds = spots.prefix(numberOfSpotsToLoad).compactMap { $0.spotId }
        
        await withTaskGroup(of: (String, [Record]).self) { group in
            for spotId in displayedSpotIds {
                group.addTask {
                    do {
                        if let cachedRecords = self.forecastCache[spotId] {
                            return (spotId, cachedRecords)
                        } else {
                            let spotForecasts = try await self.forecastFetcher.fetchAllRecords(spotIds: [spotId])
                            return (spotId, spotForecasts)
                        }
                    } catch {
                        print("Error fetching forecast for spotId: \(spotId), error: \(error)")
                        return (spotId, [])
                    }
                }
            }
            
            for await (spotId, forecasts) in group {
                await MainActor.run {
                    self.forecasts[spotId] = forecasts
                    self.forecastCache[spotId] = forecasts
                }
            }
        }
    }
    
    func loadMoreSpots() async {
        guard !isLoadingMore, displayedSpotFields.count < spotFields.count else { return }
        
        await MainActor.run { self.isLoadingMore = true }
        
        let startIndex = displayedSpotFields.count
        let endIndex = min(startIndex + loadMoreThreshold, spotFields.count)
        let newSpots = Array(spotFields[startIndex..<endIndex])
        
        await fetchForecastsForDisplayedSpots(newSpots)
        
        await MainActor.run {
            self.displayedSpotFields.append(contentsOf: newSpots)
            self.hasMoreSpots = self.displayedSpotFields.count < self.spotFields.count
            self.isLoadingMore = false
        }
    }
    
    func resetFields() {
        spotFields = []
        displayedSpotFields = []
        forecasts = [:]
        forecastCache = [:]
        error = nil
        hasMoreSpots = false
    }
}
