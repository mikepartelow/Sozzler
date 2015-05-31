import Foundation
import CoreData

class CannedUnitSource {
    func read() -> [Unit] {
        let unitNames = [ "", "Tbsp", "tsp", "oz", "g", "dash", "ml" ]
        return map(enumerate(unitNames), { (index, name) in
            Unit.create(name, index: index)
        })
    }
}