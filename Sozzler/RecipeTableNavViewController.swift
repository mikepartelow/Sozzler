import UIKit

class RecipeTableNavViewController: UINavigationController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // FIXME: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIViewController_Class/index.html
        // A view controller is the sole owner of its view and any subviews it creates. It is responsible for creating those views and for relinquishing ownership of them at the appropriate times
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "RecipeTableViewController") as! RecipeTableViewController

        viewController.navigationItem.leftBarButtonItem = nil
        viewController.navigationItem.rightBarButtonItem = nil
        
        pushViewController(viewController, animated: false)
    }
}
