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
    
    func fetchAllRecords(spotIds: [String]) async throws -> [Record] {
        var allRecords: [Record] = []
        var offset: String?
        
        while true {
            let formula = "OR(\(spotIds.map { "spotId='\($0)'" }.joined(separator: ",")))"
            let encodedFormula = formula.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let offsetParam = offset != nil ? "&offset=\(offset!)" : ""
            let endpoint = "https://api.airtable.com/v0/\(airtableBaseID)/\(tableName)?filterByFormula=\(encodedFormula)\(offsetParam)"
            
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(airtableAPIKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let decodedResponse = try JSONDecoder().decode(AirtableResponse<Record>.self, from: data)
                allRecords.append(contentsOf: decodedResponse.records)
                
                if let newOffset = decodedResponse.offset {
                    offset = newOffset
                } else {
                    break
                }
            } else {
                let body = String(data: data, encoding: .utf8)
                print("Server returned status code \((response as? HTTPURLResponse)?.statusCode ?? 0): \(body ?? "No response body")")
                throw URLError(.badServerResponse)
            }
        }
        
        // Here we sort the records before returning them.
        return sortRecords(allRecords)
    }
    
    private func sortRecords(_ records: [Record]) -> [Record] {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return records.sorted {
                guard let date0 = dateFormatter.date(from: $0.fields.timestamp),
                      let date1 = dateFormatter.date(from: $1.fields.timestamp) else {
                    print("Error parsing one of the timestamps: \($0.fields.timestamp) or \($1.fields.timestamp)")
                    return false
                }
                return date0 < date1
            }
        }
    }
