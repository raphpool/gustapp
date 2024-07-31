import SwiftUI
import AWSS3

struct ContentView: View {
    @State private var pngFiles: [PNGFile] = []
    @State private var selectedImage: UIImage? = nil
    @State private var selectedTilesetId: String? = nil
    @State private var isSearchOverlayPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CustomMapViewControllerRepresentable(selectedImage: selectedImage, tilesetId: selectedTilesetId)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Button(action: {
                    withAnimation(.spring()) {
                        isSearchOverlayPresented = true
                    }
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
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 16)
            }
        }
        .overlay(
            SearchOverlayView(isPresented: $isSearchOverlayPresented)
                .offset(y: isSearchOverlayPresented ? 0 : UIScreen.main.bounds.height)
                .animation(.spring(), value: isSearchOverlayPresented)
        )
        .onAppear {
            Task {
                do {
                    let pngFiles = try await listPNGFilesInProcessedFolder(bucket: "gustlayers", folder: "processed/")
                    self.pngFiles = pngFiles.map { PNGFile(fullName: $0) }
                } catch {
                    print("Failed to fetch files: \(error)")
                }
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
}
