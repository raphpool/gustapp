import Foundation

struct AirtableResponse<T: Codable>: Codable {
    let records: [T]
    let offset: String?
}

struct KiteSpotFields: Codable, Hashable {
    let spotName: String?
    let spotDirection: String?
    let lowTide: String?
    let highTide: String?
    let midTide: String?
    let lowTideDescription: String?
    let highTideDescription: String?
    let midTideDescription: String?
    let lat: Double
    let lon: Double
    let about: String?
    let spotDescription: String?
    let about2: String?
    let spotId: String
    let bestWindDirection: [String]?
    let bestWindDescription: String?
    let forecastStatus: String?
    let hasTides: String?
    let fullAddress: String?
    let bestWindDescription2: String?
    let tideDescription2: String?
    let contentStatus: String?
    let spotDescription2: String?
    let tideDescription1: String?
    var distance: Double?
    func hash(into hasher: inout Hasher) {
        hasher.combine(spotName)
        hasher.combine(lat)
        hasher.combine(lon)
    }
    
    static func == (lhs: KiteSpotFields, rhs: KiteSpotFields) -> Bool {
        return lhs.spotName == rhs.spotName && lhs.lat == rhs.lat && lhs.lon == rhs.lon
    }
}


struct KiteSpotRecord: Codable {
    let id: String
    let fields: KiteSpotFields
}

class SpotFetcher {
    private let apiKey = "pat3OmyPQeYWYbtan.0ac9c6603660aa5acc4b32f825c32bf4f6d55ed8ca0395cde4ad8a2a083e903a"
    private let baseId = "app3mlORKoXMPNhYn"
    private let tableName = "SpotCharacteristics"
    
    func fetchKiteSpots() async throws -> [KiteSpotFields] {
        var allSpots: [KiteSpotFields] = []
        var offset: String?
        
        while true {
            let offsetParam = offset != nil ? "&offset=\(offset!)" : ""
            let endpoint = "https://api.airtable.com/v0/\(baseId)/\(tableName)?\(offsetParam)"
            
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let decodedResponse = try JSONDecoder().decode(AirtableResponse<KiteSpotRecord>.self, from: data)
            allSpots.append(contentsOf: decodedResponse.records.map { $0.fields })
            
            if let newOffset = decodedResponse.offset {
                offset = newOffset
            } else {
                break
            }
        }
        
        return allSpots
    }
}
