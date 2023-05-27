import Foundation

public protocol PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion)
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalPlace: Equatable {
    public let id: String
    public let name: String
    public let category: String?
    public let imageUrl: URL?
    public let location: Location
    
    public init(id: String, name: String, category: String?, imageUrl: URL?, location: Location) {
        self.id = id
        self.name = name
        self.category = category
        self.imageUrl = imageUrl
        self.location = location
    }
}
