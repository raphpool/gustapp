import UIKit
import MapboxMaps
import SwiftUI
import Foundation

class CustomMapViewController: UIViewController, AnnotationInteractionDelegate {
    var mapView: MapView!
    var selectedImage: UIImage? {
        didSet {
            addImageLayer(with: selectedImage)
        }
    }
    var tilesetId: String? {
        didSet {
            addWindDirectionLayer(with: tilesetId)
        }
    }
    var currentTimestamp: Date?
    var forecastRecords: [String: [Record]] = [:]
    private var bottomSheetViewController: UIHostingController<SpotDetailBottomSheet>?
    private var viewAnnotationManager: ViewAnnotationManager!

    private var cancelables = Set<AnyCancelable>()
    private var pointAnnotationManager: PointAnnotationManager!
    private var spotFetcher = SpotFetcher()
    private var kiteSpots: [KiteSpotFields] = []
    private var annotationToKiteSpotMap: [String: String] = [:]
    private var currentViewAnnotation: UIView?
    private var selectedSpot: KiteSpotFields?



    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 44, longitude: -2.5), zoom: 2)
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self
        viewAnnotationManager = mapView.viewAnnotations

        fetchAndAddKiteSpots()
    }
    
    private func fetchAndAddKiteSpots() {
        Task {
            do {
                let kiteSpots = try await spotFetcher.fetchKiteSpots()
                print("CustomMapViewController: Fetched \(kiteSpots.count) kite spots")
                self.kiteSpots = kiteSpots
                addAnnotations(for: kiteSpots)
            } catch {
                print("CustomMapViewController: Error fetching kite spots: \(error)")
            }
        }
    }
    
    private func addAnnotations(for kiteSpots: [KiteSpotFields]) {
        var annotations = [PointAnnotation]()
        for spot in kiteSpots {
            var annotation = PointAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.lat, longitude: spot.lon))
            annotation.image = .init(image: UIImage(named: "PlaceMarker")!, name: "PlaceMarker")
            
            annotations.append(annotation)
            
            annotationToKiteSpotMap[annotation.id] = spot.spotName
        }
        
        print("CustomMapViewController: Adding \(annotations.count) point annotations")
        print("CustomMapViewController: annotationToKiteSpotMap has \(annotationToKiteSpotMap.count) entries")
        
        DispatchQueue.main.async {
            self.pointAnnotationManager.annotations = annotations
        }
    }
    
    func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
        print("Tapped annotation detected")
        
        if let annotation = annotations.first as? PointAnnotation,
           let spotName = annotationToKiteSpotMap[annotation.id],
           let kiteSpotFields = kiteSpots.first(where: { $0.spotName == spotName }) {
            print("Found kite spot for annotation: \(spotName)")
            addViewAnnotation(at: annotation.point.coordinates, for: kiteSpotFields)
        } else {
            print("Could not find kite spot for tapped annotation")
        }
    }
    
    private func createViewAnnotationContent(for kiteSpotFields: KiteSpotFields) -> UIView {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 13
        containerView.clipsToBounds = true


        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        nameLabel.text = kiteSpotFields.spotName
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .black
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        let windSpeedLabel = UILabel(frame: CGRect(x: 0, y: 40, width: 200, height: 25))
        let windGustLabel = UILabel(frame: CGRect(x: 0, y: 65, width: 200, height: 25))
        let windDirectionLabel = UILabel(frame: CGRect(x: 0, y: 90, width: 200, height: 25))

        [windSpeedLabel, windGustLabel, windDirectionLabel].forEach {
            $0.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            $0.textColor = .darkGray
            $0.textAlignment = .center
        }

        if let currentTimestamp = currentTimestamp,
           let records = forecastRecords[kiteSpotFields.spotId],
           let matchingRecord = findMatchingRecord(for: currentTimestamp, in: records) {
            windSpeedLabel.text = "Wind: \(String(format: "%.1f", matchingRecord.fields.windSpeed)) knts"
            windGustLabel.text = "Gust: \(String(format: "%.1f", matchingRecord.fields.windGust)) knts"
            windDirectionLabel.text = "Direction: \(formatWindDirection(degrees: matchingRecord.fields.windDegrees)) (\(String(format: "%.0f", matchingRecord.fields.windDegrees))°)"
        } else {
            windSpeedLabel.text = "Wind: N/A"
            windGustLabel.text = "Gust: N/A"
            windDirectionLabel.text = "Direction: N/A"
        }

        [nameLabel, windSpeedLabel, windGustLabel, windDirectionLabel].forEach {
                containerView.addSubview($0)
            }

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
            containerView.isUserInteractionEnabled = true
            containerView.addGestureRecognizer(tapGesture)

            containerView.tag = kiteSpotFields.hashValue

            return containerView
        }

    @objc private func handleAnnotationTap(_ gesture: UITapGestureRecognizer) {
        guard let containerView = gesture.view else {
            print("Failed to get container view")
            return
        }
        
        let tappedSpotId = containerView.tag
        
        if let kiteSpot = kiteSpots.first(where: { $0.spotId.hashValue == tappedSpotId }) {
            print("Tapped on spot: \(kiteSpot.spotName ?? "Unknown"), spotId: \(kiteSpot.spotId)")
            selectedSpot = kiteSpot
            print("Set selectedSpot to \(kiteSpot.spotName ?? "Unknown")")
            presentBottomSheet(for: kiteSpot)
        } else {
            print("Failed to find kiteSpot for tapped view with tag: \(tappedSpotId)")
        }
    }

    private func formatWindDirection(degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25).truncatingRemainder(dividingBy: 360) / 22.5)
        return directions[index]
    }
    
    private func presentBottomSheet(for kiteSpot: KiteSpotFields) {
        print("Presenting bottom sheet for spot: \(kiteSpot.spotName ?? "Unknown")")
        let bottomSheetView = SpotDetailBottomSheet(kiteSpot: kiteSpot)
        let hostingController = UIHostingController(rootView: bottomSheetView)
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(hostingController, animated: true) {
            print("Bottom sheet presented successfully for spot: \(kiteSpot.spotName ?? "Unknown")")
        }
        bottomSheetViewController = hostingController
    }
    
    func updateAnnotations() {
        print("CustomMapViewController: Updating annotations")
        print("CustomMapViewController: Current timestamp: \(String(describing: currentTimestamp))")
        print("CustomMapViewController: Forecast records count: \(forecastRecords.count)")
        print("CustomMapViewController: Number of annotations: \(viewAnnotationManager.annotations.count)")
        
        for (view, _) in viewAnnotationManager.annotations {
            if let kiteSpotFields = kiteSpots.first(where: { $0.spotId.hashValue == view.tag }) {
                print("CustomMapViewController: Updating annotation for spot: \(kiteSpotFields.spotName ?? "Unknown")")
                let updatedContent = createViewAnnotationContent(for: kiteSpotFields)
                view.subviews.forEach { $0.removeFromSuperview() }
                for subview in updatedContent.subviews {
                    view.addSubview(subview)
                }
            } else {
                print("CustomMapViewController: Could not find kite spot fields for annotation")
            }
        }
    }
    
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D, for kiteSpotFields: KiteSpotFields) {
        print("CustomMapViewController: Adding view annotation for spot: \(kiteSpotFields.spotName ?? "Unknown")")
        
        // Remove existing view annotation if any
        if let currentViewAnnotation = currentViewAnnotation {
            viewAnnotationManager.remove(currentViewAnnotation)
        }

        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: 200,
            height: 120,
            allowOverlap: false,
            anchor: .bottom,
            offsetY: 12
        )

        let content = createViewAnnotationContent(for: kiteSpotFields)
        content.tag = kiteSpotFields.spotId.hashValue
        
        do {
            try viewAnnotationManager.add(content, options: options)
            currentViewAnnotation = content
            print("CustomMapViewController: Successfully added view annotation")
        } catch {
            print("CustomMapViewController: Error adding view annotation: \(error)")
        }
    }
    
    func addWindDirectionLayer(with string: String?) {
        guard let mapView = mapView, let string = string else { return }
        
        print("Starting to add Wind Direction Layer using Mapbox tileset.")
        
        do {
            let sourceId = "wind-direction-source"
            if mapView.mapboxMap.layerExists(withId: "wind-direction-layer") {
                try mapView.mapboxMap.removeLayer(withId: "wind-direction-layer")
            }
            if mapView.mapboxMap.sourceExists(withId: sourceId) {
                try mapView.mapboxMap.removeSource(withId: sourceId)
            }
            var vectorSource = VectorSource(id: sourceId)
            vectorSource.url = "mapbox://raphaeldoulonne.\((tilesetId ?? "defaultTilesetId"))" // Dynamic tileset ID with default
            
            print("Adding Vector Source to the map's style")
            // Add the vector source to the map's style
            try mapView.mapboxMap.addSource(vectorSource)
            
            // Ensure the "Arrow" image is added to the map's style for use in the symbol layer
            if let arrowImage = UIImage(named: "Arrow") {
                try? mapView.mapboxMap.addImage(arrowImage, id: "Arrow")
            }
            
            print("Creating symbol layer")
            // Create a symbol layer using the vector source
            var symbolLayer = SymbolLayer(id: "wind-direction-layer", source: sourceId)
            // Assuming "wind-direction" is the correct source layer within your tileset
            // This needs to match the layer name in your vector tileset that contains the wind_direction feature property
            symbolLayer.sourceLayer = tilesetId
            symbolLayer.iconImage = .constant(.name("Arrow"))
            symbolLayer.iconAllowOverlap = .constant(true)
            symbolLayer.iconRotate = .expression(Exp(.get) { "wind_direction" })
            symbolLayer.iconRotationAlignment = .constant(.map)
            
            print("Adding the symbol layer to the map")
            // Add the symbol layer to the map
            try mapView.mapboxMap.addLayer(symbolLayer)
            
            print("Wind Direction Layer added successfully using tileset source.")
            
        } catch {
            print("Error adding vector source or symbol layer: \(error)")
        }
    }
    func addImageLayer(with image: UIImage?) {
        guard let mapView = mapView, let image = image else { return }
        
        let sourceId = "image-source"
        var imageSource = ImageSource(id: sourceId)
        imageSource.coordinates = [
            [-5.3, 51.1], // top-left
            [9.6, 51.1], // top-right
            [9.6, 41.3], // bottom-right
            [-5.3, 41.3] // bottom-left
        ]
        
        // Convert the UIImage to Data and use the utility function to save it
        if let imageData = image.pngData(),
           let imageURL = imageData.saveToTemporaryDirectory(withFilename: "dynamic_image.png") {
            imageSource.url = imageURL.absoluteString
        }
        
        // Prepare the layer using the source
        var imageLayer = RasterLayer(id: "image-layer", source: sourceId)
        imageLayer.rasterOpacity = .constant(0.7)
        
        // Add the source and layer to the map
        do {
            if mapView.mapboxMap.layerExists(withId: imageLayer.id) {
                try mapView.mapboxMap.removeLayer(withId: imageLayer.id)
            }
            
            // Remove existing source and layer if they exist
            if mapView.mapboxMap.sourceExists(withId: sourceId) {
                try mapView.mapboxMap.removeSource(withId: sourceId)
            }
            // Add the new source and layer
            try mapView.mapboxMap.addSource(imageSource)
            try mapView.mapboxMap.addLayer(imageLayer)
        } catch {
            print("Failed to add the source or layer. Error: \(error)")
        }
    }
}

