import Foundation

internal class PlacesMapper {
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> GooglePlacesLoader.Result {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }

        return .success(root.places)
    }
}

private extension PlacesMapper {
    private struct Root: Decodable {
        let results: [Place]
        
        var places: [Places.Place] {
            return results.map { $0.place }
        }
    }
}

private extension PlacesMapper {
    struct Place: Decodable {
        private let id: String
        private let name: String
        private let category: String?
        private let imageUrl: URL?
        private let geometry: Geometry
        
        private enum CodingKeys: String, CodingKey {
            case id = "place_id"
            case name
            case category
            case imageUrl
            case geometry
        }
        
        var place: Places.Place {
            Places.Place(id: id,
                         name: name,
                         category: category,
                         imageUrl: imageUrl,
                         location: geometry.location)
        }
    }
}

private extension PlacesMapper.Place {
    struct Geometry: Decodable {
        private let googleLocation: Location

        private enum CodingKeys: String, CodingKey {
            case googleLocation = "location"
        }
        
        var location: Places.Location {
            Places.Location(latitude: googleLocation.lat,
                            longitude: googleLocation.lng)
        }
    }
}

private extension PlacesMapper.Place.Geometry {
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
}

