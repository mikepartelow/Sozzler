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
        let options = JSONSerialization.WritingOptions.prettyPrinted
        
        do {
            let data = try JSONSerialization.data(withJSONObject: recipeDicts, options: options)
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                let data = string.data(using: String.Encoding.utf8.rawValue)
                let base64Data = data!.base64EncodedString(options: [])
                
                let nsdata = NSData(base64Encoded: base64Data, options: [])!
                composer.addAttachmentData(nsdata as Data, mimeType: "application/sozzler", fileName: "Sozzler Recipes.sozzler")
                
                self.completion = completion
                
                viewController.present(composer, animated: true, completion: nil)
            }
        } catch _ {
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        viewController.dismiss(animated: true, completion: nil)
        if let c = self.completion {
            c()
        }
    }
}
