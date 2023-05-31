import XCTest
import Places

class CodablePlacesStore {
    private struct Cache: Codable {
        let places: [CodableLocalPlace]
        let timestamp: Date
        
        var localPlaces: [LocalPlace] {
            self.places.map {
                $0.local
            }
        }
    }
    
    private struct CodableLocalPlace: Codable {
        private let id: String
        private let name: String
        private let category: String?
        private let imageUrl: URL?
        private let location: CodableLocation
        
        var local: LocalPlace {
            LocalPlace(id: id, name: name, category: category, imageUrl: imageUrl, location: location.local)
        }
        
        init(_ localPlace: LocalPlace) {
            id = localPlace.id
            name = localPlace.name
            category = localPlace.category
            imageUrl = localPlace.imageUrl
            location = CodableLocation(latitude: localPlace.location.latitude, longitude: localPlace.location.longitude)
        }
    }
    
    private struct CodableLocation: Codable {
        let latitude: Double
        let longitude: Double
        
        var local: Location {
            Location(latitude: latitude, longitude: longitude)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping PlacesStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(places: cache.localPlaces, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping PlacesStore.InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(places: places.map(CodableLocalPlace.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

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
    
    
    // Mark: Helpers
    
    func makeSUT(storeURL: URL? = nil, file: StaticString = #file, line: UInt = #line) -> CodablePlacesStore {
        let sut = CodablePlacesStore(storeURL: storeURL ?? testSpecificStoreURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    func insert(_ cache: (places: [LocalPlace], timestamp: Date), to sut: CodablePlacesStore, file: StaticString = #file, line: UInt = #line) -> Error? {
        var receivedError: Error?
        
        let exp = expectation(description: "Wait for Cache Insertion")
        
        sut.insert(cache.places, timestamp: cache.timestamp) { insertionError in
            receivedError = insertionError
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }
    
    func expect(_ sut: CodablePlacesStore, toRetrieve expectedResult: RetrievedCachedPlacesResult, file: StaticString = #file, line: UInt = #line) {
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
    
    func expect(_ sut: CodablePlacesStore, toRetrieveTwice expectedResult: RetrievedCachedPlacesResult, file: StaticString = #file, line: UInt = #line) {
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
    
    private func deleteStoreArtefacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL)
    }
}


