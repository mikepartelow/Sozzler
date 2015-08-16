import UIKit
import MessageUI
import AddressBook

class RecipeExporter: NSObject, MFMailComposeViewControllerDelegate {
    let viewController: UIViewController
    var completion: (() -> ())?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    func export(recipes: [Recipe], completion: (() -> ())? = nil) {
        let composer = MFMailComposeViewController()
        let messageSubject = recipes.count == 1 ? "Sozzler Recipe" : "Sozzler Recipes"
        let messageBody = recipes.count == 1 ? recipes[0].name : "My Sozzler Recipes"
        
        composer.mailComposeDelegate = self
        composer.setSubject(messageSubject)
        composer.setMessageBody(messageBody, isHTML: true)
        
        let recipeDicts = recipes.map({ NSMutableDictionary(recipe: $0 as Recipe) })
        let options = NSJSONWritingOptions.PrettyPrinted
        
        do {
            let data = try NSJSONSerialization.dataWithJSONObject(recipeDicts, options: options)
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let base64Data = data!.base64EncodedDataWithOptions([])
                
                let nsdata = NSData(base64EncodedData: base64Data, options: [])!
                composer.addAttachmentData(nsdata, mimeType: "application/sozzler", fileName: "Sozzler Recipes.sozzler")
                
                self.completion = completion
                
                viewController.presentViewController(composer, animated: true, completion: nil)
            }
        } catch _ {
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if let c = self.completion {
            c()
        }
    }
}
