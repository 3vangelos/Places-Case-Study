import XCTest

class GooglePlacesLoader {
    
}

class HTTPClient {
    var requestedURL: URL?
}

class GooglePlacesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        _ = GooglePlacesLoader()
        
        XCTAssertNil(client.requestedURL)
    }
    
}
