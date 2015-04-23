import Foundation
import CoreData

@objc(Recipe)
class Recipe: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var rating: NSNumber
    @NSManaged var text: String
    @NSManaged var component_count: NSNumber
    @NSManaged var components: NSSet

    class func fetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Recipe")
        
        let sortByRating            = NSSortDescriptor(key: "rating", ascending: false)
        let sortByName              = NSSortDescriptor(key: "name", ascending: true)
        let sortByComponentCount    = NSSortDescriptor(key: "component_count", ascending: false)
        
        fetchRequest.sortDescriptors = [sortByName, sortByRating, sortByComponentCount]
        
        return fetchRequest
    }
    
    class func count(context: NSManagedObjectContext) -> Int {
        return CoreDataHelper.count("Recipe", context: context)
    }

    class func create(name: String, withRating rating: Int, withText text: String, inContext context: NSManagedObjectContext) -> Recipe {
        let predicate = NSPredicate(format: "name == %@", name)
        
        let recipe = CoreDataHelper.create("Recipe", context: context, initializer: { (entity, context) in
            let recipe = Recipe(entity: entity, insertIntoManagedObjectContext: context)
            recipe.name = name
            recipe.rating = rating
            recipe.text = text
            return recipe
        })
        
        return recipe as! Recipe
    }

    class func populate(context: NSManagedObjectContext) {
        Recipe.create("disgusting artichoke", withRating: 5, withText: "not as bad as it sounds", inContext: context)
        Recipe.create("disgusting asparagus", withRating: 4, withText: "worse than it sounds", inContext: context)
        Recipe.create("disgusting rutabaga", withRating: 3, withText: "only marginally worse than it sounds", inContext: context)
        
        context.save(nil)
    }
}
