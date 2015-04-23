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
        let oz = Unit.create("ounce", context: context)
        let tsp = Unit.create("tsp", context: context)
        
        var artichoke = Ingredient.create("artichoke", context: context)
        var asparagus = Ingredient.create("asparagus", context: context)
        var limeJuice = Ingredient.create("lime juice", context: context)
        var lemonJuice = Ingredient.create("lemon juice", context: context)
        
        var r = Recipe.create("disgusting artichoke", withRating: 5, withText: "not as bad as it sounds", inContext: context)
        Component.create(1, quantity_d: 2, unit: oz, ingredient: artichoke, recipe: r, context: context)
        Component.create(1, quantity_d: 1, unit: oz, ingredient: limeJuice, recipe: r, context: context)
        r.component_count = 2
        
        r = Recipe.create("disgusting asparagus", withRating: 4, withText: "worse than it sounds", inContext: context)
        Component.create(2, quantity_d: 1, unit: oz, ingredient: asparagus, recipe: r, context: context)
        Component.create(1, quantity_d: 4, unit: tsp, ingredient: limeJuice, recipe: r, context: context)
        r.component_count = 2

        let text = "\n".join(map((0..<30), { "long recipe text \($0)" }))
        r = Recipe.create("disgusting rutabaga", withRating: 3, withText: text, inContext: context)
        Component.create(1, quantity_d: 3, unit: oz, ingredient: asparagus, recipe: r, context: context)
        Component.create(1, quantity_d: 1, unit: oz, ingredient: limeJuice, recipe: r, context: context)
        Component.create(1, quantity_d: 1, unit: tsp, ingredient: lemonJuice, recipe: r, context: context)
        r.component_count = 3
        
        artichoke.recipe_count = 1
        asparagus.recipe_count = 2
        limeJuice.recipe_count = 3
        lemonJuice.recipe_count = 1
        
        var error: NSError?
        if context.save(&error) {            
        } else {
            NSLog("\(error)")
        }
    }
}
