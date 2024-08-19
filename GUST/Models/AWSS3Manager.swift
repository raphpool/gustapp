import AWSS3 // Import the S3 service from AWS SDK for Swift
import Foundation

func createS3Client() async throws -> S3Client {
    let s3 = try await S3Client()
    return s3
}

// List files & set displayname with timestamps (to be used by picker)

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
        // Extract the date and hour from the file name
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

//// Wind direction layer
//func listVectorTileFilesInFolder(bucket: String, folder: String) async throws -> [String] {
//    let s3 = try await createS3Client()
//    let input = ListObjectsV2Input(bucket: bucket, prefix: folder)
//    let output = try await s3.listObjectsV2(input: input)
//    var vectorTileFiles: [String] = []
//
//    if let objects = output.contents {
//        for object in objects where object.key?.hasSuffix(".mbtiles") ?? false {
//            if let fileName = object.key {
//                vectorTileFiles.append(fileName)
//            }
//        }
//    }
//
//    return vectorTileFiles
//}
//
//
//struct VectorTileFile {
//    let fullName: String
//    let displayName: String
//    
//    init(fullName: String) {
//        self.fullName = fullName
//        let components = fullName.split(separator: "_")
//        if components.count >= 4 {
//            let day = components[2]
//            let time = components[3].prefix(4) // Extracting HHMM part
//            let hour = time.prefix(2)
//            let minute = time.suffix(2)
//            self.displayName = "\(day)\(hour)\(minute)"
//        } else {
//            self.displayName = fullName // Fallback if parsing fails
//        }
//    }
//}



