import Foundation
import CoreData

class Component: NSManagedObject {

    @NSManaged var quantity_d: NSNumber
    @NSManaged var quantity_n: NSNumber
    @NSManaged var quantity_s: String
    @NSManaged var ingredient: NSManagedObject
    @NSManaged var unit: NSManagedObject
    @NSManaged var recipe: NSManagedObject

}
