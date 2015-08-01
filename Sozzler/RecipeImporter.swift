import UIKit

class RecipeImporter {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func importRecipes(url: NSURL) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let addToExisting = UIAlertAction(title: "Add to Existing Recipes", style: .Default) {
            (alert: UIAlertAction!) -> Void in
            self.loadRecipes(url)
        }
        
        let replaceAll = UIAlertAction(title: "Replace All Recipes", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            var alertAreYouSure = UIAlertController(title: "", message: "Delete All Existing Recipes and Import New Recipes?", preferredStyle: .Alert)
            
            let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
                CoreDataHelper.factoryReset(save: false)
                CannedUnitSource().read()

                self.loadRecipes(url)
            }
            
            let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
            
            alertAreYouSure.addAction(doitAction)
            alertAreYouSure.addAction(cancelAction)
            
            self.viewController.presentViewController(alertAreYouSure, animated: true, completion: nil)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        sheet.addAction(addToExisting)
        sheet.addAction(replaceAll)
        sheet.addAction(cancel)
        
        viewController.presentViewController(sheet, animated: true, completion: nil)
    }
    
    func loadRecipes(url: NSURL) {
        if url.fileURL {
            let recipes = URLRecipeSource(url: url).read()
            self.saveRecipes(recipes)
        } else {
            WebRecipeSource().fetch(url, completion: { (recipes: [Recipe]?) -> Void in
                self.saveRecipes(recipes)
            })
        }
    }
    
    func saveRecipes(newRecipes: [Recipe]?) {
        var errors = true
        if newRecipes != nil {
            var error: NSError?
            if CoreDataHelper.save(&error) {
                errors = false
        
                self.viewController.tabBarController!.selectedIndex = 0

                let viewControllers = self.viewController.tabBarController!.viewControllers as! [UINavigationController]

                viewControllers[0].popToRootViewControllerAnimated(false)
                viewControllers[1].popToRootViewControllerAnimated(false)

                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let recipeTableViewController = mainStoryboard.instantiateViewControllerWithIdentifier("RecipeTableViewController") as! RecipeTableViewController

                recipeTableViewController.recipeNameFilter = map(newRecipes!, { $0.name })
                recipeTableViewController.navigationItem.leftBarButtonItem = nil
                recipeTableViewController.navigationItem.rightBarButtonItem = nil
                viewControllers[0].pushViewController(recipeTableViewController, animated: true)

                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)

            } else {
                NSLog("\(error)")
            }
        }

        if errors {
            CoreDataHelper.rollback()
            var alert = UIAlertController(title: "", message: "Errors in Sozzler file, canceling import.", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Default) { (action: UIAlertAction!) -> Void in }
            alert.addAction(cancelAction)
            viewController.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
}