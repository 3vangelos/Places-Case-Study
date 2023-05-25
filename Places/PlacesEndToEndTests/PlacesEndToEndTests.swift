import XCTest
import Places

final class PlacesEndToEndTests: XCTestCase {
    
    func test_endToEndTestServerGetPlacesResult_matchesFixedTestAccountData() {
        switch getPlacesResult() {
        case let .success(places)?:
            XCTAssertEqual(places.count, 20)
            
            
        case let .failure(error)?:
            XCTFail("Expected successful places result, got no \(error) instead")
        default:
            XCTFail("Expected successful places result, got no result instead")
        }
    }
    
    // MARK - Helpers

    func getPlacesResult(file: StaticString = #filePath, line: UInt = #line) -> LoadPlacesResult? {
        let urlString = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=coffee&location=\(13.4050)%2C-\(52.52)&radius=500&key="
        let apiKey = "ENTER YOUR API KEY HERE"
        let url = URL(string: urlString + apiKey)!
        let client = URLSessionHTTPClient()
        let loader = GooglePlacesLoader(url: url, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        let exp = expectation(description: "Waiting for Places to Load...")
        
        var receivedResult: LoadPlacesResult?
        loader.load { result in
            receivedResult = result
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 15.0)
        return receivedResult
    }
}




