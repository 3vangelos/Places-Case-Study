import XCTest
import Places

class CodablePlacesStore {
    private struct Cache: Codable {
        let places: [LocalPlace]
        let timestamp: Date
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("places.store")
    
    func retrieve(completion: @escaping PlacesStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(places: cache.places, timestamp: cache.timestamp))
    }
    
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping PlacesStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(places: places, timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodablePlacesStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("places.store")
        try? FileManager.default.removeItem(at: storeURL)
        
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for Retrieval")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for Retrieval")
        
        sut.retrieve { resultFirst in
            sut.retrieve { resultSecond in
                switch (resultFirst, resultSecond) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected empty result, got \(resultFirst) and \(resultSecond) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingIntoEmptyCache_deliversEmptyValue() {
        let sut = makeSUT()
        let places = uniquePlaces().localRepresentation
        let timestamp = Date()
        let exp = expectation(description: "Wait for Cache Retrieval")
        
        sut.insert(places, timestamp: timestamp) { error in
            XCTAssertNil(error, "Expected Places to be inserted successfully")
            
            sut.retrieve { result in
                switch (result) {
                case let .found(retrievedPlaces, retrievedTimestamp):
                    XCTAssertEqual(retrievedPlaces, places)
                    XCTAssertEqual(retrievedTimestamp, timestamp)
                default:
                    XCTFail("Expected empty result, got \(error) and \(result) instead")
                }
                
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
    // Mark: Helpers
    
    func makeSUT() -> CodablePlacesStore {
        return CodablePlacesStore()
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


