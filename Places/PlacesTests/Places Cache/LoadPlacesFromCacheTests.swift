import XCTest
import Places

class LocalPlacesLoader {
    let store: PlacesStore
    
    init(store: PlacesStore) {
        self.store = store
    }
    
    func save(_ places: [Place]) {
        store.deleteCachedPlaces()
    }
}

class PlacesStore {
    var deleteCachedPlacesCount = 0
    var insertCallCountProperty = 0
    
    func deleteCachedPlaces() {
        deleteCachedPlacesCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        
    }
}

class LoadPlacesFromCacheTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCachedPlacesCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        
        sut.save(places)
        
        XCTAssertEqual(store.deleteCachedPlacesCount, 1)
    }
    
    func test_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let places = [uniquePlace(), uniquePlace()]
        let deletionError = anyError
        
        sut.save(places)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCountProperty, 0)
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
