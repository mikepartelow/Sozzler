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
    
    class func all(entityName: String) -> [NSManagedObject] {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        // FIXME: error handling
        if let results = moc.executeFetchRequest(fetchRequest, error: nil) {
            return results as! [NSManagedObject]
        }
        
        return []
    }
    
    class func create(entityName: String,
        initializer: (entity: NSEntityDescription, context: NSManagedObjectContext) -> NSManagedObject) -> NSManagedObject {
            let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

            var obj: NSManagedObject?
            if let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: moc) {
                obj = initializer(entity: entity, context: moc)
            }
            
            return obj!
    }

    class func save(error: NSErrorPointer) -> Bool {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        return moc.save(error)
    }
    
    class func rollback() {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        moc.rollback()
    }
    
    class func delete(obj: NSManagedObject) {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        moc.deleteObject(obj)
    }
    
    class func fetchedResultsController(fetchRequest: NSFetchRequest, sectionNameKeyPath: String? = nil) -> NSFetchedResultsController {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
    }
    
    class func factoryReset(save: Bool=true) {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        map(CoreDataHelper.all("Component"), { moc.deleteObject($0) })
        map(CoreDataHelper.all("Unit"), { moc.deleteObject($0) })
        map(CoreDataHelper.all("Ingredient"), { moc.deleteObject($0) })
        map(CoreDataHelper.all("Recipe"), { moc.deleteObject($0) })

        if save {
            // FIXME: handle errors
            var error: NSError?
            CoreDataHelper.save(&error)
            NSLog("\(error)")
            NSLog("recipe count: \(Recipe.count())")
            assert(error == nil)
        }
    }
}