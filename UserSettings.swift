import Foundation

class UserSettings {
    enum RecipeSortOrder: Int {
        case Name = 0
        case Rating
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

    var recipeSortOrderName: String {
        switch recipeSortOrder {
        case .Rating:
            return "Rating"
        case .Name:
            return "Name"
        default:
            return ""
        }
    }
    
    func factoryReset() {
        _recipeSortOrder = .Name
    }

    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let recipeSortOrderDefault = defaults.integerForKey("recipeSortOrder")
        if let recipeSortOrder = RecipeSortOrder(rawValue: recipeSortOrderDefault) {
            _recipeSortOrder = recipeSortOrder
        } else {
            _recipeSortOrder = .Name
        }        
    }
}