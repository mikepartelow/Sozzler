import Foundation
import CoreData

func <(lhs: Component, rhs: Component) -> Bool {
    let x = Int(lhs.quantity_n) * Int(rhs.quantity_d)
    let y = Int(rhs.quantity_n) * Int(lhs.quantity_d)
    
    return x < y
}

func ==(lhs: Component, rhs: Component) -> Bool {
    return lhs.ingredient == rhs.ingredient &&
        lhs.unit == rhs.unit &&
        lhs.quantity_n == rhs.quantity_n &&
        lhs.quantity_d == rhs.quantity_d
}

@objc(Component)
class Component: NSManagedObject, Comparable {

    @NSManaged var quantity_d: Int16
    @NSManaged var quantity_n: Int16
    @NSManaged var quantity_s: String
    @NSManaged var ingredient: Ingredient
    @NSManaged var unit: Unit
    @NSManaged var recipe: Recipe

    var string: String {
        return "\(quantity_n)/\(quantity_d) \(unit.name) \(ingredient.name)"
    }
    
    class func sorted(components: NSSet) -> [Component] {
        let componentArray = components.allObjects as! [Component]

        return Swift.sorted(componentArray, { $0 > $1 })
    }
    
    class func create(quantity_n: Int16, quantity_d: Int16, unit: Unit, ingredient: Ingredient, recipe: Recipe) -> Component {
        
        return CoreDataHelper.create("Component", initializer: {
            (entity, context) in
            let component = Component(entity: entity, insertIntoManagedObjectContext: context)
            
            component.quantity_n    = quantity_n
            component.quantity_d    = quantity_d
            component.unit          = unit
            component.ingredient    = ingredient
            component.recipe        = recipe
            return component
        }) as! Component
    }
}

extension Component {
    // FIXME: this needs to handle unparseable strings. try MANY cases.
    //
    class func parseQuantity(quantity: String) -> (quantity_n: Int, quantity_d: Int) {
        var quantity_n = 0
        var quantity_d = 1
        
        var partsIdx = 0
        
        var parts = quantity.componentsSeparatedByString(" ")
        if let intPart = parts[partsIdx].toInt() {
            quantity_n = intPart
            partsIdx += 1
        }
            
        if partsIdx < parts.count {
            let possibleFractionalParts = parts[partsIdx].componentsSeparatedByString("/")
            if possibleFractionalParts.count > 1 {
                if let numerator = possibleFractionalParts[0].toInt(), let denominator = possibleFractionalParts[1].toInt() {
                    quantity_d = denominator
                    quantity_n = (quantity_n * quantity_d) + numerator
                }
            }
        }
        
        return (quantity_n, quantity_d)
    }
}