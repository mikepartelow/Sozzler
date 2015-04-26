import Foundation

import UIKit
import CoreData

protocol RecipeSource {
    func fetch() -> [Recipe]
}

class CannedRecipeSource: RecipeSource {
    func fetch() -> [Recipe] {
        let recipesDict = [
            [
                "name"          : "Disgusting Artichoke",
                "rating"        : 5,
                "notes"         : "really not as bad as it sounds",
                "components"    : [
                    [
                        "quantity"      : "1/2",
                        "measure"       : "oz",
                        "ingredient"    : "artichoke"
                    ],
                    [
                        "quantity"      : "2",
                        "measure"       : "oz",
                        "ingredient"    : "disgusting"
                    ]
                ]
            ],

            [
                "name"          : "Disgusting Asparagus",
                "rating"        : 4,
                "notes"         : "worse than it sounds",
                "components"    : [
                    [
                        "quantity"      : "1",
                        "measure"       : "oz",
                        "ingredient"    : "asparagus"
                    ],
                    [
                        "quantity"      : "1/2",
                        "measure"       : "oz",
                        "ingredient"    : "lemon juice"
                    ]
                ]
            ]
            
        ]
        
        // FIXME: error reporting not just filtering
        //
        return filter(map(recipesDict, { Recipe.create($0) }), { $0 != nil }).map { $0! }
    }
}

//
//class RecipeImporter: NSObject, NSURLConnectionDelegate {
//    private var recipesJsonData = NSMutableData()
//    private var finished: ((success: Bool) -> ())?
//    
//    private let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
//    
//    override init() {}
//    
//    func injectCannedRecipes() {
//        let recipes = [
//            [
//                "name"          : "Disgusting Artichoke",
//                "rating"        : 5,
//                "notes"         : "really not as bad as it sounds",
//                "components"    : [
//                    [
//                        "quantity"      : "1/2",
//                        "measure"       : "oz",
//                        "ingredient"    : "artichoke"
//                    ],
//                    [
//                        "quantity"      : "2",
//                        "measure"       : "oz",
//                        "ingredient"    : "disgusting"
//                    ]
//                ]
//            ],
//            
//            [
//                "name"          : "Disgusting Asparagus",
//                "rating"        : 4,
//                "notes"         : "worse than it sounds",
//                "components"    : [
//                    [
//                        "quantity"      : "1",
//                        "measure"       : "oz",
//                        "ingredient"    : "asparagus"
//                    ],
//                    [
//                        "quantity"      : "1/2",
//                        "measure"       : "oz",
//                        "ingredient"    : "lemon juice"
//                    ]
//                ]
//            ]
//            
//        ]
//        
//        saveRecipes(recipes)
//    }
//    
//    func fetch(url: String,
//        started: () -> (),
//        finished: (success: Bool) -> ()) {
//            
//            self.finished = finished
//            
//            started()
//            
//            let request = NSURLRequest(URL: NSURL(string: url)!)
//            let connection = NSURLConnection(request: request, delegate: self, startImmediately: true)!
//    }
//    
//    func connection(connection: NSURLConnection!, didReceiveData data: NSData!){
//        recipesJsonData.appendData(data)
//    }
//    
//    func connectionDidFinishLoading(connection: NSURLConnection!) {
//        if let recipes = NSJSONSerialization.JSONObjectWithData(recipesJsonData, options: nil, error: nil) as? [NSDictionary] {
//            saveRecipes(recipes)
//        }
//    }
//    
//    func saveRecipes(recipes: [NSDictionary]) {
//        for recipeDict in recipes {
//            Recipe.fromDictionary(recipeDict, context: context)
//        }
//        
//        var success = false
//        var error: NSError?
//        
//        if context.save(&error) {
//            success = true
//        } else {
//            // FIXME: unacceptable
//            println("Could not save \(error), \(error?.userInfo)")
//        }
//        
//        if let f = finished {
//            f(success: success)
//        }
//    }
//    
//}