import Foundation
import CoreData

class URLRecipeSource {
    let url: NSURL
    
    init(url: NSURL) {
        self.url = url
    }
    
    func read() -> [Recipe] {
        let recipesJson = NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
        let recipeDicts = NSJSONSerialization.JSONObjectWithData(recipesJson!, options: nil, error: nil) as! [NSDictionary]
        
        // FIXME: error reporting not just filtering
        //
        return filter(map(recipeDicts, { Recipe.create($0) }), { $0 != nil }).map { $0! }
    }
}

class CannedRecipeSource: URLRecipeSource {
    init() {
        let path = NSBundle.mainBundle().pathForResource("recipes", ofType: "json")!
        let recipesUrl = NSURL(fileURLWithPath: path)!

        super.init(url: recipesUrl)
    }
}