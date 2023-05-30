import Foundation

public final class LocalPlacesLoader {
    public typealias SaveResult = Error
    public typealias LoadResult = LoadPlacesResult
    
    private let store: PlacesStore
    private let currentDate: () -> Date
    private lazy var calendar = Calendar(identifier: .gregorian)

    
    public init(store: PlacesStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func load(completion: @escaping (LoadPlacesResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .found(places, timestamp) where self.validate(timestamp):
                completion(.success(places.toModels()))
                
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .failure:
                store.deleteCachedPlaces(completion: { _ in })
                
            case let .found(_, timestamp) where !self.validate(timestamp):
                store.deleteCachedPlaces(completion: { _ in })
                
            case .empty, .found:
                break
            }
        }
    }

    public func save(_ places: [Place], completion: @escaping (SaveResult?) -> Void) {
        store.deleteCachedPlaces { [weak self] error in
            guard let self else { return }
            
            if let error {
                completion(error)
            } else {
                self.cache(places, with: completion)
            }
        }
    }
    
    private func cache(_ places: [Place], with completion: @escaping (SaveResult?) -> Void) {
        store.insert(places.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
    
    private var maxCacheAgeInDays: Int {
        return 1
    }
    
    private func validate(_ timestamp: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else {
            return false
        }
        
        return currentDate() < maxCacheAge
    }
}

private extension Array where Element == Place {
    func toLocal() -> [LocalPlace] {
        self.map{ LocalPlace(id: $0.id,
                             name: $0.name,
                             category: $0.category,
                             imageUrl: $0.imageUrl,
                             location: $0.location) }
    }
}

private extension Array where Element == LocalPlace {
    func toModels() -> [Place] {
        self.map{ Places.Place(id: $0.id,
                               name: $0.name,
                               category: $0.category,
                               imageUrl: $0.imageUrl,
                               location: $0.location) }
    }
}

