import Foundation
import Places

var anyError: Error {
    NSError(domain: "Any Error", code: 1)
}

func uniquePlace() -> Place {
    Place(id: UUID().uuidString,
          name: "Any NAme",
          category: nil,
          imageUrl: nil,
          location: Location(latitude: 1,
                             longitude: 1))
}

func uniquePlaces() -> (models: [Place], local: [LocalPlace]) {
    let models = [uniquePlace(), uniquePlace()]
    let local = models.map { place in
        LocalPlace(id: place.id,
                   name: place.name,
                   category: place.category,
                   imageUrl: place.imageUrl,
                   location: place.location)
    }
    
    return (models, local)
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        return adding(days: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        return 7
    }
    
    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
