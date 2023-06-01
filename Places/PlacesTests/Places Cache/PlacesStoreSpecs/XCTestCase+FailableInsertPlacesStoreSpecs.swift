import XCTest
import Places

extension FailableInsertPlacesStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: PlacesStore, file: StaticString = #file, line: UInt = #line) {
         let insertionError = insert((uniquePlaces().local, Date()), to: sut)

         XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
     }

     func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: PlacesStore, file: StaticString = #file, line: UInt = #line) {
         insert((uniquePlaces().local, Date()), to: sut)

         expect(sut, toRetrieve: .empty, file: file, line: line)
     }
}
