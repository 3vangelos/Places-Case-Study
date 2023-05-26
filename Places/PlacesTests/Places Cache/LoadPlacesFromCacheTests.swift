import XCTest
import Places

class LocalPlacesLoader {
    private let store: PlacesStore
    private let currentDate: () -> Date
    
    init(store: PlacesStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ places: [Place], completion: @escaping (Error?) -> Void) {
        store.deleteCachedPlaces { [unowned self] error in
            if let error {
                completion(error)
            } else {
                store.insert(places, timestamp: currentDate(), completion: completion)
            }
        }
    }
}

class PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedPlaces
        case insert([Place], Date)
    }
    
    private var insertionCompletions = [DeletionCompletion]()
    private var deletionCompletions = [InsertionCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    
    func insert(_ places: [Place], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(places, timestamp))
    }
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedPlaces)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

class LoadPlacesFromCacheTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        
        sut.save(places) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        
        sut.save(places) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_requestsCacheInsertionWithTimestmpOnDeletionSuccess() {
        let timestamp = Date()
        let places = [uniquePlace(), uniquePlace()]
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(places) { _ in }
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces, .insert(places, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let insertionError = anyError
        var receivedError: Error?
        
        let exp = expectation(description: "Waiting for Completion")
        sut.save(places) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletionSuccessfully()
        store.completeInsertion(with: insertionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, insertionError)
    }
    
    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        var receivedError: Error?
        
        let exp = expectation(description: "Waiting for Completion")
        sut.save(places) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError as NSError?, deletionError)
    }
    
    func test_save_SucceedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        var receivedError: Error?
        
        let exp = expectation(description: "Waiting for Completion")
        sut.save(places) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDeletionSuccessfully()
        store.completeInsertionSuccessfully()
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertNil(receivedError)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalPlacesLoader, store: PlacesStore) {
        let store = PlacesStore()
        let sut = LocalPlacesLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func uniquePlace() -> Place {
        Place(id: UUID().uuidString,
              name: "Any NAme",
              category: nil,
              imageUrl: nil,
              location: Location(latitude: 1,
                                 longitude: 1))
    }
    
    private var anyError: NSError {
        NSError(domain: "Any Error", code: 1)
    }
}
