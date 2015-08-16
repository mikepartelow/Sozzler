import Foundation
import CoreData

func !=(lhs: Component, rhs: Component) -> Bool {
    return !(lhs == rhs)
}

func ==(lhs: Component, rhs: Component) -> Bool {
    return lhs.unit.name == rhs.unit.name &&
            lhs.ingredient.name == rhs.ingredient.name &&
            lhs.quantity_n == rhs.quantity_n &&
            lhs.quantity_d == rhs.quantity_d
}

@objc(Component)
class Component: NSManagedObject {

    @NSManaged var index: Int16
    @NSManaged var quantity_d: Int16
    @NSManaged var quantity_n: Int16
    @NSManaged var ingredient: Ingredient
    @NSManaged var unit: Unit
    @NSManaged var recipe: Recipe

    var string: String {
        var quantity = ""
        
        if quantity_n > 0 {
            let whole = quantity_n / quantity_d
            let rem = quantity_n % quantity_d
            
            if rem > 0 {
                let fancyFractions = ["1/8" : "⅛", "1/4" : "¼", "3/4" : "¾", "1/2" : "½", "1/3" : "⅓" , "2/3" : "⅔"]
                var frac = "\(rem)/\(quantity_d)"
                if (fancyFractions[frac] != nil) {
                    frac = fancyFractions[frac]!
                }
            
                if whole > 0 {
                    quantity = "\(whole) \(frac)"
                } else {
                    quantity = "\(frac)"
                }
            } else {
                quantity = "\(whole)"
            }
        }
        
        let unit_name = (quantity_n / quantity_d) > 1 ? unit.plural_name : unit.name
        
        return "\(quantity) \(unit_name) \(ingredient.name)".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).stringByReplacingOccurrencesOfString("  ", withString: " ")

    }
        
    class func create(quantity_n: Int16, quantity_d: Int16, unit: Unit, ingredient: Ingredient, recipe: Recipe, index: Int16) -> Component {
        
        return CoreDataHelper.create("Component", initializer: {
            (entity, context) in
            let component = Component(entity: entity, insertIntoManagedObjectContext: context)
            
            component.quantity_n    = quantity_n
            component.quantity_d    = quantity_d
            component.unit          = unit
            component.ingredient    = ingredient
            component.recipe        = recipe
            component.index         = index
            return component
        }) as! Component
    }
}

extension Component {
    class func parseQuantity(quantity: String) -> (quantity_n: Int, quantity_d: Int) {
        var quantity_n = 0
        var quantity_d = 1
        
        var partsIdx = 0
        
        var parts = quantity.componentsSeparatedByString(" ")
        if let intPart = Int(parts[partsIdx]) {
            quantity_n = intPart
            partsIdx += 1
        }
            
        if partsIdx < parts.count {
            let possibleFractionalParts = parts[partsIdx].componentsSeparatedByString("/")
            if possibleFractionalParts.count > 1 {
                if let numerator = Int(possibleFractionalParts[0]), let denominator = Int(possibleFractionalParts[1]) {
                    quantity_d = denominator
                    quantity_n = (quantity_n * quantity_d) + numerator
                }
            }
        }
        
        return (quantity_n, quantity_d)
    }
}

extension NSMutableDictionary {
    convenience init(component: Component) {
        self.init()
        
        let quantity = "\(component.quantity_n)/\(component.quantity_d)"

        setValue(quantity, forKey: "quantity")
        
        setValue(component.unit.name, forKey: "unit")
        setValue(component.ingredient.name, forKey: "ingredient")
        setValue(Int(component.index), forKey: "index")
        
        if component.unit.plural_name != component.unit.name {
            setValue(component.unit.plural_name, forKey: "unit_plural")
        }
    }
}
