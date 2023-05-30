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
    
    func test_validateCache_DeletesOneDayOldCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let oneDayOldTimeStamp = fixedCurrentDate.add(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: oneDayOldTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_validateCache_deletesMoreThanOneDayOldCache() {
        let expectedPlaces = uniquePlaces()
        let fixedCurrentDate = Date()
        let moreThanOneDayOldTimestamp = fixedCurrentDate.add(days: -1).add(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: expectedPlaces.localRepresentation, timestamp: moreThanOneDayOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedPlaces])
    }
    
    func test_validateCache_doesNotDeliverResultAfterSUTHasBeenDeallocatde() {
        let store = PlacesStoreSpy()
        var sut: LocalPlacesLoader? = LocalPlacesLoader(store: store, currentDate: Date.init)
        var receivedResult = [LocalPlacesLoader.LoadResult]()
        
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
}
