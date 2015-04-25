import CoreData

class CoreDataHelper {
    class func count(entityName: String, predicate: NSPredicate?, context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        
        // FIXME: error handling
        let fetchedResults = context.executeFetchRequest(fetchRequest, error: nil)
        
        if let results = fetchedResults {
            return results.count
        }
        
        return 0
    }

    class func find(entityName: String, predicate: NSPredicate, context: NSManagedObjectContext) -> NSManagedObject? {
        var obj: NSManagedObject?
            
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
            
        // FIXME: error handling
        if let results = context.executeFetchRequest(fetchRequest, error: nil) {
            if results.count == 1 {
                obj = (results[0] as! NSManagedObject)
            } else if results.count > 1 {
                // FIXME: do something
                NSLog("more than one result in CoreDataHelper.find(\(entityName))")
            }
        }
        return obj
    }
    

    class func create(entityName: String, context: NSManagedObjectContext,
        initializer: (entity: NSEntityDescription, context: NSManagedObjectContext) -> NSManagedObject) -> NSManagedObject {
            
            var obj: NSManagedObject?
            
            if let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context) {
                obj = initializer(entity: entity, context: context)
            }
            
            return obj!
    }
}