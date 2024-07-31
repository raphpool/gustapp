import SwiftUI

struct ModelCell: View {
    let model: String
    
    private let modelTranslations: [String: String] = [
        "meteofrance_arome_france_hd": "Ar",
        "meteofrance_arpege_europe": "Arp",
        "gfs_seamless": "Gfs"
    ]
    
    var body: some View {
        Text(abbreviation(for: model))
            .frame(width: 27, height: 28)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.black)
            .font(.custom("Inter-Regular", size: 11))
            .border(Color.white, width: 0.5)
            .lineLimit(1)
    }
    
    private func abbreviation(for model: String) -> String {
        modelTranslations[model] ?? model
    }
}

// Preview provider for the ModelCell
struct ModelCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ModelCell(model: "meteofrance_arome_france_hd")
            ModelCell(model: "meteofrance_arpege_europe")
            ModelCell(model: "gfs_seamless")
        }
        .previewLayout(.sizeThatFits)
    }
}
