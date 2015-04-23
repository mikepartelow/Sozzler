import Foundation
import CoreData

@objc(Ingredient)
class Ingredient: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var recipe_count: NSNumber
    @NSManaged var components: NSSet

    class func create(name: String, context: NSManagedObjectContext) -> Ingredient {
        return CoreDataHelper.create("Ingredient", context: context, initializer: {
            (entity, context) -> NSManagedObject in
                let ingredient = Ingredient(entity: entity, insertIntoManagedObjectContext: context)
                ingredient.name = name
                return ingredient
            }
        ) as! Ingredient
    }
}
