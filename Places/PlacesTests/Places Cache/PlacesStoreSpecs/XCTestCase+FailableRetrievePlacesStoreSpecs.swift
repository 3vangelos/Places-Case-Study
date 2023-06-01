import XCTest
 import Places

 extension FailableRetrievePlacesStoreSpecs where Self: XCTestCase {
     func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: PlacesStore, file: StaticString = #file, line: UInt = #line) {
          expect(sut, toRetrieve: .failure(anyError), file: file, line: line)
      }

      func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: PlacesStore, file: StaticString = #file, line: UInt = #line) {
          expect(sut, toRetrieveTwice: .failure(anyError), file: file, line: line)
      }
 }
