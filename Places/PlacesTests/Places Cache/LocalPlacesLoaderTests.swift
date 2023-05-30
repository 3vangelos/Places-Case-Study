import XCTest
import Places

class LocalPlacesLoaderTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(uniquePlaces().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        sut.save(uniquePlaces().models) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_requestsCacheInsertionWithTimestmpOnDeletionSuccess() {
        let timestamp = Date()
        let places = uniquePlaces()
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(places.models) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces, .insert(places.localRepresentation, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyError
        
        expect(sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyError
        
        expect(sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    func test_save_SucceedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDealocated() {
        let store = PlacesStoreSpy()
        var sut: LocalPlacesLoader? = LocalPlacesLoader(store: store, currentDate: Date.init)
        var receivedErrors = [LocalPlacesLoader.SaveResult?]()
        
        sut?.save(uniquePlaces().models) { error in
            receivedErrors.append(error)
        }
        sut = nil
        store.completeDeletion(with: anyError)
        
        XCTAssertTrue(receivedErrors.isEmpty)
    }
    
    func test_save_doesNotDeliverInsertaionErrorAfterSUTInstanceHasBeenDealocated() {
        let store = PlacesStoreSpy()
        var sut: LocalPlacesLoader? = LocalPlacesLoader(store: store, currentDate: Date.init)
        var receivedErrors = [LocalPlacesLoader.SaveResult?]()
        
        sut?.save(uniquePlaces().models) { error in
            receivedErrors.append(error)
        }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyError)
        
        XCTAssertTrue(receivedErrors.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalPlacesLoader, store: PlacesStoreSpy) {
        let store = PlacesStoreSpy()
        let sut = LocalPlacesLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalPlacesLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var receivedError: LocalPlacesLoader.SaveResult?

        let exp = expectation(description: "Wait for load to completion")
        sut.save(uniquePlaces().models) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
            
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
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
    
    
    private var anyError: NSError {
        NSError(domain: "Any Error", code: 1)
    }
}
