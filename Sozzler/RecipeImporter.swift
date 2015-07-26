import UIKit

class RecipeImporter {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func importRecipes(url: NSURL) {
        var errors = true
        var recipeSource = URLRecipeSource(url: url)
        if let newRecipes = recipeSource.read() {
            var error: NSError?
            if CoreDataHelper.save(&error) {
                errors = false
        
                self.viewController.tabBarController!.selectedIndex = 0

                let viewControllers = self.viewController.tabBarController!.viewControllers as! [UINavigationController]

                viewControllers[0].popToRootViewControllerAnimated(false)
                viewControllers[1].popToRootViewControllerAnimated(false)

                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let recipeTableViewController = mainStoryboard.instantiateViewControllerWithIdentifier("RecipeTableViewController") as! RecipeTableViewController

                recipeTableViewController.recipeNameFilter = map(newRecipes, { $0.name })
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