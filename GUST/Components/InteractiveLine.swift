import SwiftUI

struct InteractiveLine: View {
    var title: String
    var previewInfo: String?
    var previewInfoUrl: URL?
    var previewInfoUrl2: URL?
    var content: String?
    var linkUrl: URL?
    @State private var isOpen = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                
                Spacer()
                
                if let previewInfo = previewInfo {
                    Text(previewInfo)
                }
                
                if let previewInfoUrl = previewInfoUrl {
                    Link(destination: previewInfoUrl) {
                        Text(extractDomainName(from: previewInfoUrl))
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                
                if let previewInfoUrl2 = previewInfoUrl2 {
                    Link(destination: previewInfoUrl2) {
                        Text(extractDomainName(from: previewInfoUrl2))
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
                
                if let linkUrl = linkUrl {
                    Link(destination: linkUrl) {
                        Image("LinkIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
                
                if content != nil && content != "" {
                    Button(action: {
                        self.isOpen.toggle()
                    }) {
                        Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .font(.custom("Inter-Regular", size: 15))
            
            if isOpen, let content = content, content != "" {
                Text(content)
                    .font(.custom("Inter-Regular", size: 15))
                    .padding([.top, .bottom])
            }
        }
    }
    
    // Helper function to extract the domain name from a URL
    func extractDomainName(from url: URL) -> String {
        let hostName = url.host?.replacingOccurrences(of: "www.", with: "")
        let domainParts = hostName?.split(separator: ".")
        return domainParts?.first.map(String.init) ?? url.absoluteString
    }
}

struct InteractiveLine_Previews: PreviewProvider {
    static var previews: some View {
        InteractiveLine(
            title: "Plus d'infos",
            previewInfo: "Some preview info",
            previewInfoUrl: URL(string: "https://www.example.com"),
            previewInfoUrl2: URL(string: "https://www.example2.com"),
            content: "nil",
            linkUrl: URL(string: "https://example.com")
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
