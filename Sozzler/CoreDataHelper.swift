import CoreData
import UIKit

class CoreDataHelper {
    
    class func count(entityName: String, predicate: NSPredicate?) -> Int {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        do {
            return try moc.fetch(fetchRequest).count
        } catch _ {
            assert(false)
            return 0
        }
    }

    class func find(entityName: String, predicate: NSPredicate) -> NSManagedObject? {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
            
        do {
            let results = try moc.fetch(fetchRequest)
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
    }
    
    class func all(entityName: String, predicate: NSPredicate? = nil) -> [NSManagedObject] {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        do {
            return try moc.fetch(fetchRequest) as! [NSManagedObject]
        } catch _ {
            return []
        }
    }
    
    class func create(entityName: String,
                      initializer: (_ entity: NSEntityDescription, _ context: NSManagedObjectContext) -> NSManagedObject) -> NSManagedObject {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        let entity = NSEntityDescription.entity(forEntityName: entityName, in: moc)!
        return initializer(entity, moc)
    }

    class func save() -> NSError? {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        do {
            try moc.save()
        } catch let error as NSError {
            return error
        }
        
        return nil
    }
    
    class func rollback() {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
        moc.rollback()
    }
    
    class func delete(obj: NSManagedObject) {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
        moc.delete(obj)
    }
    
    class func delete(recipe: Recipe) {
        for component in recipe.components.allObjects as! [Component] {
            // FIXME: lame hack. recipe_count will be recalculated in willSave() but if we don't change the
            // Ingredient, willSave() *wont* be called..
            //
            component.ingredient.computeRecipeCount(adjustment: -1)
            component.unit.computeRecipeCount(adjustment: -1)
            CoreDataHelper.delete(obj: component)
        }
        CoreDataHelper.delete(obj: recipe)
    }
    
    class func fetchedResultsController(fetchRequest: NSFetchRequest<NSFetchRequestResult>, sectionNameKeyPath: String? = nil) -> NSFetchedResultsController<NSFetchRequestResult> {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: sectionNameKeyPath, cacheName: nil)
    }
    
    class func factoryReset(save: Bool=true) {
        let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

        _ = CoreDataHelper.all(entityName: "Component").map({ moc.delete($0) })
        _ = CoreDataHelper.all(entityName: "Unit").map({ moc.delete($0) })
        _ = CoreDataHelper.all(entityName: "Ingredient").map({ moc.delete($0) })
        _ = CoreDataHelper.all(entityName: "Recipe").map({ moc.delete($0) })

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
