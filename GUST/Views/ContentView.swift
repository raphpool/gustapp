import SwiftUI
import AWSS3

struct ContentView: View {
    @State private var pngFiles: [PNGFile] = []
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTilesetId: String? = nil
    @State private var isSearchSheetPresented = false
    @State private var currentTimestamp: Date? = nil
    @StateObject private var forecastListViewModel = ForecastListViewModel()

    
    var body: some View {
        ZStack(alignment: .bottom) {
            CustomMapViewControllerRepresentable(
                            selectedImage: selectedImage,
                            tilesetId: selectedTilesetId,
                            currentTimestamp: currentTimestamp,
                            forecastRecords: forecastListViewModel.forecasts
                        )                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Button(action: {
                    isSearchSheetPresented = true
                }) {
                    Text("Search")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 8)
                
                PNGFilesScrollView(pngFiles: pngFiles) { pngFile in
                    Task {
                        await fetchImage(bucket: "gustlayers", key: pngFile.fullName)
                        
                        let tilesetId = pngFile.fullName
                            .replacingOccurrences(of: "processed/", with: "")
                            .replacingOccurrences(of: ".png", with: "")
                            .replacingOccurrences(of: "-", with: "_")
                            .replacingOccurrences(of: "T", with: "_") + "_Paris_Time"
                        
                        self.selectedTilesetId = tilesetId
                        self.currentTimestamp = extractTimestamp(from: pngFile.fullName)
                        if let timestamp = self.currentTimestamp {
                                    print("Current timestamp set to: \(timestamp)")
                                } else {
                                    print("Failed to extract timestamp from: \(pngFile.fullName)")
                                }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $isSearchSheetPresented) {
            SearchOverlayView(isPresented: $isSearchSheetPresented)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            Task {
                do {
                    let pngFiles = try await listPNGFilesInProcessedFolder(bucket: "gustlayers", folder: "processed/")
                    self.pngFiles = pngFiles.map { PNGFile(fullName: $0) }
                } catch {
                    print("Failed to fetch files: \(error)")
                }
            }
            Task {
                            await forecastListViewModel.fetchForecasts()
                        }
        }
    }
    
    func fetchImage(bucket: String, key: String) async {
        do {
            let s3 = try await S3Client()
            let input = GetObjectInput(bucket: bucket, key: key)
            let output = try await s3.getObject(input: input)
            
            guard let body = output.body,
                  let data = try await body.readData() else {
                print("No data found")
                return
            }
            
            if let uiImage = UIImage(data: data) {
                self.selectedImage = uiImage
            }
        } catch {
            print("Failed to fetch image: \(error)")
        }
    }
    func extractTimestamp(from fileName: String) -> Date? {
        // Remove "processed/" prefix and ".png" suffix
        let cleanFileName = fileName
            .replacingOccurrences(of: "processed/", with: "")
            .replacingOccurrences(of: ".png", with: "")
        
        // Parse the date components
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HHmm"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = dateFormatter.date(from: cleanFileName) {
            // Convert to ISO8601 format to match forecast timestamps
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let iso8601String = iso8601Formatter.string(from: date)
            print("ContentView: Extracted timestamp ISO8601 string: \(iso8601String)")
            return iso8601Formatter.date(from: iso8601String)
        }
        
        return nil
    }
}
