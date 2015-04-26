import CoreData
import UIKit

class CoreDataHelper {
    class func count(entityName: String, predicate: NSPredicate?) -> Int {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        
        // FIXME: error handling
        let fetchedResults = moc.executeFetchRequest(fetchRequest, error: nil)
        
        if let results = fetchedResults {
            return results.count
        }
        
        return 0
    }

    class func find(entityName: String, predicate: NSPredicate) -> NSManagedObject? {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        var obj: NSManagedObject?
            
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
            
        // FIXME: error handling
        if let results = moc.executeFetchRequest(fetchRequest, error: nil) {
            if results.count == 1 {
                obj = (results[0] as! NSManagedObject)
            } else if results.count > 1 {
                // FIXME: do something
                NSLog("more than one result in CoreDataHelper.find(\(entityName))")
            }
        }
        return obj
    }

    class func create(entityName: String,
        initializer: (entity: NSEntityDescription, context: NSManagedObjectContext) -> NSManagedObject) -> NSManagedObject {
            let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

            var obj: NSManagedObject?
            
            // FIXME: figure out how to pass a correctly typed object so we don't have to pass the moc
            //        this is where we should insert into moc, not in each NSMO ctor
            if let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: moc) {
                obj = initializer(entity: entity, context: moc)
            }
            
            return obj!
    }

    class func save(error: NSErrorPointer) -> Bool {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        return moc.save(error)
    }
    
    class func delete(obj: NSManagedObject) {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        moc.deleteObject(obj)
    }
    
    class func fetchedResultsController(fetchRequest: NSFetchRequest) -> NSFetchedResultsController {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }
}