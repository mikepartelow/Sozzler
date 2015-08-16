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
        }
    }
    
    private var _oliveAsset: String
    var oliveAsset: String {
        get {
            return _oliveAsset
        }
        
        set(newOliveAsset) {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(newOliveAsset, forKeyPath: "oliveAsset")
            _oliveAsset = newOliveAsset
        }
    }
    
    func factoryReset() {
        _recipeSortOrder = .Name
        _oliveAsset = "asset-olive-green-outline"
    }

    init() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        let recipeSortOrderDefault = defaults.integerForKey("recipeSortOrder")
        if let recipeSortOrder = RecipeSortOrder(rawValue: recipeSortOrderDefault) {
            _recipeSortOrder = recipeSortOrder
        } else {
            _recipeSortOrder = .Name
        }
        
        if let oliveAsset = defaults.stringForKey("oliveAsset") {
            _oliveAsset = oliveAsset
        } else {
            _oliveAsset = "asset-olive-green-outline"
        }
    }
}