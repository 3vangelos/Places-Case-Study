import Foundation

class PlacesMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [Places.Place] {
        guard response.statusCode == 200 else {
            throw GooglePlacesLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(Root.self, from: data).results.map { $0.place }
    }
}

private extension PlacesMapper {
    private struct Root: Decodable {
        let results: [Place]
    }

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

extension PlacesMapper.Place {
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

