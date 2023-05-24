import Foundation

public struct Place: Equatable {    
    let id: String
    let name: String
    let category: String?
    let imageUrl: URL?
    let location: Location
}
