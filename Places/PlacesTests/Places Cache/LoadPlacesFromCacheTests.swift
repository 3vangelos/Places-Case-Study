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
    
    func test_load_deliversPlacesOnLessThanOneDayCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let lessThanOneDayOldTimeStamp = fixedCurrentDate.add(days: -1).add(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(expectedPlaces.models)) {
            store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: lessThanOneDayOldTimeStamp)
        }
    }
    
    func test_load_deliversNoPlacesOnOneDayOldCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let oneDayOldTimeStamp = fixedCurrentDate.add(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: oneDayOldTimeStamp)
        }
    }
    
    func test_load_deliversNoPlacesOnMoreThanOneDayOldCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let moreThanOneDayOldTimeStamp = fixedCurrentDate.add(days: -1).add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: moreThanOneDayOldTimeStamp)
        }
    }
    
    func test_load_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyError)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_load_dontDeleteTheCacheWhenCacheIsAlreadyEmpty() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeleteValidCacheWhenCacheIsLessThanOneDayOld() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let lessThanOneDayOldTimeStamp = fixedCurrentDate.add(days: -1).add(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: lessThanOneDayOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_shouldDeleteExpiredCacheWhenCacheOneDayOld() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let oneDayOldTimeStamp = fixedCurrentDate.add(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: oneDayOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_load_shouldDeleteExpiredCacheWhenCacheMoreThanOneDayOld() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let oneDayOldTimeStamp = fixedCurrentDate.add(days: -1).add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: oneDayOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
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
    
    private var anyError: Error {
        NSError(domain: "Any Error", code: 1)
    }
    
    private func uniquePlace() -> Place {
        Place(id: UUID().uuidString,
              name: "Any NAme",
              category: nil,
              imageUrl: nil,
              location: Location(latitude: 1,
                                 longitude: 1))
    }
    
    private func uniquePlaces() -> (models: [Place], localRepresentation: [LocalPlace]) {
        let models = [uniquePlace(), uniquePlace()]
        let localRepresentation = models.map { place in
            LocalPlace(id: place.id,
                       name: place.name,
                       category: place.category,
                       imageUrl: place.imageUrl,
                       location: place.location)
        }
        
        return (models, localRepresentation)
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

private extension Date {
    func add(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func add(seconds: Double) -> Date {
        return self.addingTimeInterval(seconds)
    }
}
