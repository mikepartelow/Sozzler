import UIKit

class DataViewController: UIViewController {
    let userSettings = (UIApplication.shared.delegate as! AppDelegate).userSettings
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ingredientsLabel: UILabel!
    @IBOutlet weak var recipesLabel: UILabel!
    
    var exporter: RecipeExporter? // can't be local or it gets GC'd too soon => crash
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                versionLabel!.text = "Sozzler version \(version).\(build)"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        recipesLabel!.text = "\(Recipe.count()) recipes"
        ingredientsLabel!.text = "\(Ingredient.count()) ingredients"
    }
   
    @IBAction func onImport(sender: UIButton) {
        let alert = UIAlertController(title: "Import Recipes", message: "", preferredStyle: .alert)
        
        let importRecipes = UIAlertAction(title: "Import", style: .default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0]
            let url = textField.text!
            
            RecipeImporter(viewController: self).importRecipes(url: NSURL(string: url)!)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action: UIAlertAction!) -> Void in
        }
        
        alert.addTextField { (textField: UITextField!) -> Void in
            let app = UIApplication.shared.delegate as! AppDelegate
            textField.placeholder   = app.ONE_POINT_ONE_NEW_RECIPES_URL
            textField.text          = app.ONE_POINT_ONE_NEW_RECIPES_URL
        }
        
        alert.addAction(importRecipes)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onImportCanned(sender: UIButton) {
        let alert = UIAlertController(title: "", message: "Restore default recipes and settings?", preferredStyle: .alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .destructive) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            (UIApplication.shared.delegate as! AppDelegate).userSettings.factoryReset()
            
            CannedUnitSource().read()
            CannedRecipeSource().read()
            NSLog("recipe count: \(Recipe.count())")
            
            if let error = CoreDataHelper.save() {
                NSLog("[ON IMPORT CANNED] : \(error)")
                assert(false)
                fatalError()
            } else {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "data.reset"), object: self)

                self.tabBarController!.selectedIndex = 0
                
                let viewControllers = self.tabBarController!.viewControllers as! [UINavigationController]
                viewControllers[0].popToRootViewController(animated: false)
                viewControllers[1].popToRootViewController(animated: false)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }    
        
    @IBAction func unwindToData(sender: UIStoryboardSegue) {
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent!) {
        if event.subtype == UIEventSubtype.motionShake {
            if userSettings.oliveAsset == "asset-olive-green" {
                userSettings.oliveAsset = "asset-olive-green-outline"
            } else if userSettings.oliveAsset == "asset-olive-green-outline" {
                userSettings.oliveAsset = "asset-olive-black"
            } else {
                userSettings.oliveAsset = "asset-olive-green"
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "asset.reset"), object: self)
        }
    }
}
