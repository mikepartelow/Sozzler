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
    
    class func create(quantity_n: Int16, quantity_d: Int16, unit: Unit, ingredient: Ingredient, recipe: Recipe, context: NSManagedObjectContext) -> Component {
        
        return CoreDataHelper.create("Component", context: context, initializer: {
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
