import UIKit
import MessageUI

class DataViewController: UIViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onExportRecipes(sender: UIButton) {
        var composer = MFMailComposeViewController()
        
        composer.mailComposeDelegate = self
        composer.setSubject("Sozzler recipes export")
        composer.setMessageBody("my recipes in JSON format", isHTML: true)

        // FIXME: set default addressee to "device owner" if there's an API for that
        // FIXME: is JSON "user friendly"?
        
        // need to connect physical device to really send email
        //
        // https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSJSONSerialization_Class/index.html
        // https://medium.com/swift-programming/4-json-in-swift-144bf5f88ce4
        // http://www.raywenderlich.com/1980/email-tutorial-for-ios-how-to-import-and-export-app-data-via-email-in-your-ios-app
        
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
//
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
    
//    @IBAction func onImportFromWeb(sender: UIButton) {
//        show modal to get url
//        status label "fetching data..."
//        do progress as described: http://ux.stackexchange.com/questions/28159/is-there-a-standard-iphone-way-of-displaying-an-actionless-confirmation-message
//        
//        
//        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
//        
//        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
//            CoreDataHelper.factoryReset()
//            
//            // FIXME: need an alert to select URL: http://nshipster.com/uialertcontroller/
//            // FIXME: need a spinner while the import does its thing : http://stackoverflow.com/questions/26881625/how-to-use-mbprogresshud-with-swift : or maybe write own? how hard can it be...
//            
//            UrlRecipeSource(url: NSURL(string: "http://sainttoad.com/muddler/recipes.json")!, completion: { (recipes) -> () in
//                // FIXME: handle errors
//                NSLog("\(recipes?.count)")
//                CoreDataHelper.save(nil)
//                
//                NSNotificationCenter.defaultCenter().postNotificationName("data.reset", object: self)
//
//                // FIXME: tell user it worked
//            }).fetch()
//        }
//        
//        let cancelAction = UIAlertAction(title: "Forget it", style: .Default) { (action: UIAlertAction!) -> Void in }
//        
//        alert.addAction(doitAction)
//        alert.addAction(cancelAction)
//        
//        presentViewController(alert, animated: true, completion: nil)
//    }
    
    @IBAction func onImportCanned(sender: UIButton) {
        var alert = UIAlertController(title: "", message: "Imported recipes will replace all existing recipes.", preferredStyle: .Alert)
        
        let doitAction = UIAlertAction(title: "Do it", style: .Destructive) { (action: UIAlertAction!) -> Void in
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
    
    @IBAction func unwindToData(sender: UIStoryboardSegue) {
    }
    

}
