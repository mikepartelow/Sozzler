import UIKit

class DataViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onExportRecipes(sender: UIButton) {
    }
    
    @IBAction func onImportFromWeb(sender: UIButton) {
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Default) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            // FIXME: need an alert to select URL
            // FIXME: need a spinner while the import does its thing
            
            UrlRecipeSource(url: NSURL(string: "http://sainttoad.com/muddler/recipes.json")!, completion: { (recipes) -> () in
                // FIXME: handle errors
                NSLog("\(recipes?.count)")
                CoreDataHelper.save(nil)
                
                // FIXME: tell user it worked
                
                // FIXME: tell controllers that they must reload()
            }).fetch()
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func onImportCanned(sender: UIButton) {
        // FIXME: ask user whether to MERGE or REPLACE existing recipes.
        //        how to deal with dups?
        //
        //        for now, warn and REPLACE
        
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Default) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            CannedRecipeSource().fetch()
            
            // FIXME: handle errors
            CoreDataHelper.save(nil)
            
            // FIXME: tell user it worked
            
            // FIXME: tell controllers that they must reload()
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}
