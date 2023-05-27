import Foundation

struct GooglePlace: Decodable {
    let id: String
    let name: String
    let category: String?
    let imageUrl: URL?
    let geometry: Geometry
    
    private enum CodingKeys: String, CodingKey {
        case id = "place_id"
        case name
        case category
        case imageUrl
        case geometry
    }
}

extension GooglePlace {
    struct Geometry: Decodable {
        let googleLocation: Location
        
        private enum CodingKeys: String, CodingKey {
            case googleLocation = "location"
        }
    }
}

extension GooglePlace.Geometry {
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
}

