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

        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_load_deliversErrorOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeWithEmptyCache()
        }
    }
    
    func test_load_deliversPlacesOnNonCacheExpirationTimestamp() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge().add(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(expectedPlaces.models)) {
            store.completeRetrieval(with: expectedPlaces.local, timestamp: nonExpiredTimestamp)
        }
    }
    
    func test_load_deliversNoPlacesOnExactCacheExpiration() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: expectedPlaces.local, timestamp: expirationTimestamp)
        }
    }
    
    func test_load_deliversNoPlacesOnExpiredCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge().add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: expectedPlaces.local, timestamp: expiredTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyError)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_dontDeleteTheCacheWhenCacheIsAlreadyEmpty() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeleteValidCacheWhenCacheIsValid() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge().add(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsWhenCacheHasExactExpirationTimestamp() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsWhenCacheHasExpired() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge().add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeliverResultAfterSUTHasBeenDeallocatde() {
        let store = PlacesStoreSpy()
        var sut: LocalPlacesLoader? = LocalPlacesLoader(store: store, currentDate: Date.init)
        var receivedResult = [LocalPlacesLoader.LoadResult]()
        
        sut?.load(completion: {
            receivedResult.append($0)
        })
        
        sut = nil
        store.completeWithEmptyCache()
        
        XCTAssertTrue(receivedResult.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalPlacesLoader, store: PlacesStoreSpy) {
        let store = PlacesStoreSpy()
        let sut = LocalPlacesLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
        
    private func expect(_ sut: LocalPlacesLoader, toCompleteWith expectedResult: LocalPlacesLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedPlaces), .success(expectedPlaces)):
                XCTAssertEqual(receivedPlaces, expectedPlaces, file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError.code, expectedError.code, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), but got \(receivedResult)")
            }
            
            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }
}

extension Date {
    func minusPlacesCacheMaxAge() -> Date {
        add(days: -maxCacheAgeInDays)
    }
    
    private var maxCacheAgeInDays : Int{
        return 1
    }
    
    private func add(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func add(seconds: Double) -> Date {
        return self.addingTimeInterval(seconds)
    }
}
