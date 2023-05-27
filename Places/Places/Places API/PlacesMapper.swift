import Foundation

internal class PlacesMapper {
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [GooglePlace] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw GooglePlacesLoader.Error.invalidData
        }
        
        return root.results
    }
}

private extension PlacesMapper {
    private struct Root: Decodable {
        let results: [GooglePlace]
    }
}

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

