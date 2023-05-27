import Foundation

public final class GooglePlacesLoader: PlacesLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadPlacesResult
      
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (LoadPlacesResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success((data, response)):
                do {
                    let places = try PlacesMapper.map(data, response)
                    completion(.success(places.toModels()))
                } catch {
                    completion(.failure(error))
                }
            case .failure:
                completion(.failure(GooglePlacesLoader.Error.connectivity))
            }
        }
    }
}


private extension Array where Element == GooglePlace {
    func toModels() -> [Place] {
        self.map{ Places.Place(id: $0.id,
                               name: $0.name,
                               category: $0.category,
                               imageUrl: $0.imageUrl,
                               location: $0.geometry.location) }
    }
}

private extension GooglePlace.Geometry {
    var location: Places.Location {
        Places.Location(latitude: googleLocation.lat,
                        longitude: googleLocation.lng)
    }
}
