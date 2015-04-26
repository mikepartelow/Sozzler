import UIKit

class DataViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func onExportRecipes(sender: UIButton) {
    }
    
    @IBAction func onImportFromWeb(sender: UIButton) {
        // FIXME: ask user whether to MERGE or REPLACE existing recipes.
        //        how to deal with dups?
        //        
        //        for now, warn and REPLACE
    }
}
