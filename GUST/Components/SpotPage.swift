import SwiftUI

struct SpotPage: View {
    let kiteSpot: KiteSpotFields
    
    var formattedTides: String {
        var tides = [String]()
        if kiteSpot.lowTide == "Yes" { tides.append("Basse") }
        if kiteSpot.midTide == "Yes" { tides.append("Intermédiaire") }
        if kiteSpot.highTide == "Yes" { tides.append("Haute") }
        return tides.joined(separator: ", ")
    }
    
    var formattedBestWindDirection: String {
        kiteSpot.bestWindDirection?.joined(separator: ", ") ?? ""
    }
    
    // Helper function to extract the domain name from a URL
    func extractDomainName(from url: URL) -> String {
        let hostName = url.host?.replacingOccurrences(of: "www.", with: "")
        let domainParts = hostName?.split(separator: ".")
        return domainParts?.first.map(String.init) ?? url.absoluteString
    }
    
    func formattedDescription(from description: String?) -> [String] {
        guard let description = description else { return [] }
        let titles = ["Informations générales", "Conditions de navigation", "Sécurité et règlementations", "Accès"]
        
        let pattern = "(?:" + titles.joined(separator: "|") + ")"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = description as NSString
            let results = regex.matches(in: description, options: [], range: NSRange(location: 0, length: nsString.length))
            
            var sections: [String] = []
            var lastLocation = 0
            for result in results {
                let range = result.range(at: 0)
                let sectionContent = nsString.substring(with: NSRange(location: lastLocation, length: range.location - lastLocation)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sectionContent.isEmpty {
                    sections.append(sectionContent)
                }
                lastLocation = range.location + range.length
            }
            
            // Add the last section if applicable
            if lastLocation < nsString.length {
                let lastSection = nsString.substring(from: lastLocation).trimmingCharacters(in: .whitespacesAndNewlines)
                if !lastSection.isEmpty {
                    sections.append(lastSection)
                }
            }
            
            return sections
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
            return []
        }
    }
    func formattedWindAndTideDescription(description: String) -> some View {
        let trimmedDescription = description.trimmingCharacters(in: .init(charactersIn: "\""))
        let quotes = trimmedDescription.split(separator: "\"").map(String.init).filter { !$0.isEmpty }
        
        return VStack(alignment: .leading) {
            ForEach(quotes, id: \.self) { quote in
                Text(quote)
                    .padding(.vertical, 2)
            }
            
            if let aboutURL = kiteSpot.about, let url = URL(string: aboutURL) {
                Link(destination: url) {
                    Text(extractDomainName(from: url))
                }
            }
            
            if let about2URL = kiteSpot.about2, let url = URL(string: about2URL) {
                Link(destination: url) {
                    Text(extractDomainName(from: url))
                }
            }
        }
    }
    var body: some View {
           ScrollView {
               VStack(alignment: .leading, spacing: 8) {
                   // Spot name and address block
                   VStack(alignment: .center, spacing: 8) {
                       Text(kiteSpot.spotName ?? "Spot")
                           .font(.title)
                           .fontWeight(.semibold)
                           .multilineTextAlignment(.center)
                           .padding(.top)
                       
                       Link(destination: URL(string: "https://www.google.com/maps/place/\(kiteSpot.lat),\(kiteSpot.lon)")!) {
                           Text(kiteSpot.fullAddress ?? "Adresse")
                               .foregroundColor(Color.gray)
                               .underline()
                       }
                   }
                   .frame(maxWidth: .infinity)
                   .padding(.bottom, 16)
                   
                   // Description
                   informationContainerView {
                       InteractiveLine(
                           title: "Description du spot",
                           content: kiteSpot.spotDescription2
                       )
                   }
                   
                   // Wind direction
                   informationContainerView {
                       InteractiveLine(
                           title: "Orientations idéales",
                           previewInfo: formattedBestWindDirection,
                           content: kiteSpot.bestWindDescription2
                       )
                   }
                   
                   // Tides
                   informationContainerView {
                       InteractiveLine(
                           title: "Marées praticables",
                           previewInfo: formattedTides,
                           content: kiteSpot.tideDescription2
                       )
                   }
                   
                   informationContainerView {
                       VStack(spacing: 16) {
                           InteractiveLine(
                               title: "Vidéos",
                               linkUrl: URL(string: "https://www.youtube.com/results?search_query=\(kiteSpot.spotName ?? "france")+kitesurf")
                           )
                           InteractiveLine(
                               title: "Images",
                               linkUrl: URL(string: "https://www.google.fr/search?q=\(kiteSpot.spotName ?? "france")+kitesurf&tbm=isch")
                           )
                       }
                   }
                   
                   // More infos
                   informationContainerView {
                       InteractiveLine(
                           title: "Plus d'infos",
                           previewInfoUrl: URL(string: kiteSpot.about ?? ""),
                           previewInfoUrl2: URL(string: kiteSpot.about2 ?? "")
                       )
                   }
                   
                   Spacer(minLength: 40)
               }
               .padding(.horizontal)
           }
           .background(Color(hex: "F9F9F9FF"))
           .navigationBarTitle(Text("Spot Details"), displayMode: .large)
       }
       
