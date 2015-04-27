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
            // FIXME: need a spinner while the import does its thing : http://stackoverflow.com/questions/26881625/how-to-use-mbprogresshud-with-swift : or maybe write own? how hard can it be...
            
            UrlRecipeSource(url: NSURL(string: "http://sainttoad.com/muddler/recipes.json")!, completion: { (recipes) -> () in
                // FIXME: handle errors
                NSLog("\(recipes?.count)")
                CoreDataHelper.save(nil)
                
                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)

                // FIXME: tell user it worked
            }).fetch()
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func onImportCanned(sender: UIButton) {
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Default) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            CannedRecipeSource().splorp() // splorp is the sound of canned food leaving the can
            
            // FIXME: handle errors
            CoreDataHelper.save(nil)
            
            NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)

            
            // FIXME: tell user it worked            
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}
