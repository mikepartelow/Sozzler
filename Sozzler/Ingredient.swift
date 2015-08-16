import UIKit
import CoreData

@objc(Ingredient)
class Ingredient: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var recipe_count: Int16
    @NSManaged var components: NSSet
    
    class func fetchedResultsController(predicate: NSPredicate?=nil) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "Ingredient")
        fetchRequest.predicate = predicate

        let sortByName              = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortByName]

        return CoreDataHelper.fetchedResultsController(fetchRequest, sectionNameKeyPath: "name")
    }

    class func create(name: String) -> Ingredient {
        return CoreDataHelper.create("Ingredient", initializer: {
            (entity, context) -> NSManagedObject in
                let ingredient = Ingredient(entity: entity, insertIntoManagedObjectContext: context)
                ingredient.name = Recipe.fancyName(name)
                ingredient.recipe_count = 0
                return ingredient
            }
        ) as! Ingredient
    }
    
    class func find(name: String) -> Ingredient? {
        let predicate = NSPredicate(format: "name ==[c] %@", Recipe.fancyName(name))
        return CoreDataHelper.find("Ingredient", predicate: predicate) as! Ingredient?
    }
    
    class func findOrCreate(name: String) -> Ingredient {
        let fancyName = Recipe.fancyName(name)
        if let ingredient = Ingredient.find(fancyName) {
            return ingredient
        } else {
            return Ingredient.create(fancyName)
        }
    }
}

// saving and validation
//
extension Ingredient {
    class func count() -> Int {
        return CoreDataHelper.count("Ingredient", predicate: nil)
    }
    
    // FIXME: DRY: copypasta Unit
    override func willSave() {
        if !deleted {
            var recipeCounts: [Recipe:Int] = [:]
            
            setPrimitiveValue(Recipe.fancyName(name), forKey: "name")

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