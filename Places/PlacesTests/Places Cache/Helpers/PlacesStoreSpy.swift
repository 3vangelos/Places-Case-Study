import Foundation
import Places

class PlacesStoreSpy: PlacesStore {
    enum ReceivedMessage: Equatable {
        case deleteCachedPlaces
        case insert([LocalPlace], Date)
        case retrieve
    }
    
    private var insertionCompletions = [InsertionCompletion]()
    private var deletionCompletions = [DeletionCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    
    func insert(_ places: [LocalPlace], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(places, timestamp))
    }
    
    func deleteCachedPlaces(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedPlaces)
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve() {
        receivedMessages.append(.retrieve)
    }
}
