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
    
    func deleteCachedPlaces() {
        deleteCachedPlacesCount += 1
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
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: LocalPlacesLoader, store: PlacesStore) {
        let store = PlacesStore()
        let sut = LocalPlacesLoader(store: store)
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
}
