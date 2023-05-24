import Foundation

public struct Place: Equatable {
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
