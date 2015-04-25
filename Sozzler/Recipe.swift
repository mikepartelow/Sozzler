import UIKit
import CoreData

@objc(Recipe)
class Recipe: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var rating: Int16
    @NSManaged var text: String
    @NSManaged var component_count: Int16
    @NSManaged var components: NSSet
}

// querying
//
extension Recipe {
    class func fetchRequest() -> NSFetchRequest {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let fetchRequest = NSFetchRequest(entityName: "Recipe")
        
        let sortByRating            = NSSortDescriptor(key: "rating", ascending: false)
        let sortByName              = NSSortDescriptor(key: "name", ascending: true)
        let sortByComponentCount    = NSSortDescriptor(key: "component_count", ascending: false)
        
        switch app.userSettings.recipeSortOrder {
        case .Rating:
            fetchRequest.sortDescriptors = [sortByRating, sortByName, sortByComponentCount]
        case .Name:
            fetchRequest.sortDescriptors = [sortByName, sortByRating, sortByComponentCount]
        case .NumberOfIngredients:
            fetchRequest.sortDescriptors = [sortByComponentCount, sortByRating, sortByName]
        }
        
        return fetchRequest
    }
    
    class func count() -> Int {
        return CoreDataHelper.count("Recipe", predicate: nil)
    }
    
    class func countByName(name: String) -> Int {
        let predicate = NSPredicate(format: "name == %@", name)
        return CoreDataHelper.count("Recipe", predicate: predicate)
    }
}

// creation
//
extension Recipe {
    class func create(name: String, withRating rating: Int16, withText text: String) -> Recipe {
        let predicate = NSPredicate(format: "name == %@", name)
        
        let recipe = CoreDataHelper.create("Recipe", initializer: { (entity, context) in
            let recipe = Recipe(entity: entity, insertIntoManagedObjectContext: context)
            recipe.name = name
            recipe.rating = rating
            recipe.text = text
            recipe.component_count = 0
            return recipe
        })
        
        return recipe as! Recipe
    }

    class func populate() {
        let oz = Unit.create("ounce")
        let tsp = Unit.create("tsp")
        
        var artichoke = Ingredient.create("artichoke")
        var asparagus = Ingredient.create("asparagus")
        var limeJuice = Ingredient.create("lime juice")
        var lemonJuice = Ingredient.create("lemon juice")

        var r = Recipe.create("a disgusting artichoke", withRating: 1, withText: "not as bad as it sounds")
        Component.create(1, quantity_d: 2, unit: oz, ingredient: artichoke, recipe: r)
        Component.create(1, quantity_d: 1, unit: oz, ingredient: limeJuice, recipe: r)
        
        r = Recipe.create("b disgusting asparagus", withRating: 2, withText: "worse than it sounds")
        Component.create(2, quantity_d: 1, unit: oz, ingredient: asparagus, recipe: r)
        Component.create(1, quantity_d: 4, unit: tsp, ingredient: limeJuice, recipe: r)

        let text = "\n".join(map((0..<30), { "long recipe text \($0)" }))
        r = Recipe.create("c disgusting rutabaga", withRating: 3, withText: text)
        Component.create(1, quantity_d: 3, unit: oz, ingredient: asparagus, recipe: r)
        Component.create(1, quantity_d: 1, unit: oz, ingredient: limeJuice, recipe: r)
        Component.create(1, quantity_d: 1, unit: tsp, ingredient: lemonJuice, recipe: r)
        
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        NSLog("FIXME: put this in CDH, no moc here")
        var error: NSError?
        if moc.save(&error) {
        } else {
            NSLog("\(error)")
        }
    }
}

// saving and validation
//
extension Recipe {
    override func willSave() {
        if !deleted {
            setPrimitiveValue(components.count, forKey: "component_count")
        }
    }
    
    func validate(error: NSErrorPointer) -> Bool {
        var errorMessage = ""
        
        if components.count < 1 {
            errorMessage = "Please add at least one ingredient."
        } else if name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
            errorMessage = "Please add a name for your recipe."
        } else if Recipe.countByName(name) > 1 {
            errorMessage = "Sorry, that name is already taken."
        } else {
            return true
        }
        
        if !errorMessage.isEmpty {
            if error != nil {
                error.memory = NSError(domain: "CoreData", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
        }
        
        return false
    }
    
    override func validateForUpdate(error: NSErrorPointer) -> Bool {
        if !super.validateForUpdate(error) {
            return false
        }
        
        return validate(error)
    }
    
    override func validateForInsert(error: NSErrorPointer) -> Bool {
        if !super.validateForInsert(error) {
            return false
        }
        
        return validate(error)
    }
}