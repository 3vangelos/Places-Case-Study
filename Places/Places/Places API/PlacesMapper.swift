import Foundation

internal class PlacesMapper {
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [GooglePlace] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw GooglePlacesLoader.Error.invalidData
        }
        
        return root.results
    }
}

private extension PlacesMapper {
    private struct Root: Decodable {
        let results: [GooglePlace]
    }
}
