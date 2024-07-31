import Combine
import MapKit

class SelectedLocation: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D? {
        didSet {
            print("SelectedLocation.coordinate didSet: \(String(describing: coordinate))")
        }
    }
}

class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var showSuggestions: Bool = false
    @Published var selectedLocation = SelectedLocation()
    
    private var searchCompleter: MKLocalSearchCompleter
    private var cancellables: Set<AnyCancellable> = []
    private var isSelectingCompletion = false
    
    override init() {
        searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        searchCompleter.resultTypes = .address
        searchCompleter.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.2276, longitude: 2.2137),
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
        )
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                if !self!.isSelectingCompletion {
                    self?.searchCompleter.queryFragment = newValue
                    self?.showSuggestions = !newValue.isEmpty
                }
                self?.isSelectingCompletion = false
            }
            .store(in: &cancellables)
        
        searchCompleter.delegate = self
    }
    
    func selectSuggestion(_ suggestion: MKLocalSearchCompletion) {
        isSelectingCompletion = true
        searchText = suggestion.title
        let searchRequest = MKLocalSearch.Request(completion: suggestion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] (response, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    print("No valid coordinate found in search response.")
                    return
                }
                
                print("Coordinate obtained from suggestion: \(coordinate)")
                self.selectedLocation.coordinate = coordinate
                self.showSuggestions = false
                self.dismissKeyboard()
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
        showSuggestions = !completer.results.isEmpty && !isSelectingCompletion
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error while fetching suggestions: \(error)")
    }
}