       // Helper view to provide consistent styling for InteractiveLine containers
       @ViewBuilder
       private func informationContainerView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
           VStack {
               content()
           }
           .padding(.vertical, 10)
           .padding(.horizontal, 16)
           .background(Color.white)
           .cornerRadius(8)
       }
   }

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

let sampleKiteSpot = KiteSpotFields(
    spotName: "Pont-Mahe",
    spotDirection: "South-west",
    lowTide: "No",
    highTide: "Yes",
    midTide: "Yes",
    lowTideDescription: "Impossible à pratiquer, il n'y a pas d'eau sur le spot",
    highTideDescription: "Praticable, attention cependant à marée très haute il n'y a pas beaucoup de place sur la plage pour décoller et atterrir",
    midTideDescription: "Idéal, des chances d'obtenir des zones de flat",
    lat: 47.441331788580335,
    lon: -2.4533732272276865,
    about: "https://www.magasin-glissevolution.com/blog/spot-de-pont-mahe-n199",
    spotDescription: "Informations générales :\n- Pont-Mahé est situé à Assérac, à 20 km au nord de La Baule, à la frontière de la Loire Atlantique et du Morbihan.\n- C'est u...",
    about2: "https://www.newkite.fr/pont-mahe/",
    spotId: "pontmahe",
    bestWindDirection: ["SO", "O"],
    bestWindDescription: "Idéal de sud-sud ouest à ouest",
    forecastStatus: "Processed",
    hasTides: "Yes",
    fullAddress: "6 Rue De La Plage, Assérac, Loire-Atlantique",
    bestWindDescription2: "Orientation du vent :\nSud-Ouest : onshore\nOuest : side onshore\nNord-Ouest : sideshore\nNord : side offshore\nNord-Est : offshore\nEst : offshore\nSud-Est...",
    tideDescription2: "Attention aux marées, le spot n'est pas navigable à toute heure. En pleine marée basse il n'y a pas d'eau pour naviguer et à marée haute très peu de ...",
    contentStatus: "Processed",
    spotDescription2: "Informations générales :\n- Pont-Mahé est situé à Assérac, à 20 km au nord de La Baule, à la frontière de la Loire Atlantique et du Morbihan.\n- C'est u...",
    tideDescription1: "Marée basse : Impossible à pratiquer, il n'y a pas deau sur le spot\n\nMarée intermédiaire : Idéal, des chances d'obtenir des zones de flat\n\nMarée haute : Praticable, attention cependant à marée très haute il n'y a pas beaucoup de place sur la plage pour décoller et atterrir"
)

struct SpotPage_Previews: PreviewProvider {
    static var previews: some View {
        SpotPage(kiteSpot: sampleKiteSpot)
    }
}
