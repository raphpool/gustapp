import Foundation

struct RecordFields: Codable {
    let spotName: String
    let timestamp: String
    let windSpeed: Double
    let windGust: Double
    let windDegrees: Int
    let relativeDirection: String
    let tideDescription: String?
    let tideHeight: Double?
    let tidePracticable: String?
    let spotId: String
    let model: String
    let extremeHour: String?
    let extremeType: String?
}

struct Record: Codable {
    let fields: RecordFields
}

class ForecastFetcher {
    private let tableName = "Forecasts"
    private let airtableAPIKey = "pat3OmyPQeYWYbtan.0ac9c6603660aa5acc4b32f825c32bf4f6d55ed8ca0395cde4ad8a2a083e903a"
    private let airtableBaseID = "app3mlORKoXMPNhYn"
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func fetchAllRecords(spotIds: [String], concurrentFetches: Int = 5) async throws -> [Record] {
        let startTime = Date()
        print("ForecastFetcher: Starting to fetch records for \(spotIds.count) spots")
        
        let groups = spotIds.chunked(into: concurrentFetches)
        print("ForecastFetcher: Split into \(groups.count) groups")
        
        let results = try await withThrowingTaskGroup(of: [Record].self) { group in
            for (index, spotIdGroup) in groups.enumerated() {
                group.addTask {
                    print("ForecastFetcher: Starting fetch for group \(index + 1)/\(groups.count)")
                    let groupStartTime = Date()
                    let records = try await self.fetchRecordsForSpots(spotIds: spotIdGroup)
                    print("ForecastFetcher: Finished fetch for group \(index + 1)/\(groups.count) in \(Date().timeIntervalSince(groupStartTime)) seconds, fetched \(records.count) records")
                    return records
                }
            }
            
            var allRecords: [Record] = []
            for try await records in group {
                allRecords.append(contentsOf: records)
            }
            return allRecords
        }
        
        print("ForecastFetcher: Finished fetching all records in \(Date().timeIntervalSince(startTime)) seconds")
        print("ForecastFetcher: Total records fetched: \(results.count)")
        return results
    }
    
    private func fetchRecordsForSpots(spotIds: [String]) async throws -> [Record] {
        var allRecords: [Record] = []
        var offset: String?
        var pageCount = 0
        let fetchStartTime = Date()
        
        repeat {
            pageCount += 1
            let pageStartTime = Date()
            
            let formula = "OR(\(spotIds.map { "spotId='\($0)'" }.joined(separator: ",")))"
            let encodedFormula = formula.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let offsetParam = offset.map { "&offset=\($0)" } ?? ""
            let sortParam = "&sort%5B0%5D%5Bfield%5D=timestamp&sort%5B0%5D%5Bdirection%5D=asc"
            let endpoint = "https://api.airtable.com/v0/\(airtableBaseID)/\(tableName)?filterByFormula=\(encodedFormula)&pageSize=100\(offsetParam)\(sortParam)"
            
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(airtableAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("ForecastFetcher: Sending request for page \(pageCount) (Spots: \(spotIds.joined(separator: ", ")))")
            let requestStartTime = Date()
            let (data, response) = try await session.data(for: request)
            print("ForecastFetcher: Received response for page \(pageCount) in \(Date().timeIntervalSince(requestStartTime)) seconds")
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decodingStartTime = Date()
            let decodedResponse = try JSONDecoder().decode(AirtableResponse<Record>.self, from: data)
            print("ForecastFetcher: Decoded response for page \(pageCount) in \(Date().timeIntervalSince(decodingStartTime)) seconds")
            
            allRecords.append(contentsOf: decodedResponse.records)
            offset = decodedResponse.offset
            
            print("ForecastFetcher: Fetched \(decodedResponse.records.count) records in page \(pageCount)")
            print("ForecastFetcher: Total time for page \(pageCount): \(Date().timeIntervalSince(pageStartTime)) seconds")
            
        } while offset != nil
        
        print("ForecastFetcher: Fetched a total of \(allRecords.count) records for spots \(spotIds.joined(separator: ", ")) in \(pageCount) pages")
        print("ForecastFetcher: Total fetch time for these spots: \(Date().timeIntervalSince(fetchStartTime)) seconds")
        
        return allRecords
    }
}



extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
