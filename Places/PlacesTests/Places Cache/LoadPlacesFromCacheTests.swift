import XCTest
import Places

class LocalPlacesLoader {
    let store: PlacesStore
    
    init(store: PlacesStore) {
        self.store = store
    }
    
    func save(_ places: [Place]) {
        store.deleteCachedPlaces { [unowned self] error in
            if error == nil {
                store.insertPlaces(places)
            }
        }
    }
}

class PlacesStore {
    typealias DeletionCompletion = (Error?) -> Void

    var insertCallCount = 0
    var deletionCompletions = [DeletionCompletion]()
    
    
    func insertPlaces(_ places: [Place]) {
        insertCallCount += 1
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
    
    func test_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        
        sut.save(places)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_requestsCacheInsertionOnDeletionSuccess() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        
        sut.save(places)
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.deletionCompletions.count, 1)
    }

    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalPlacesLoader, store: PlacesStore) {
        let store = PlacesStore()
        let sut = LocalPlacesLoader(store: store)
        
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
