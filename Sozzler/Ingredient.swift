import UIKit
import CoreData

@objc(Ingredient)
class Ingredient: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var recipe_count: Int16
    @NSManaged var components: NSSet

    class func fetchRequest() -> NSFetchRequest {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        let fetchRequest = NSFetchRequest(entityName: "Ingredient")
        let sortByName              = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [sortByName]
        
        return fetchRequest
    }

    class func create(name: String, context: NSManagedObjectContext) -> Ingredient {
        return CoreDataHelper.create("Ingredient", context: context, initializer: {
            (entity, context) -> NSManagedObject in
                let ingredient = Ingredient(entity: entity, insertIntoManagedObjectContext: context)
                ingredient.name = name
                return ingredient
            }
        ) as! Ingredient
    }
    
    class func find(name: String, context: NSManagedObjectContext) -> Ingredient? {
        let predicate = NSPredicate(format: "name == %@", name)
        return CoreDataHelper.find("Ingredient", predicate: predicate, context: context) as! Ingredient?
    }
}
