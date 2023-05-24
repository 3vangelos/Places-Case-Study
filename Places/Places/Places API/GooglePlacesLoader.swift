import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class GooglePlacesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = Swift.Result<[Place], Error>
      
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success((data, response)):
                if let places = try? PlacesMapper.map(data, response) {
                    completion(.success(places))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class PlacesMapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [Place] {
        guard response.statusCode == 200 else {
            throw GooglePlacesLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(Root.self, from: data).results.map { $0.place }

    }
}

extension PlacesMapper {
    private struct Root: Decodable {
        let results: [GooglePlace]
    }
    
    private struct GooglePlace: Decodable {
        private let id: String
        private let name: String
        private let category: String?
        private let imageUrl: URL?
        private let location: GoogleLocation
        
        private enum CodingKeys: String, CodingKey {
            case id = "place_id"
            case name
            case category
            case imageUrl
            case location = "geometry"
        }
        
        var place: Place {
            return Place(id: id,
                         name: name,
                         category: category,
                         imageUrl: imageUrl,
                         location: location.placesLocation)
        }
    }
    
    struct GoogleLocation: Decodable {
        private let location: Location
        
        var longitude: Double {
            location.longitude
        }
        
        var latitude: Double {
            location.latitude
        }
        
        var placesLocation: Places.Location {
            return Places.Location(latitude: location.latitude,
                                   longitude: location.longitude)
        }
    }
}

private extension PlacesMapper.GoogleLocation {
    struct Location: Decodable {
        let latitude: Double
        let longitude: Double
        
        private enum CodingKeys: String, CodingKey {
            case latitude = "lat"
            case longitude = "lng"
        }
    }
}
