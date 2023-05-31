import Foundation

public class CodablePlacesStore: PlacesStore {
    private struct Cache: Codable {
        let places: [CodableLocalPlace]
        let timestamp: Date
        
        var localPlaces: [LocalPlace] {
            self.places.map {
                $0.local
            }
        }
    }
    
    private struct CodableLocalPlace: Codable {
        private let id: String
        private let name: String
        private let category: String?
        private let imageUrl: URL?
        private let location: CodableLocation
        
        var local: LocalPlace {
            LocalPlace(id: id, name: name, category: category, imageUrl: imageUrl, location: location.local)
        }
        
        public init(_ localPlace: LocalPlace) {
            id = localPlace.id
            name = localPlace.name
            category = localPlace.category
            imageUrl = localPlace.imageUrl
            location = CodableLocation(latitude: localPlace.location.latitude, longitude: localPlace.location.longitude)
        }
    }
    
    private struct CodableLocation: Codable {
        let latitude: Double
        let longitude: Double
        
        var local: Location {
            Location(latitude: latitude, longitude: longitude)
        }
    }
    
    private let queue = DispatchQueue(label: "\(CodableLocalPlace.self)Queue")
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard let data = try? Data(contentsOf: storeURL) else {
                return completion(.empty)
            }
            
            do {
                let decoder = JSONDecoder()
                let cache = try decoder.decode(Cache.self, from: data)
                completion(.found(places: cache.localPlaces, timestamp: cache.timestamp))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            do {
                let encoder = JSONEncoder()
                let cache = Cache(places: places.map(CodableLocalPlace.init), timestamp: timestamp)
                let encoded = try encoder.encode(cache)
                try encoded.write(to: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public
    func deleteCachedPlaces(completion: @escaping DeletionCompletion) {
        let storeURL = self.storeURL
        queue.async {
            guard FileManager.default.fileExists(atPath: storeURL.path) else {
                return completion(nil)
            }
            
            do {
                try FileManager.default.removeItem(at: storeURL)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
