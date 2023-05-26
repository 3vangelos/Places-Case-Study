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
    var deletionCompletions = [DeletionCompletion]()
    var insertions = [(places: [Place], timestamp: Date)]()
    
    
    func insert(_ places: [Place], timestamp: Date) {
        insertions.append((places, timestamp))
    }
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion ) {
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
}

class LoadPlacesFromCacheTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deletionCompletions.count, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        
        sut.save(places)
        
        XCTAssertEqual(store.deletionCompletions.count, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        
        sut.save(places)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertions.count, 0)
    }
    
    func test_save_requestsCacheInsertionOnDeletionSuccess() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        
        sut.save(places)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.deletionCompletions.count, 1)
        XCTAssertEqual(store.insertions.count, 1)
    }
    
    func test_save_requestsCacheInsertionWithTimestmpOnDeletionSuccess() {
        let timestamp = Date()
        let places = [uniquePlace(), uniquePlace()]
        let (sut, store) = makeSUT { timestamp }
        
        sut.save(places)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertions.first?.places, places)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)

        XCTAssertEqual(store.deletionCompletions.count, 1)
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
