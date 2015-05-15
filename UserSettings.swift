import Foundation

class UserSettings {
    enum RecipeSortOrder: Int {
        case Name = 0
        case Rating
        case NumberOfIngredients
    }
    
    private var _recipeSortOrder: RecipeSortOrder
    var recipeSortOrder: RecipeSortOrder {
        get {
            return _recipeSortOrder
        }
        
        set(newSortOrder) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(newSortOrder.rawValue, forKey: "recipeSortOrder")
            _recipeSortOrder = newSortOrder
        }
    }

    enum IngredientSortOrder: Int {
        case Name = 0
        case NumberOfRecipes
    }
    
    private var _ingredientSortOrder: IngredientSortOrder
    var ingredientSortOrder: IngredientSortOrder {
        get {
            return _ingredientSortOrder
        }
        
        set(newSortOrder) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setInteger(newSortOrder.rawValue, forKey: "ingredientSortOrder")
            _ingredientSortOrder = newSortOrder
        }
    }

    var recipeSortOrderName: String {
        switch recipeSortOrder {
        case .Rating:
            return "Rating"
        case .Name:
            return "Name"
        case .NumberOfIngredients:
            return "Number of Ingredients"
        default:
            return ""
        }
    }
    
    var ingredientSortOrderName: String {
        switch ingredientSortOrder {
        case .Name:
            return "Name"
        case .NumberOfRecipes:
            return "Number of Recipes"
        default:
            return ""
        }
    }
    
    func factoryReset() {
        _recipeSortOrder = .Name
        _ingredientSortOrder = .Name
    }

    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let recipeSortOrderDefault = defaults.integerForKey("recipeSortOrder")
        if let recipeSortOrder = RecipeSortOrder(rawValue: recipeSortOrderDefault) {
            _recipeSortOrder = recipeSortOrder
        } else {
            _recipeSortOrder = .Name
        }
        
        let ingredientSortOrderDefault = defaults.integerForKey("ingredientSortOrder")
        if let ingredientSortOrder = IngredientSortOrder(rawValue: ingredientSortOrderDefault) {
            _ingredientSortOrder = ingredientSortOrder
        } else {
            _ingredientSortOrder = .Name
        }

    }
}