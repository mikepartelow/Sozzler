import UIKit
import CoreData

@objc(Recipe)
class Recipe: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var rating: Int16
    @NSManaged var text: String
    @NSManaged var component_count: Int16
    @NSManaged var components: NSMutableSet
}

// querying
//
extension Recipe {
    class func fetchedResultsController(predicate: NSPredicate? = nil) -> NSFetchedResultsController {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let fetchRequest = NSFetchRequest(entityName: "Recipe")
        if predicate != nil {
            fetchRequest.predicate = predicate
        }
        
        let sortByRating            = NSSortDescriptor(key: "rating", ascending: false)
        let sortByName              = NSSortDescriptor(key: "name", ascending: true)
        let sectionNameKeyPath: String
        
        switch app.userSettings.recipeSortOrder {
        case .Rating:
            sectionNameKeyPath = "rating"
            fetchRequest.sortDescriptors = [sortByRating, sortByName]
        case .Name:
            sectionNameKeyPath = "name"
            fetchRequest.sortDescriptors = [sortByName, sortByRating]
        }
        
        return CoreDataHelper.fetchedResultsController(fetchRequest, sectionNameKeyPath: sectionNameKeyPath)
    }
    
    class func all() -> [Recipe] {
        return CoreDataHelper.all("Recipe") as! [Recipe]
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
    
    class func create(recipeDict: NSDictionary) -> Recipe? {
        let name        = recipeDict["name"]        as! String
        let rating      = recipeDict["rating"]      as! Int
        let text        = recipeDict["text"]       as! String
        let components  = recipeDict["components"]  as! [NSDictionary]
        
        let recipe = Recipe.create(name, withRating: Int16(rating), withText: text)
        
        for componentDict in components {
            let quantity        = componentDict["quantity"]     as! String
            let unitName        = componentDict["unit"]         as! String
            let ingredientName  = componentDict["ingredient"]   as! String
            
            let unit            = Unit.findOrCreate(unitName)
            let ingredient      = Ingredient.findOrCreate(ingredientName)
            
            let (quantity_n, quantity_d) = Component.parseQuantity(quantity)
            // FIXME: should probably bounds check quantity_n/d before downcast
            //
            let component       = Component.create(Int16(quantity_n), quantity_d: Int16(quantity_d), unit: unit, ingredient: ingredient, recipe: recipe)
        }
        
        return recipe
    }

}

extension NSMutableDictionary {
    convenience init(recipe: Recipe) {
        self.init()

        setValue(recipe.name,               forKey: "name")
        setValue(Int(recipe.rating),        forKey: "rating")
        setValue(recipe.text,               forKey: "text")
        
        let components = map(recipe.components.allObjects, { NSMutableDictionary(component: $0 as! Component) })
        
        setValue(components, forKey: "components")
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
    
    // FIXME: additional validations
    //
    //        0 < rating <= 5
    
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