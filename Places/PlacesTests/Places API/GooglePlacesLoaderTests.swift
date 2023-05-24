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
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples =  [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                let json = makePlacesJSON([])
                client.complete(withStatusCode: code, data:json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("INVALID JSON".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversNoPlacesOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyJSON = makePlacesJSON([])
            client.complete(withStatusCode: 200, data: emptyJSON)
        })
    }
    
    func test_load_deliversNoPlacesOn200HTTPResponseWithJSONPlaces() {
        let (sut, client) = makeSUT()

        let place1Location = Location(latitude: 53.1, longitude: 13.3)
        let place1 = makePlace(id: UUID(), name: "A Name", location: place1Location)

        
        expect(sut, toCompleteWith: .success([place1.model]), when: {
            let json = makePlacesJSON([place1.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClientSpy()
        var sut: GooglePlacesLoader? = GooglePlacesLoader(url: url, client: client)
        
        var capturedResults = [GooglePlacesLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makePlacesJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: GooglePlacesLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = GooglePlacesLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(client)

        return (sut, client)
    }
    
    private func failure(_ error: GooglePlacesLoader.Error) -> GooglePlacesLoader.Result {
        .failure(error)
    }
     
    func makePlace(id: UUID, name: String, category: String? = nil, imageURL: URL? = nil, location: Location) -> (model: Place, json: [String: Any]) {
        let place = Place(id: id.uuidString,
                          name: name,
                          category: category,
                          imageUrl: imageURL,
                          location: location)
        let locationJSON = [
            "lat": location.latitude,
            "lng": location.longitude
        ]
        let json: [String: Any] = [
            "geometry": [
                "location": locationJSON
            ],
            "name": place.name,
            "place_id": place.id,
        ].compactMapValues { $0 }
        
        return (place, json)
    }
    
    func makePlacesJSON(_ places: [[String: Any]]) -> Data {
        let json =  [ "results": places]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func expect(_ sut: GooglePlacesLoader, toCompleteWith expectedResult: GooglePlacesLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load to completion")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedPlaces), .success(expectedPlaces)):
                XCTAssertEqual(receivedPlaces, expectedPlaces, file: file, line: line)

            case let (.failure(receivedError as GooglePlacesLoader.Error), .failure(expectedError as GooglePlacesLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected Result \(expectedResult), but received Result \(receivedResult)")
            }
            
            exp.fulfill()
        }
        
        action()
            
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: ((HTTPClientResult) -> Void))]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
