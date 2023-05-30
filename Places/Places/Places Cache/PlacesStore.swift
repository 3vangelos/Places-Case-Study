import Foundation

public enum RetrievedCachedPlacesResult {
    case empty
    case found(places: [LocalPlace], timestamp: Date)
    case failure(Error)
}

public protocol PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrievalCompletion = (RetrievedCachedPlacesResult) -> Void
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion)
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrievalCompletion)
}
