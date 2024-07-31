import SwiftUI
import AWSS3

struct ImageDetailView: View {
    var bucket: String
    var key: String // The full key of the PNG file in the bucket
    
    @State private var image: UIImage? = nil
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Text("Loading image...")
                .onAppear {
                    Task {
                        await fetchImage()
                    }
                }
        }
    }
    
    func fetchImage() async {
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
                self.image = uiImage
            }
        } catch {
            print("Failed to fetch image: \(error)")
        }
    }
}




