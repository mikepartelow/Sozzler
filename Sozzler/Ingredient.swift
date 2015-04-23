import Foundation
import CoreData

class Ingredient: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var recipe_count: NSNumber
    @NSManaged var components: NSSet

}
