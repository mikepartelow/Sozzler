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

    class func create(name: String) -> Ingredient {
        return CoreDataHelper.create("Ingredient", initializer: {
            (entity, context) -> NSManagedObject in
                let ingredient = Ingredient(entity: entity, insertIntoManagedObjectContext: context)
                ingredient.name = name
                ingredient.recipe_count = 0
                return ingredient
            }
        ) as! Ingredient
    }
    
    class func find(name: String) -> Ingredient? {
        let predicate = NSPredicate(format: "name == %@", name)
        return CoreDataHelper.find("Ingredient", predicate: predicate) as! Ingredient?
    }
}

// saving and validation
//
extension Ingredient {
    override func willSave() {
        if !deleted {
            var recipeCounts: [Recipe:Int] = [:]
            
            for component in components.allObjects as! [Component] {
                if recipeCounts[component.recipe] == nil {
                   recipeCounts[component.recipe] = 1
                } else {
                    recipeCounts[component.recipe]! += 1
                }
            }
            
            let count = recipeCounts.values.array.reduce(0, combine: +)
            setPrimitiveValue(count, forKey: "recipe_count")
        }
    }
}