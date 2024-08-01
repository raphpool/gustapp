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
    private var bottomSheetViewController: UIHostingController<SpotDetailBottomSheet>?
    
    private var cancelables = Set<AnyCancelable>()
    private var pointAnnotationManager: PointAnnotationManager!
    private var spotFetcher = SpotFetcher()
    private var kiteSpots: [KiteSpotFields] = []
    private var annotationToKiteSpotMap: [String: String] = [:]
    private var currentViewAnnotation: ViewAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = MapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 44, longitude: -2.5), zoom: 2)
        mapView.mapboxMap.setCamera(to: cameraOptions)
        
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self
        
        fetchAndAddKiteSpots()
    }
    
    private func fetchAndAddKiteSpots() {
        Task {
            do {
                let kiteSpots = try await spotFetcher.fetchKiteSpots()
                self.kiteSpots = kiteSpots
                addAnnotations(for: kiteSpots)
            } catch {
                print("Error fetching kite spots: \(error)")
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
        let label = UILabel()
        label.text = kiteSpotFields.spotName
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold) // Using system font as a fallback
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = .white
        label.frame = CGRect(x: 0, y: 0, width: 200, height: 65)
        label.layer.cornerRadius = 13
        label.clipsToBounds = true
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
        
        // Store the kiteSpotFields in the label's tag
        label.tag = kiteSpotFields.hashValue
        
        return label
    }
    @objc private func handleAnnotationTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
              let kiteSpot = kiteSpots.first(where: { $0.hashValue == label.tag }) else {
            return
        }
        
        presentBottomSheet(for: kiteSpot)
    }
    private func presentBottomSheet(for kiteSpot: KiteSpotFields) {
        let bottomSheetView = SpotDetailBottomSheet(kiteSpot: kiteSpot)
        let hostingController = UIHostingController(rootView: bottomSheetView)
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(hostingController, animated: true, completion: nil)
        bottomSheetViewController = hostingController
    }
    
    private func addViewAnnotation(at coordinate: CLLocationCoordinate2D, for kiteSpotFields: KiteSpotFields) {
        currentViewAnnotation?.remove()
        let view = createViewAnnotationContent(for: kiteSpotFields)
        let viewAnnotation = ViewAnnotation(coordinate: coordinate, view: view)
        viewAnnotation.variableAnchors = [ViewAnnotationAnchorConfig(anchor: .bottom, offsetY: -view.frame.height / 2)]
        mapView.viewAnnotations.add(viewAnnotation)
        currentViewAnnotation = viewAnnotation
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
    var tilesetId: String?  // Use tilesetId instead of selectedGeoJSONData
    
    func makeUIViewController(context: Context) -> CustomMapViewController {
        let controller = CustomMapViewController()
        controller.selectedImage = selectedImage
        controller.tilesetId = tilesetId  // Pass tilesetId to the controller
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CustomMapViewController, context: Context) {
        uiViewController.selectedImage = selectedImage
        uiViewController.tilesetId = tilesetId  // Update tilesetId in the controller
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
