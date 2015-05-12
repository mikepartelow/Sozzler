import UIKit

class WebRecipeImportViewController: UIViewController {
    @IBOutlet weak var url: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    @IBAction func onImport(sender: UIButton) {
//        status label "fetching data..."
//        do progress as described: http://ux.stackexchange.com/questions/28159/is-there-a-standard-iphone-way-of-displaying-an-actionless-confirmation-message
                
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            
            // FIXME: need an alert to select URL: http://nshipster.com/uialertcontroller/
            // FIXME: need a spinner while the import does its thing : http://stackoverflow.com/questions/26881625/how-to-use-mbprogresshud-with-swift : or maybe write own? how hard can it be...
            
//            "http://sainttoad.com/muddler/recipes.json"
            
            UrlRecipeSource(url: NSURL(string: self.url!.text!)!, completion: { (recipes) -> () in
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
}
