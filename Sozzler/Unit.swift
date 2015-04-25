import CoreData
import UIKit

@objc(Unit)
class Unit: NSManagedObject {

    @NSManaged var name: String

    class func fetchRequest() -> NSFetchRequest {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: "Unit")
        let sortByName = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [sortByName]
        
        return fetchRequest
    }

    class func find(name: String, context: NSManagedObjectContext) -> Unit? {
        let predicate = NSPredicate(format: "name == %@", name)
        return CoreDataHelper.find("Unit", predicate: predicate, context: context) as! Unit?
    }
    
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
