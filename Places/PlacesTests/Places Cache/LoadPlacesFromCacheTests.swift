import XCTest
import Places

class LoadPlacesFromCacheTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load() { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyError
        
        let exp = expectation(description: "Wait for load completion")
        
        var receivedError: Error?
        sut.load() { result in
            switch result {
            case let .failure(error):
                receivedError = error
            default:
                XCTFail("Expected Error but got \(result)")
            }
            exp.fulfill()
        }
        store.completeRetrieval(with: retrievalError)
            
        wait(for: [exp], timeout: 1.0)
    
        XCTAssertEqual(receivedError as NSError?, retrievalError as NSError)
    }
    
    func test_load_deliversErrorOnEmptyCache() {
        let (sut, store) = makeSUT()

        let exp = expectation(description: "Wait for load completion")

        var receivedPlaces: [Place]?
        sut.load() { result in
            switch result {
            case let .success(places):
                receivedPlaces = places
            default:
                XCTFail("Expected Places, but got \(result)")
                
            }
            exp.fulfill()
        }
        
        store.completeWithEmptyCache()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedPlaces, [])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalPlacesLoader, store: PlacesStoreSpy) {
        let store = PlacesStoreSpy()
        let sut = LocalPlacesLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private var anyError: Error {
        NSError(domain: "Any Error", code: 1)
    }
    
    
    private func expect(_ sut: LocalPlacesLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        var receivedError: Error?

        sut.load() { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
            
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
        
    }
}
