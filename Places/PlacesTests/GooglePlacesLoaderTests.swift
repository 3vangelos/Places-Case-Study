import XCTest
import Places


class GooglePlacesLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var capturedError = [GooglePlacesLoader.Error]()
        sut.load { capturedError.append($0) }
    
        let clientError = NSError(domain: "Test", code: 0)
        client.completions[0](clientError)

        XCTAssertEqual(capturedError, [.connectivity])
    }
    
    // MARK - Helpers
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var completions = [((Error) -> Void)]()
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            completions.append(completion)
            requestedURLs.append(url)
        }
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: GooglePlacesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = GooglePlacesLoader(url: url, client: client)
        return (sut, client)
    }
    

}
