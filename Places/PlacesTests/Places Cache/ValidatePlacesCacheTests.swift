import XCTest
import Places

class ValidatePlacesCacheTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
        
    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieval(with: anyError)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_validateCache_deletesCacheOnExactExpirationTimestampOfCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: expectedPlaces.local, timestamp: expirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_validateCache_deletesCacheOnExpiredCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusPlacesCacheMaxAge().add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: expectedPlaces.local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_validateCache_doesNotDeliverResultAfterSUTHasBeenDeallocatde() {
        let store = PlacesStoreSpy()
        var sut: LocalPlacesLoader? = LocalPlacesLoader(store: store, currentDate: Date.init)
        let receivedResult = [LocalPlacesLoader.LoadResult]()
        
        sut?.validateCache()
        
        sut = nil
        store.completeRetrieval(with: anyError)
        
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
}
