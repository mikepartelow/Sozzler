import UIKit

class DataViewController: UIViewController {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var recipesLabel: UILabel!
    
    var exporter: RecipeExporter? // can't be local or it gets GC'd too soon => crash
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                versionLabel!.text = "Sozzler version \(version).\(build)"
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        recipesLabel!.text = "\(Recipe.count()) recipes"
        ingredientsLabel!.text = "\(Ingredient.count()) ingredients"
    }
   
    @IBAction func onImport(sender: UIButton) {
        let alert = UIAlertController(title: "Import Recipes", message: "", preferredStyle: .Alert)
        
        let importRecipes = UIAlertAction(title: "Import", style: .Default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0]
            let url = textField.text!
            
            RecipeImporter(viewController: self).importRecipes(NSURL(string: url)!)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            let app = UIApplication.sharedApplication().delegate as! AppDelegate
            textField.placeholder   = app.ONE_POINT_ONE_NEW_RECIPES_URL
            textField.text          = app.ONE_POINT_ONE_NEW_RECIPES_URL
        }
        
        alert.addAction(importRecipes)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func onImportCanned(sender: UIButton) {
        let alert = UIAlertController(title: "", message: "Restore default recipes and settings?", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings.factoryReset()
            
            CannedUnitSource().read()
            CannedRecipeSource().read()
            NSLog("recipe count: \(Recipe.count())")
            
            if let error = CoreDataHelper.save() {
                NSLog("[ON IMPORT CANNED] : \(error)")
                assert(false)
                fatalError()
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)

                self.tabBarController!.selectedIndex = 0
                
                let viewControllers = self.tabBarController!.viewControllers as! [UINavigationController]
                viewControllers[0].popToRootViewControllerAnimated(false)
                viewControllers[1].popToRootViewControllerAnimated(false)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }    
        
    @IBAction func unwindToData(sender: UIStoryboardSegue) {
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent!) {
        if event.subtype == UIEventSubtype.MotionShake {
            if userSettings.oliveAsset == "asset-olive-green" {
                userSettings.oliveAsset = "asset-olive-green-outline"
            } else if userSettings.oliveAsset == "asset-olive-green-outline" {
                userSettings.oliveAsset = "asset-olive-black"
            } else {
                userSettings.oliveAsset = "asset-olive-green"
            }
            NSNotificationCenter.defaultCenter().postNotificationName("asset.reset", object: self)
        }
    }
}
