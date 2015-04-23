import Foundation
import CoreData

@objc(Unit)
class Unit: NSManagedObject {

    @NSManaged var name: String

    class func create(name: String, context: NSManagedObjectContext) -> Unit {
        return CoreDataHelper.create("Unit", context: context, initializer: {
            (entity, context) -> NSManagedObject in
                let unit = Unit(entity: entity, insertIntoManagedObjectContext: context)
                unit.name = name
                return unit
            }
        ) as! Unit
    }

}
