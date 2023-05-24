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
                completion(PlacesMapper.map(data, response))
            case .failure:
                completion(.failure(GooglePlacesLoader.Error.connectivity))
            }
        }
    }
}
