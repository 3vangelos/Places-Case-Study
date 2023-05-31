import XCTest
import Places

class CodablePlacesStore {
    func retrieve(completion: @escaping PlacesStore.RetrievalCompletion) {
        completion(.empty)
    }
}

class CodablePlacesStoreTests: XCTestCase {
    
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
    
    // Mark: Helpers
    
    func makeSUT() -> CodablePlacesStore {
        return CodablePlacesStore()
    }
}


