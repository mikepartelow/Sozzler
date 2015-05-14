import Foundation

import UIKit
import CoreData

class CannedRecipeSource {
    func splorp() -> [Recipe] {
        let path = NSBundle.mainBundle().pathForResource("recipes", ofType: "json")!
        let url = NSURL(fileURLWithPath: path)!
        let recipesJson = NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
        let recipeDicts = NSJSONSerialization.JSONObjectWithData(recipesJson!, options: nil, error: nil) as! [NSDictionary]
        
        // FIXME: error reporting not just filtering
        //
        return filter(map(recipeDicts, { Recipe.create($0) }), { $0 != nil }).map { $0! }
    }
}

class UrlRecipeSource: NSObject, NSURLConnectionDelegate {
    private var recipesJsonData = NSMutableData()
    private let completion: (recipes: [Recipe]?) -> ()

    private let url: NSURL
    
    init(url: NSURL, completion: (recipes: [Recipe]?) -> ()) {
        self.url = url
        self.completion = completion

        super.init()
    }
    
    func fetch() {
        let request = NSURLRequest(URL: url)
        NSURLConnection(request: request, delegate: self, startImmediately: true)
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        recipesJsonData.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        var recipes: [Recipe]? = nil
        
        if let recipeDicts = NSJSONSerialization.JSONObjectWithData(recipesJsonData, options: nil, error: nil) as? [NSDictionary] {
            recipes = filter(map(recipeDicts, { Recipe.create($0) }), { $0 != nil }).map { $0! }
        }
        
        completion(recipes: recipes)
    }
}