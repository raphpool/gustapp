import UIKit
import MapboxMaps
import SwiftUI
import Foundation

class KiteSpotAnnotationView: UIView {
    private let nameLabel = UILabel()
    private let speedLabel = UILabel()
    private let arrowImageView = UIImageView()
    private let directionLabel = UILabel()
    private let tideLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLoadingIndicator() {
        subviews.forEach { $0.isHidden = true }
        addSubview(activityIndicator)
        activityIndicator.center = CGPoint(x: bounds.width / 2, y: 30)
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
        subviews.forEach { $0.isHidden = false }
    }
    
    func showErrorMessage(_ message: String) {
        hideLoadingIndicator()
        // You might want to add a label for error messages if you haven't already
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 13
        clipsToBounds = true
        
        [nameLabel, speedLabel, arrowImageView, directionLabel, tideLabel].forEach { addSubview($0) }
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textAlignment = .left
        nameLabel.numberOfLines = 1
        
        speedLabel.font = .systemFont(ofSize: 14, weight: .regular)
        speedLabel.textAlignment = .left
        speedLabel.numberOfLines = 1
        
        arrowImageView.contentMode = .scaleAspectFit
        arrowImageView.image = UIImage(named: "Arrow")?.withRenderingMode(.alwaysTemplate)
        
        directionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        directionLabel.textAlignment = .right
        directionLabel.numberOfLines = 1
        
        tideLabel.font = .systemFont(ofSize: 14, weight: .regular)
        tideLabel.textAlignment = .left
        tideLabel.numberOfLines = 1
        
        errorLabel.textColor = .red
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let hasTides = !tideLabel.isHidden
        let height: CGFloat = hasTides ? 90 : 60 // Adjust these values as needed
        
        nameLabel.frame = CGRect(x: 8, y: 5, width: frame.width - 16, height: 25)
        speedLabel.frame = CGRect(x: 8, y: 30, width: frame.width / 2 - 14, height: 25)
        arrowImageView.frame = CGRect(x: frame.width / 2 - 18, y: 32, width: 25, height: 25)
        directionLabel.frame = CGRect(x: frame.width / 2 - 6, y: 30, width: frame.width / 2 - 6, height: 25)
        
        if hasTides {
            tideLabel.frame = CGRect(x: 8, y: 60, width: frame.width - 16, height: 25)
        }
        errorLabel.frame = CGRect(x: 8, y: bounds.height - 30, width: bounds.width - 16, height: 25)
        
        frame.size.height = height
    }
    
    func configure(with kiteSpot: KiteSpotFields,
                   windSpeed: String,
                   windGust: String,
                   windDirection: String,
                   windDegrees: Int,
                   relativeDirection: String,
                   isBestWindDirection: Bool,
                   tideDescription: String?,
                   lowTide: String,
                   midTide: String,
                   highTide: String,
                   hasTides: Bool) {
        hideLoadingIndicator()
        nameLabel.text = kiteSpot.spotName
        speedLabel.text = "\(windSpeed) / \(windGust) knots"
        directionLabel.text = "(\(windDirection) / \(relativeDirection))"
        
        let directionColor: UIColor = isBestWindDirection ? .green : .black
        directionLabel.textColor = directionColor
        arrowImageView.tintColor = directionColor
        
        arrowImageView.transform = CGAffineTransform(rotationAngle: CGFloat(windDegrees) * .pi / 180 - .pi / 2)
        
        if hasTides, let tideDescription = tideDescription {
            let tidePracticable = practicableTide(for: tideDescription, lowTide: lowTide, midTide: midTide, highTide: highTide)
            let frenchTideDescription = translateTideDescription(tideDescription)
            tideLabel.text = frenchTideDescription
            tideLabel.textColor = tidePracticable == "No" ? .red : .black
            tideLabel.isHidden = false
        } else {
            tideLabel.isHidden = true
        }
        
        setNeedsLayout()
    }
    
    private func translateTideDescription(_ description: String) -> String {
        switch description.lowercased() {
        case "low":
            return "Marée basse"
        case "mid":
            return "Marée intermédiaire"
        case "high":
            return "Marée haute"
        default:
            return description
        }
    }
    
