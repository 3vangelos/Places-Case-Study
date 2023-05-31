import XCTest
import Places

class CodablePlacesStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        setupEmptyStoreState()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversfailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyError))
    }
    
    func test_retrieve_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: false, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyError))
    }
    
    func test_insert_overridesPreviouslyInsertedCache() {
        let storeURL = testSpecificStoreURL
        let sut = makeSUT(storeURL: storeURL)
        let firstPlaces = uniquePlaces().localRepresentation
        let firstTimestamp = Date()
        
        let firstInsertionError = insert((places: firstPlaces, timestamp: firstTimestamp), to: sut)
        XCTAssertNil(firstInsertionError, "Did expect successful cache insertion")
        
        let secondPlaces = uniquePlaces().localRepresentation
        let secondTimestamp = Date()
        let secondInsertionError = insert((places: secondPlaces, timestamp: secondTimestamp), to: sut)
        XCTAssertNil(secondInsertionError, "Did expect to override cache successfully")

        expect(sut, toRetrieve: .found(places: secondPlaces, timestamp: secondTimestamp))
    }
    
    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid://store-url")
        let sut = makeSUT(storeURL: invalidStoreURL)
        
        let places = uniquePlaces().localRepresentation
        let timestamp = Date()
        
        let insertionError = insert((places: places, timestamp: timestamp), to: sut)
        XCTAssertNotNil(insertionError, "Did expect successful cache insertion")
    }
    
    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()
        insert((uniquePlaces().localRepresentation, Date()), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory
        let sut = makeSUT(storeURL: noDeletePermissionURL)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let places = uniquePlaces().localRepresentation
        let timestamp = Date()
        
        insert((places: places, timestamp: timestamp), to: sut)
        
        expect(sut, toRetrieve: .found(places: places, timestamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let places = uniquePlaces().localRepresentation
        let timestamp = Date()

        insert((places: places, timestamp: timestamp), to: sut)
        
        expect(sut, toRetrieveTwice: .found(places: places, timestamp: timestamp))
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(uniquePlaces().localRepresentation, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedPlaces { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(uniquePlaces().localRepresentation, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side effects to run serially but operations finished in wrong order")
    }
    
    
    // Mark: Helpers
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> PlacesStore {
        let sut = CodablePlacesStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    func insert(_ cache: (places: [LocalPlace], timestamp: Date), to sut: PlacesStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        var receivedError: Error?
        
        let exp = expectation(description: "Wait for Cache Insertion")
        
        sut.insert(cache.places, timestamp: cache.timestamp) { insertionError in
            receivedError = insertionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    private func deleteCache(from sut: PlacesStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedPlaces { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    func expect(_ sut: PlacesStore, toRetrieve expectedResult: RetrievedCachedPlacesResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for Retrieval")
        
        sut.retrieve { receivedResult in
            switch (expectedResult, receivedResult) {
            case (.empty, .empty),
                 (.failure, .failure):
                break
                
            case let (.found(expectedPlaces, expectedTimestamp), .found(retrievedPlaces, retrievedTimestamp)):
                XCTAssertEqual(retrievedPlaces, expectedPlaces, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
                
            default:
                XCTFail("Expected to receive \(expectedResult), but got \(receivedResult)", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(_ sut: PlacesStore, toRetrieveTwice expectedResult: RetrievedCachedPlacesResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }
          
    private var anyError: Error {
        NSError(domain: "Any Error", code: 1)
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
    
    private func setupEmptyStoreState() {
        deleteStoreArtefacts()
    }
    
    private func undoStoreSideEffect() {
        deleteStoreArtefacts()
    }
    
    private var testSpecificStoreURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }
    
    private func deleteStoreArtefacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}


