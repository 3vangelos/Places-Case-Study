import Foundation

public protocol PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion)
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve()
}
