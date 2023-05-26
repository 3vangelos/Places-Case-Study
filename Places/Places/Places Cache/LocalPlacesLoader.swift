import Foundation

public final class LocalPlacesLoader {
    public typealias SaveResult = Error
    
    private let store: PlacesStore
    private let currentDate: () -> Date
    
    public init(store: PlacesStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
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
        store.insert(places, timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            
            completion(error)
        }
    }
}
