import Foundation
import CoreData


class JsonRecipeParser {
    func parse(recipesJson: NSData?) -> [Recipe]? {
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
                } else {
                    return nil // JSON parsing failed
                }
            }
        } else {
            return nil // JSON parsing failed
        }
        
        return recipes
    }
}

class URLRecipeSource {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func read() -> [Recipe]? {
        let parser = JsonRecipeParser()
        return parser.parse(NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil))
    }
}

class CannedRecipeSource: URLRecipeSource {
    init() {
        let path = NSBundle.mainBundle().pathForResource("recipes", ofType: "json")!
        let recipesUrl = NSURL(fileURLWithPath: path)!

        super.init(url: recipesUrl)
    }
}

class WebRecipeSource: NSObject, NSURLConnectionDelegate {
    var recipesJsonData = NSMutableData()
    var completion: (([Recipe]?) -> Void)?
    
    func fetch(url: NSURL, completion: (([Recipe]?) -> Void)) {
        self.completion = completion
        
        let request = NSURLRequest(URL: url)
        NSURLConnection(request: request, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        recipesJsonData.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        let parser = JsonRecipeParser()
        completion!(parser.parse(recipesJsonData))
    }
}
