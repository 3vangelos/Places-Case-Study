import Foundation

public typealias LoadPlacesResult = Result<[Place], Error>

public protocol PlacesLoader {
    func load(completion: @escaping (LoadPlacesResult) -> Void)
}