struct CustomMapViewControllerRepresentable: UIViewControllerRepresentable {
    var selectedImage: UIImage?
    var tilesetId: String?
    var currentTimestamp: Date?
    var forecastRecords: [String: [Record]]
    
    func makeUIViewController(context: Context) -> CustomMapViewController {
        let controller = CustomMapViewController()
        controller.selectedImage = selectedImage
        controller.tilesetId = tilesetId  
        controller.currentTimestamp = currentTimestamp
        controller.forecastRecords = forecastRecords
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CustomMapViewController, context: Context) {
        print("CustomMapViewControllerRepresentable: Updating UI")
        uiViewController.selectedImage = selectedImage
        uiViewController.tilesetId = tilesetId
        uiViewController.currentTimestamp = currentTimestamp
        uiViewController.forecastRecords = forecastRecords
        print("CustomMapViewControllerRepresentable: Current timestamp: \(String(describing: currentTimestamp))")
        print("CustomMapViewControllerRepresentable: Forecast records count: \(forecastRecords.count)")
        uiViewController.updateAnnotations()
    }
}


extension Data {
    func saveToTemporaryDirectory(withFilename filename: String) -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let targetURL = tempDirectoryURL.appendingPathComponent(filename)
        
        do {
            try self.write(to: targetURL)
            return targetURL
        } catch {
            print("Failed to write image data to temporary directory: \(error)")
            return nil
        }
    }
}

private func findMatchingRecord(for timestamp: Date, in records: [Record]) -> Record? {
    print("CustomMapViewController: Finding matching record for timestamp: \(timestamp)")
    
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    let matchingRecord = records.first { record in
        if let recordDate = dateFormatter.date(from: record.fields.timestamp) {
            let isMatch = Calendar.current.isDate(recordDate, equalTo: timestamp, toGranularity: .hour)
            print("CustomMapViewController: Comparing record date: \(recordDate), isMatch: \(isMatch)")
            print("CustomMapViewController: Record timestamp string: \(record.fields.timestamp)")
            return isMatch
        } else {
            print("CustomMapViewController: Failed to parse record timestamp: \(record.fields.timestamp)")
            return false
        }
    }
    
    print("CustomMapViewController: Matching record found: \(matchingRecord != nil)")
    return matchingRecord
}
