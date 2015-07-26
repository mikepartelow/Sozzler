import Foundation
import CoreData


class URLRecipeSource {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func read() -> [Recipe]? {
        let recipesJson = NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
        var recipes = [Recipe]()
        if let recipeDicts = NSJSONSerialization.JSONObjectWithData(recipesJson!, options: nil, error: nil) as? [NSDictionary] {
            recipeLoop: for recipeDict in recipeDicts {
                if let newRecipe = Recipe.create(recipeDict) {
                    if let existingRecipe = Recipe.findDuplicate(newRecipe) {
                        NSLog("Found duplicate of \(newRecipe.name)")
                        if existingRecipe == newRecipe {
                            NSLog("Deleting exact duplicate new recipe (1)")
                            CoreDataHelper.delete(newRecipe)
                            continue
                        } else {
                            do {
                                newRecipe.name += " (Alternate)"
                                if let existingRecipe = Recipe.findDuplicate(newRecipe) where existingRecipe == newRecipe {
                                    NSLog("Deleting exact duplicate new recipe (2)")
                                    CoreDataHelper.delete(newRecipe)
                                    continue recipeLoop

                                }
                            } while (Recipe.findDuplicate(newRecipe) != nil)
                        }
                    }
                    recipes.append(newRecipe)
                }
            }
        } else {
            return nil // JSON parsing failed
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