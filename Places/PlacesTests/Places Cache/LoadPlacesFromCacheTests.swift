import XCTest

class LocalPlacesLoader {
    let store: PlacesStore
    
    init(store: PlacesStore) {
        self.store = store
    }
}

class PlacesStore {
    var deleteCachedPlacesCount = 0
}

class LoadPlacesFromCacheTests: XCTestCase {
    
    func test_init_doesNotDeleteCacheUponCreation() {
        let store = PlacesStore()
        _ = LocalPlacesLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedPlacesCount, 0)
    }
}
