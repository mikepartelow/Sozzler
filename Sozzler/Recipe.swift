import UIKit
import CoreData

func ==(lhs: Recipe, rhs: Recipe) -> Bool {
    if lhs.name == rhs.name && lhs.rating == rhs.rating && lhs.text == rhs.text && lhs.components.count == rhs.components.count {
        let lhsSortedComponents = lhs.sortedComponents
        let rhsSortedComponents = rhs.sortedComponents

        for i in 0..<Int(lhs.components.count) {
            if lhsSortedComponents[i] != rhsSortedComponents[i] {
                return false
            }
        }

        return true
    }

    return false
}


@objc(Recipe)
class Recipe: NSManagedObject {

    enum ValidationErrorCode: Int {
        case None = 0
        case Name
        case Ingredients
    }

    @NSManaged var name: String
    @NSManaged var rating: Int16
    @NSManaged var text: String
    @NSManaged var component_count: Int16
    @NSManaged var components: NSMutableSet

    var sortedComponents: [Component] {
        let componentArray = components.allObjects as! [Component]
        return componentArray.sort({ (lhs, rhs) -> Bool in
            lhs.index < rhs.index
        })
    }
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

    class func find(name: String) -> Recipe? {
        let predicate = NSPredicate(format: "name ==[c] %@", Recipe.fancyName(name))
        return CoreDataHelper.find("Recipe", predicate: predicate) as! Recipe?
    }

    class func findDuplicate(recipe: Recipe) -> Recipe? {
        let predicate = NSPredicate(format: "name ==[c] %@", Recipe.fancyName(recipe.name))
        let recipes = CoreDataHelper.all("Recipe", predicate: predicate) as! [Recipe]

        assert(recipes.count <= 2)
        for foundRecipe in recipes {
            if foundRecipe.objectID != recipe.objectID {
                return foundRecipe
            }
        }

        return nil
    }

    class func count() -> Int {
        return CoreDataHelper.count("Recipe", predicate: nil)
    }

    class func countByName(name: String) -> Int {
        let searchName = Recipe.fancyName(name)
        let predicate = NSPredicate(format: "name == %@", searchName)
        let count = CoreDataHelper.count("Recipe", predicate: predicate)
        return count
    }
}

// creation
//
extension Recipe {
    class func create(name: String, withRating rating: Int16, withText text: String) -> Recipe {
        NSLog("create: [\(name)]")

        let recipe = CoreDataHelper.create("Recipe", initializer: { (entity, context) in
            let recipe = Recipe(entity: entity, insertIntoManagedObjectContext: context)
            recipe.name = Recipe.fancyName(name)
            recipe.rating = rating
            recipe.text = text
            recipe.component_count = 0
            return recipe
        })

        return recipe as! Recipe
    }

    class func create(recipeDict: NSDictionary) -> Recipe? {
        let name           = (recipeDict["name"] as? String) ?? nil
        let rating         = (recipeDict["rating"] as? Int) ?? nil
        let text           = (recipeDict["text"] as? String) ?? nil

        if name == nil || rating == nil || text == nil {
            return nil
        }

        let components     = (recipeDict["components"] as? [NSDictionary]) ?? [NSDictionary]()

        let recipe = Recipe.create(name!, withRating: Int16(rating!), withText: text!)

        for componentDict in components {
            let quantity        = (componentDict["quantity"] as? String) ?? nil
            let unitName        = (componentDict["unit"] as? String) ?? nil
            let unitPluralName  = (componentDict["unit_plural"] as? String) ?? unitName
            let ingredientName  = (componentDict["ingredient"] as? String) ?? nil
            let index           = (componentDict["index"] as? Int) ?? nil

            if quantity == nil || unitName == nil || ingredientName == nil || index == nil {
                return nil
            }

            let unit            = Unit.findOrCreate(unitName!, plural_name: unitPluralName!)
            let ingredient      = Ingredient.findOrCreate(ingredientName!)

            let (quantity_n, quantity_d) = Component.parseQuantity(quantity!)
            let component       = Component.create(Int16(quantity_n), quantity_d: Int16(quantity_d), unit: unit, ingredient: ingredient, recipe: recipe, index: Int16(index!))
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

        let components = recipe.components.allObjects.map({ NSMutableDictionary(component: $0 as! Component) })

        setValue(components, forKey: "components")
    }
}

// saving and validation
//
extension Recipe {
    class func fancyName(name: String) -> String {
        let trimmedName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if !trimmedName.isEmpty && String(trimmedName[trimmedName.startIndex]) == String(trimmedName[trimmedName.startIndex]).capitalizedString {
            return trimmedName
        } else {
            return trimmedName.capitalizedString
        }
    }

    override func willSave() {
        if !deleted {
            setPrimitiveValue(components.count, forKey: "component_count")
        }
    }

    func validate() throws {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        var errorMessage = ""
        var errorCode = ValidationErrorCode.None
        // have to do this to get accurate name uniqueness count.
        // if we don't, we may be searching for "XX" while this recipe is named " XX" -- so no dup!
        //
        setPrimitiveValue(Recipe.fancyName(name), forKey: "name")

        if components.count < 1 {
            errorMessage = "Please add at least one ingredient."
            errorCode = .Ingredients
        } else if name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
            errorMessage = "Please add a name for your recipe."
            errorCode = .Name
        } else if Recipe.countByName(name) > 1 {
            errorMessage = "Sorry, that name is already taken."
            errorCode = .Name
        } else {
            return
        }

        if !errorMessage.isEmpty {
            error = NSError(domain: "CoreData", code: errorCode.rawValue, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        throw error
    }

    override func validateForUpdate() throws {
        try super.validateForUpdate()

        try validate()
    }

    override func validateForInsert() throws {
        try super.validateForInsert()

        try validate()
    }
}