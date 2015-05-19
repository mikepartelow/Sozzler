import Foundation
import CoreData

class CannedUnitSource {
    func read() -> [Unit] {
        let unitNames = [ "Tbsp", "tsp", "oz", "g", "dash", "ml" ]
        return map(unitNames) { Unit.create($0) }
    }
}