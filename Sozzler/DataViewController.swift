import UIKit
import MessageUI
import AddressBook

class DataViewController: UIViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onExportRecipes(sender: UIButton) {
        var composer = MFMailComposeViewController()
        
        composer.mailComposeDelegate = self
        composer.setSubject("Sozzler recipes export")
        composer.setMessageBody("my recipes in JSON format", isHTML: true)
        
        let recipeDicts = map(Recipe.all(), { NSMutableDictionary(recipe: $0 as Recipe) })
        let options = NSJSONWritingOptions.PrettyPrinted
        
        if let data = NSJSONSerialization.dataWithJSONObject(recipeDicts, options: options, error: nil) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                NSLog("\(string)")

                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let base64Data = data!.base64EncodedDataWithOptions(.allZeros)

                composer.addAttachmentData(NSData(base64EncodedData: base64Data, options: .allZeros), mimeType: "application/json", fileName: "recipe.json")
                
                presentViewController(composer, animated: true, completion: nil)
            }
        }
    }

    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        dismissViewControllerAnimated(true, completion: nil)
    }
   
    @IBAction func onImportCanned(sender: UIButton) {
        var alert = UIAlertController(title: "", message: "Restore default recipes and settings?", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
            CoreDataHelper.factoryReset()
            (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings.factoryReset()

            CannedRecipeSource().splorp() // splorp is the sound of canned food leaving the can
            
            // FIXME: handle errors
            CoreDataHelper.save(nil)
            
            NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)
            self.tabBarController!.selectedIndex = 0
        }
        
        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
        
        alert.addAction(doitAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func unwindToData(sender: UIStoryboardSegue) {
    }
    

}
