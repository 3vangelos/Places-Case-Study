import XCTest
import Places


class GooglePlacesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
    
    // MARK - Helpers
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: GooglePlacesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = GooglePlacesLoader(url: url, client: client)
        return (sut, client)
    }
    

}