    private func practicableTide(for description: String, lowTide: String, midTide: String, highTide: String) -> String {
        switch description {
        case "low":
            return lowTide
        case "mid":
            return midTide
        case "high":
            return highTide
        default:
            return ""
        }
    }
    
    private func capitalizeFirstLetter(string: String) -> String {
        return string.prefix(1).uppercased() + string.dropFirst()
    }
}


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
    private var forecastFetcher = ForecastFetcher()
    var isLoadingForecasts: Bool = false {
        didSet {
            updateAnnotations()
        }
    }
    
    
    
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
    
    // Annotation view
    
    private func configureAnnotationView(_ annotationView: KiteSpotAnnotationView, for kiteSpotFields: KiteSpotFields) {
        if let currentTimestamp = currentTimestamp,
           let records = forecastRecords[kiteSpotFields.spotId],
           let matchingRecord = findMatchingRecord(for: currentTimestamp, in: records) {
            let windSpeed = String(format: "%.0f", matchingRecord.fields.windSpeed)
            let windGust = String(format: "%.0f", matchingRecord.fields.windGust)
            let windDegrees = matchingRecord.fields.windDegrees
            let windDirection = formatWindDirection(degrees: matchingRecord.fields.windDegrees)
            let relativeDirection = RelativeWindDirection(rawValue: matchingRecord.fields.relativeDirection)?.translate() ?? matchingRecord.fields.relativeDirection
            
            let isBestWindDirection = kiteSpotFields.bestWindDirection?.contains(windDirection) ?? false
            
            let tideDescription = matchingRecord.fields.tideDescription
            let hasTides = kiteSpotFields.hasTides == "Yes"
            
            annotationView.configure(with: kiteSpotFields,
                                     windSpeed: windSpeed,
                                     windGust: windGust,
                                     windDirection: windDirection,
                                     windDegrees: windDegrees,
                                     relativeDirection: relativeDirection,
                                     isBestWindDirection: isBestWindDirection,
                                     tideDescription: tideDescription,
                                     lowTide: kiteSpotFields.lowTide ?? "No",
                                     midTide: kiteSpotFields.midTide ?? "No",
                                     highTide: kiteSpotFields.highTide ?? "No",
                                     hasTides: hasTides)
        } else {
            annotationView.configure(with: kiteSpotFields,
                                     windSpeed: "N/A",
                                     windGust: "N/A",
                                     windDirection: "N/A",
                                     windDegrees: 0,
                                     relativeDirection: "N/A",
                                     isBestWindDirection: false,
                                     tideDescription: nil,
                                     lowTide: "No",
                                     midTide: "No",
                                     highTide: "No",
                                     hasTides: false)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
        annotationView.addGestureRecognizer(tapGesture)
        annotationView.tag = kiteSpotFields.spotId.hashValue
    }
    
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D, for kiteSpotFields: KiteSpotFields) {
        print("CustomMapViewController: Adding view annotation for spot: \(kiteSpotFields.spotName ?? "Unknown")")
        
        // Remove existing view annotation if any
        if let currentViewAnnotation = currentViewAnnotation {
            mapView.viewAnnotations.remove(currentViewAnnotation)
        }
        
        let annotationView = KiteSpotAnnotationView(frame: CGRect(x: 0, y: 0, width: 235, height: 100))
        
        if isLoadingForecasts {
            annotationView.showLoadingIndicator()
        } else {
            configureAnnotationView(annotationView, for: kiteSpotFields)
        }
        
        let options = ViewAnnotationOptions(
            geometry: Point(coordinate),
            width: 235,
            height: 100,
            allowOverlap: false,
            anchor: .bottom
        )
        
        do {
            try mapView.viewAnnotations.add(annotationView, options: options)
            currentViewAnnotation = annotationView
            print("CustomMapViewController: Successfully added view annotation")
            
            if isLoadingForecasts {
                Task {
                    do {
                        while isLoadingForecasts {
                            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                        }
                        await MainActor.run {
                            self.configureAnnotationView(annotationView, for: kiteSpotFields)
                        }
                    } catch {
                        print("Error while waiting for forecast data: \(error)")
                        await MainActor.run {
                            self.handleLoadingError(annotationView: annotationView, error: error)
                        }
                    }
                }
            }
        } catch {
            print("CustomMapViewController: Error adding view annotation: \(error)")
            handleLoadingError(annotationView: annotationView, error: error)
        }
    }
    
    
    private func handleLoadingError(annotationView: KiteSpotAnnotationView, error: Error) {
        annotationView.showErrorMessage("Failed to load data")
        print("Error loading forecast data: \(error)")
    }
    
    
    func updateAnnotations() {
        print("CustomMapViewController: Updating annotations")
        print("CustomMapViewController: Current timestamp: \(String(describing: currentTimestamp))")
        print("CustomMapViewController: Forecast records count: \(forecastRecords.count)")
        print("CustomMapViewController: Is loading forecasts: \(isLoadingForecasts)")
        
        guard let mapView = mapView else {
            print("CustomMapViewController: MapView is not initialized yet")
            return
        }
        
        print("CustomMapViewController: Number of annotations: \(mapView.viewAnnotations.annotations.count)")
        
        for (annotationView, _) in mapView.viewAnnotations.annotations {
            guard let annotationView = annotationView as? KiteSpotAnnotationView,
                  let kiteSpotFields = kiteSpots.first(where: { $0.spotId.hashValue == annotationView.tag }) else {
                print("CustomMapViewController: Could not find kite spot fields for annotation")
                continue
            }
            
            print("CustomMapViewController: Updating annotation for spot: \(kiteSpotFields.spotName ?? "Unknown")")
            
            if isLoadingForecasts {
                annotationView.showLoadingIndicator()
            } else {
                if let currentTimestamp = currentTimestamp,
                   let records = forecastRecords[kiteSpotFields.spotId],
                   let matchingRecord = findMatchingRecord(for: currentTimestamp, in: records) {
                    let windSpeed = String(format: "%.0f", matchingRecord.fields.windSpeed)
                    let windGust = String(format: "%.0f", matchingRecord.fields.windGust)
                    let windDegrees = matchingRecord.fields.windDegrees
                    let windDirection = formatWindDirection(degrees: matchingRecord.fields.windDegrees)
                    let relativeDirection = RelativeWindDirection(rawValue: matchingRecord.fields.relativeDirection)?.translate() ?? matchingRecord.fields.relativeDirection
                    
                    let isBestWindDirection = kiteSpotFields.bestWindDirection?.contains(windDirection) ?? false
                    
                    let tideDescription = matchingRecord.fields.tideDescription
                    let hasTides = kiteSpotFields.hasTides == "Yes"
                    
                    annotationView.configure(with: kiteSpotFields,
                                             windSpeed: windSpeed,
                                             windGust: windGust,
                                             windDirection: windDirection,
                                             windDegrees: windDegrees,
                                             relativeDirection: relativeDirection,
                                             isBestWindDirection: isBestWindDirection,
                                             tideDescription: tideDescription,
                                             lowTide: kiteSpotFields.lowTide ?? "No",
                                             midTide: kiteSpotFields.midTide ?? "No",
                                             highTide: kiteSpotFields.highTide ?? "No",
                                             hasTides: hasTides)
                } else {
                    annotationView.configure(with: kiteSpotFields,
                                             windSpeed: "N/A",
                                             windGust: "N/A",
                                             windDirection: "N/A",
                                             windDegrees: 0,
                                             relativeDirection: "N/A",
                                             isBestWindDirection: false,
                                             tideDescription: nil,
                                             lowTide: "No",
                                             midTide: "No",
                                             highTide: "No",
                                             hasTides: false)
                }
            }
        }
    }
    
    
    // End of annotation view
    
    
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
    
    private func formatWindDirection(degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
        let normalizedDegrees = ((degrees % 360) + 360) % 360
        let index = Int(round(Double(normalizedDegrees) / 22.5)) % 16
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
    var isLoadingForecasts: Bool
    
    func makeUIViewController(context: Context) -> CustomMapViewController {
        let controller = CustomMapViewController()
        controller.selectedImage = selectedImage
        controller.tilesetId = tilesetId
        controller.currentTimestamp = currentTimestamp
        controller.forecastRecords = forecastRecords
        controller.isLoadingForecasts = isLoadingForecasts
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
        uiViewController.isLoadingForecasts = isLoadingForecasts
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
