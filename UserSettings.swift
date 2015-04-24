import Foundation

class UserSettings {
    enum RecipeSortOrder: Int {
        case Rating = 0
        case Name
        case NumberOfIngredients
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
    
    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let recipeSortOrderDefault = defaults.integerForKey("recipeSortOrder")
        if let recipeSortOrder = RecipeSortOrder(rawValue: recipeSortOrderDefault) {
            _recipeSortOrder = recipeSortOrder
        } else {
            _recipeSortOrder = RecipeSortOrder.Rating
        }        
    }
}