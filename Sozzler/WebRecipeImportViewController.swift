import UIKit

class WebRecipeImportViewController: UIViewController {
    @IBOutlet weak var url: UITextField!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        progress.progress = 0
    }
    
    @IBAction func onImport(sender: UIButton) {
//        status label "fetching data..."

//        do progress as described: http://ux.stackexchange.com/questions/28159/is-there-a-standard-iphone-way-of-displaying-an-actionless-confirmation-message
                
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
            self.progress.progress += 0.25
            
            CoreDataHelper.factoryReset()
            
            self.progress.progress += 0.25
            
            
//            "http://sainttoad.com/muddler/recipes.json"
            
            UrlRecipeSource(url: NSURL(string: self.url!.text!)!, completion: { (recipes) -> () in
                self.progress.progress += 0.50

                // FIXME: handle errors
                NSLog("\(recipes?.count)")
                CoreDataHelper.save(nil)
                
                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)
                
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    // FIXME: http://stackoverflow.com/questions/24659845/unwind-segue-and-nav-button-items-not-triggering-after-tab-bar-controller-added
                    self.performSegueWithIdentifier("unwindToRecipes", sender: self)
                })
            }).fetch()
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}
