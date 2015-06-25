import UIKit
import MessageUI
import AddressBook

class RecipeExporter: NSObject, MFMailComposeViewControllerDelegate {
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    func export(recipes: [Recipe]) {
        let composer = MFMailComposeViewController()
        let messageSubject = recipes.count == 1 ? "Sozzler Recipe" : "Sozzler Recipes"
        let messageBody = recipes.count == 1 ? recipes[0].name : "My Sozzler Recipes"
        
        composer.mailComposeDelegate = self
        composer.setSubject(messageSubject)
        composer.setMessageBody(messageBody, isHTML: true)
        
        let recipeDicts = map(recipes, { NSMutableDictionary(recipe: $0 as Recipe) })
        let options = NSJSONWritingOptions.PrettyPrinted
        
        if let data = NSJSONSerialization.dataWithJSONObject(recipeDicts, options: options, error: nil) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let data = string.dataUsingEncoding(NSUTF8StringEncoding)
                let base64Data = data!.base64EncodedDataWithOptions(.allZeros)
                
                composer.addAttachmentData(NSData(base64EncodedData: base64Data, options: .allZeros), mimeType: "application/sozzler", fileName: "Sozzler Recipes.sozzler")
                
                viewController.presentViewController(composer, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
    }    
}
