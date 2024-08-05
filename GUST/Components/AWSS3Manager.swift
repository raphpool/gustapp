import AWSS3 // Import the S3 service from AWS SDK for Swift
import Foundation

func createS3Client() async throws -> S3Client {
    let s3 = try await S3Client()
    return s3
}


// Wind speed layer
func listPNGFilesInProcessedFolder(bucket: String, folder: String) async throws -> [String] {
    let s3 = try await createS3Client()
    let input = ListObjectsV2Input(bucket: bucket, prefix: folder)
    let output = try await s3.listObjectsV2(input: input)
    var pngFiles: [String] = []

    if let objects = output.contents {
        for object in objects where object.key?.hasSuffix(".png") ?? false {
            if let fileName = object.key {
                pngFiles.append(fileName)
            }
        }
    }

    return pngFiles
}


struct PNGFile {
    let fullName: String
    let displayName: String
    
    init(fullName: String) {
        self.fullName = fullName
        if let datePart = fullName.split(separator: "T").first,
           let timePart = fullName.split(separator: "T").last?.prefix(4) {
            let day = datePart.suffix(2)
            let hour = timePart.prefix(2)
            let minute = timePart.suffix(2)
            self.displayName = "\(day)\(hour)\(minute)"
        } else {
            self.displayName = fullName // Fallback if parsing fails
        }
    }
}
