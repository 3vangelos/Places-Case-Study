import XCTest

class GooglePlacesLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared = HTTPClient()
    
    func get(from url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    override func get(from url: URL) {
        requestedURL = url
    }
    
    var requestedURL: URL?
}

class GooglePlacesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        _ = GooglePlacesLoader()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let client = HTTPClientSpy()
        HTTPClient.shared = client
        let sut = GooglePlacesLoader()
        
        sut.load()
        
        XCTAssertNotNil(client.requestedURL)
    }
    
}
