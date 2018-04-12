import UIKit

class RecipeImporter {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func importRecipes(url: NSURL) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let addToExisting = UIAlertAction(title: "Add to Existing Recipes", style: .default) {
            (alert: UIAlertAction) -> Void in
            self.loadRecipes(url: url)
        }
        
        let replaceAll = UIAlertAction(title: "Replace All Recipes", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
            
            let alertAreYouSure = UIAlertController(title: "", message: "Delete All Existing Recipes and Import New Recipes?", preferredStyle: .alert)
            
            let doitAction = UIAlertAction(title: "Do it", style: .destructive) { (action: UIAlertAction) -> Void in
                CoreDataHelper.factoryReset(save: false)
                CannedUnitSource().read()

                self.loadRecipes(url: url)
            }
            
            let cancelAction = UIAlertAction(title: "Forget it", style: .default) { (action: UIAlertAction) -> Void in }
            
            alertAreYouSure.addAction(doitAction)
            alertAreYouSure.addAction(cancelAction)
            
            self.viewController.present(alertAreYouSure, animated: true, completion: nil)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction) -> Void in
        })
        
        sheet.addAction(addToExisting)
        sheet.addAction(replaceAll)
        sheet.addAction(cancel)
        
        viewController.present(sheet, animated: true, completion: nil)
    }
    
    func loadRecipes(url: NSURL) {
        if url.isFileURL {
            let recipes = URLRecipeSource(url: url).read()
            self.saveRecipes(newRecipes: recipes)
        } else {
            WebRecipeSource().fetch(url: url, completion: { (recipes: [Recipe]?) -> Void in
                self.saveRecipes(newRecipes: recipes)
            })
        }
    }
    
    func saveRecipes(newRecipes: [Recipe]?) {
        var errors = true
        if newRecipes != nil {
            
            if let error = CoreDataHelper.save() {
                NSLog("\(error)")
            } else {
                errors = false
        
                self.viewController.tabBarController!.selectedIndex = 0

                let viewControllers = self.viewController.tabBarController!.viewControllers as! [UINavigationController]

                viewControllers[0].popToRootViewController(animated: false)
                viewControllers[1].popToRootViewController(animated: false)

                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let recipeTableViewController = mainStoryboard.instantiateViewController(withIdentifier: "RecipeTableViewController") as! RecipeTableViewController

                recipeTableViewController.recipeNameFilter = (newRecipes!).map({ $0.name })
                recipeTableViewController.navigationItem.leftBarButtonItem = nil
                recipeTableViewController.navigationItem.rightBarButtonItem = nil
                viewControllers[0].pushViewController(recipeTableViewController, animated: true)

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "data.reset"), object: self)
            }
        }

        if errors {
            CoreDataHelper.rollback()
            let alert = UIAlertController(title: "", message: "Errors in Sozzler file, canceling import.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in }
            alert.addAction(cancelAction)
            viewController.present(alert, animated: true, completion: nil)
        }
        
    }
}
