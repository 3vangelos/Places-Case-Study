import Foundation

 protocol PlacesStoreSpecs {
     func test_retrieve_deliversEmptyOnEmptyCache()
     func test_retrieve_hasNoSideEffectsOnEmptyCache()
     func test_retrieve_deliversFoundValuesOnNonEmptyCache()
     func test_retrieve_hasNoSideEffectsOnNonEmptyCache()

     func test_insert_deliversNoErrorOnEmptyCache()
     func test_insert_deliversNoErrorOnNonEmptyCache()
     func test_insert_overridesPreviouslyInsertedCacheValues()

     func test_delete_deliversNoErrorOnEmptyCache()
     func test_delete_hasNoSideEffectsOnEmptyCache()
     func test_delete_deliversNoErrorOnNonEmptyCache()
     func test_delete_emptiesPreviouslyInsertedCache()

     func test_storeSideEffects_runSerially()
 }

 protocol FailableRetrievePlacesStoreSpecs: PlacesStoreSpecs {
     func test_retrieve_deliversFailureOnRetrievalError()
     func test_retrieve_hasNoSideEffectsOnFailure()
 }

 protocol FailableInsertPlacesStoreSpecs: PlacesStoreSpecs {
     func test_insert_deliversErrorOnInsertionError()
     func test_insert_hasNoSideEffectsOnInsertionError()
 }

 protocol FailableDeletePlacesStoreSpecs: PlacesStoreSpecs {
     func test_delete_deliversErrorOnDeletionError()
     func test_delete_hasNoSideEffectsOnDeletionError()
 }

 typealias FailablePlacesStoreSpecs = FailableRetrievePlacesStoreSpecs & FailableInsertPlacesStoreSpecs & FailableDeletePlacesStoreSpecs
