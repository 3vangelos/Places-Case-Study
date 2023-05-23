import Foundation

typealias LoadPlacesResult = Result<[Place], Error>

protocol PlacesLoader {
    func load(completion: @escaping (LoadPlacesResult) -> Void)
}
