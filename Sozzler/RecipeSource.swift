import Foundation
import CoreData


class JsonRecipeParser {
    func parse(recipesJson: NSData?) -> [Recipe]? {
        do {
            let recipeDicts = try JSONSerialization.jsonObject(with: recipesJson! as Data, options: []) as! [NSDictionary]

            var recipes = [Recipe]()
            
            recipeLoop: for recipeDict in recipeDicts {
                if let newRecipe = Recipe.create(recipeDict: recipeDict) {
                    if let existingRecipe = Recipe.findDuplicate(recipe: newRecipe) {
                        NSLog("Found duplicate of \(newRecipe.name)")
                        if existingRecipe == newRecipe {
                            NSLog("Deleting exact duplicate new recipe (1)")
                            CoreDataHelper.delete(recipe: newRecipe)
                            continue
                        } else {
                            repeat {
                                newRecipe.name += " (Alternate)"
                                if let existingRecipe = Recipe.findDuplicate(recipe: newRecipe), existingRecipe == newRecipe {
                                    NSLog("Deleting exact duplicate new recipe (2)")
                                    CoreDataHelper.delete(recipe: newRecipe)
                                    continue recipeLoop
                                    
                                }
                            } while (Recipe.findDuplicate(recipe: newRecipe) != nil)
                        }
                    }
                    recipes.append(newRecipe)
                } else {
                    return nil // JSON parsing failed
                }
            }
            return recipes
        } catch _ {
            return nil
        }
    }
}

class URLRecipeSource {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func read() -> [Recipe]? {
        do {
            let data = try NSData(contentsOf: url as URL, options: NSData.ReadingOptions.mappedIfSafe)
            return JsonRecipeParser().parse(recipesJson: data)
        } catch _ {
            return nil
        }
    }
}

class CannedRecipeSource: URLRecipeSource {
    init() {
        let path = Bundle.main.path(forResource: "recipes", ofType: "json")!
        let recipesUrl = NSURL(fileURLWithPath: path)

        super.init(url: recipesUrl)
    }
}

class WebRecipeSource: NSObject, NSURLConnectionDelegate {
    var recipesJsonData = NSMutableData()
    var completion: (([Recipe]?) -> Void)?
    
    func fetch(url: NSURL, completion: @escaping (([Recipe]?) -> Void)) {
        self.completion = completion
        
        let request = NSURLRequest(url: url as URL)
        let _ = NSURLConnection(request: request as URLRequest, delegate: self, startImmediately: true)
    }
    
    private func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        recipesJsonData.append(data as Data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        let parser = JsonRecipeParser()
        completion!(parser.parse(recipesJson: recipesJsonData))
    }
}
