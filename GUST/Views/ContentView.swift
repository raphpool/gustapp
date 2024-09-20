import SwiftUI
import AWSS3

struct ContentView: View {
    @State private var pngFiles: [PNGFile] = []
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTilesetId: String? = nil
    @State private var isSearchSheetPresented = false
    @State private var currentTimestamp: Date? = nil
    @EnvironmentObject var forecastListViewModel: ForecastListViewModel
    @EnvironmentObject var appState: AppState
    @State private var shouldAutoFocusSearch = false
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CustomMapViewControllerRepresentable(
                selectedImage: selectedImage,
                tilesetId: selectedTilesetId,
                currentTimestamp: currentTimestamp,
                forecastRecords: forecastListViewModel.forecasts,
                isLoadingForecasts: forecastListViewModel.isLoadingForecasts
            )                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Button(action: presentSearch) {
                    Text("Rechercher")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 4)
                
                PNGFilesScrollView(pngFiles: pngFiles) { pngFile in
                    Task {
                        await fetchImage(bucket: "gustlayers", key: pngFile.fullName)
                        
                        let tilesetId = pngFile.fullName
                            .replacingOccurrences(of: "processed/", with: "")
                            .replacingOccurrences(of: ".png", with: "")
                            .replacingOccurrences(of: "-", with: "_")
                            .replacingOccurrences(of: "T", with: "_")
                        
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
                    SearchOverlayView(shouldAutoFocus: $shouldAutoFocusSearch)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .padding(.top, 16)
                }
        .onAppear {
            print("ContentView: onAppear triggered")
            let startTime = Date()
            Task {
                do {
                    print("ContentView: Starting to fetch PNG files")
                    let pngFiles = try await listPNGFilesInProcessedFolder(bucket: "gustlayers", folder: "processed/")
                    self.pngFiles = pngFiles.map { PNGFile(fullName: $0) }
                    print("ContentView: PNG files fetched in \(Date().timeIntervalSince(startTime)) seconds")
                } catch {
                    print("ContentView: Failed to fetch files: \(error)")
                }
            }
            
        }
    }
    func presentSearch() {
            shouldAutoFocusSearch = true
            isSearchSheetPresented = true
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
