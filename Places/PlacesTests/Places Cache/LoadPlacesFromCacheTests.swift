import XCTest
import Places

class LocalPlacesLoader {
    private let store: PlacesStore
    private let currentDate: () -> Date
    
    init(store: PlacesStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ places: [Place]) {
        store.deleteCachedPlaces { [unowned self] error in
            if error == nil {
                store.insert(places, timestamp: currentDate())
            }
        }
    }
}

class PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedPlaces
        case insert([Place], Date)
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    
    func insert(_ places: [Place], timestamp: Date) {
        receivedMessages.append(.insert(places, timestamp))
    }
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion ) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedPlaces)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
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
        
        sut.save(places)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        
        sut.save(places)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces])
    }
    
    func test_save_requestsCacheInsertionWithTimestmpOnDeletionSuccess() {
        let timestamp = Date()
        let places = [uniquePlace(), uniquePlace()]
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(places)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedPlaces, .insert(places, timestamp)])
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
    
    private var anyError: Error {
        NSError(domain: "Any Error", code: 1)
    }
}
