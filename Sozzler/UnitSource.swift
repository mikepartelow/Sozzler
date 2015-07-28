import Foundation
import CoreData

class CannedUnitSource {
    let unitNames = [ "", "Tbsp", "tsp", "oz", "g", "dash", "ml" ]
    static let unitPluralizations = [
        "dash"      : "dashes"
    ]
    
    func read() -> [Unit] {
        return map(enumerate(unitNames), { (index, name) in
            let pluralName = CannedUnitSource.unitPluralizations[name] ?? name
            return Unit.create(name, plural_name: pluralName, index: index)
        })
    }
}