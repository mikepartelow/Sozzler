import CoreData
import UIKit

class CoreDataHelper {
    
    class func count(entityName: String, predicate: NSPredicate?) -> Int {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        
        do {
            return try moc.executeFetchRequest(fetchRequest).count
        } catch _ {
            assert(false)
            return 0
        }
    }

    class func find(entityName: String, predicate: NSPredicate) -> NSManagedObject? {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
            
        do {
            let results = try moc.executeFetchRequest(fetchRequest)
            if results.count == 0 {
                return nil
            } else if results.count > 1 {
                assert(false)
                NSLog("more than one result in CoreDataHelper.find(\(entityName))")
            }
            return results[0] as? NSManagedObject
        } catch _ {
            assert(false)
            fatalError()
        }

        return nil
    }
    
    class func all(entityName: String, predicate: NSPredicate? = nil) -> [NSManagedObject] {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        
        do {
            return try moc.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        } catch _ {
            return []
        }
    }
    
    class func create(entityName: String,
        initializer: (entity: NSEntityDescription, context: NSManagedObjectContext) -> NSManagedObject) -> NSManagedObject {
            let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

            let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: moc)!
            return initializer(entity: entity, context: moc)
    }

    class func save() -> NSError? {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        do {
            try moc.save()
        } catch let error as NSError {
            return error
        }
        
        return nil
    }
    
    class func rollback() {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        moc.rollback()
    }
    
    class func delete(obj: NSManagedObject) {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        moc.deleteObject(obj)
    }
    
    class func delete(recipe: Recipe) {
        for component in recipe.components.allObjects as! [Component] {
            // FIXME: lame hack. recipe_count will be recalculated in willSave() but if we don't change the
            // Ingredient, willSave() *wont* be called..
            //
            component.ingredient.computeRecipeCount(-1)
            component.unit.computeRecipeCount(-1)
            CoreDataHelper.delete(component)
        }
        CoreDataHelper.delete(recipe as NSManagedObject)
    }
    
    class func fetchedResultsController(fetchRequest: NSFetchRequest, sectionNameKeyPath: String? = nil) -> NSFetchedResultsController {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
    }
    
    class func factoryReset(save: Bool=true) {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

        CoreDataHelper.all("Component").map({ moc.deleteObject($0) })
        CoreDataHelper.all("Unit").map({ moc.deleteObject($0) })
        CoreDataHelper.all("Ingredient").map({ moc.deleteObject($0) })
        CoreDataHelper.all("Recipe").map({ moc.deleteObject($0) })

        if save {
            if let error = CoreDataHelper.save() {
                NSLog("[RESET] : \(error)")
                assert(false)
                fatalError()
            } else {
                NSLog("[RESET] : recipe count: \(Recipe.count())")
            }
        }
    }
}