import CoreData

class CoreDataHelper {
    class func count(entityName: String, context: NSManagedObjectContext) -> Int {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        // FIXME: error handling
        let fetchedResults = context.executeFetchRequest(fetchRequest, error: nil)
        
        if let results = fetchedResults {
            return results.count
        }
        
        return 0
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