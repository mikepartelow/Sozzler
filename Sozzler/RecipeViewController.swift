import UIKit

class RecipeViewController: UIViewController {
    var recipe: Recipe?
    
    @IBOutlet weak var recipeTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recipeTextView!.text = recipe!.string
        navigationItem.title = recipe!.name
    }
}
