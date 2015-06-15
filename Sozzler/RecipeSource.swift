import Foundation
import CoreData

class URLRecipeSource {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func read() -> [Recipe]? {
        let recipesJson = NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
        var recipes: [Recipe]?
        if let recipeDicts = NSJSONSerialization.JSONObjectWithData(recipesJson!, options: nil, error: nil) as? [NSDictionary] {
            let recipeArray = filter(map(recipeDicts, { Recipe.create($0) }), { $0 != nil }).map { $0! }
            if recipeArray.count > 0 {
                recipes = recipeArray
            }
        }
        
        return recipes
    }
}

class CannedRecipeSource: URLRecipeSource {
    init() {
        let path = NSBundle.mainBundle().pathForResource("recipes", ofType: "json")!
        let recipesUrl = NSURL(fileURLWithPath: path)!

        super.init(url: recipesUrl)
    }
}