import SwiftUI
import MapKit

import CoreLocation


struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
    }
    
    // Add this method to make the search bar become first responder
    func becomeFirstResponder() -> some View {
        return self.modifier(BecomeFirstResponderModifier())
    }
}

// Add this custom modifier
struct BecomeFirstResponderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let keyWindow = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first?.windows
                        .filter { $0.isKeyWindow }.first
                    keyWindow?.rootViewController?.view.endEditing(true)
                    keyWindow?.rootViewController?.view.subviews.first?.becomeFirstResponder()
                }
            }
    }
}

