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

    class func find(name: String) -> Unit? {
        let predicate = NSPredicate(format: "name == %@", name)
        return CoreDataHelper.find("Unit", predicate: predicate) as! Unit?
    }
    
    class func create(name: String) -> Unit {
        return CoreDataHelper.create("Unit", initializer: {
            (entity, context) -> NSManagedObject in
                let unit = Unit(entity: entity, insertIntoManagedObjectContext: context)
                unit.name = name
                return unit
            }
        ) as! Unit
    }
}
