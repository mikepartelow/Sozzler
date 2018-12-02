import UIKit

class RecipeViewController: UIViewController {
    var recipe: Recipe?
    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeTextView: UITextView!
    
    @IBOutlet weak var recipeTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    override func viewDidLoad() {
        super.viewDidLoad()
        render()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editRecipe" {
            let nav = segue.destination as! UINavigationController
            let addRecipeViewController = nav.topViewController as! AddRecipeViewController
            
            addRecipeViewController.recipe = recipe
        }
    }
    
    func render() {
        recipeName!.text = recipe!.name
        
        let sortedComponents = recipe!.sortedComponents
        let componentText = sortedComponents.map({ $0.string }).joined(separator: "\n")
        recipeTextView!.text = "\(componentText)\n\n\(recipe!.text)"
        ratingView!.rating = Int(recipe!.rating)
        
        let fit = recipeTextView.sizeThatFits(recipeTextView.contentSize).height
        recipeTextViewHeight.constant = fit
    }
    
    @IBAction func unwindToRecipe(_ sender: UIStoryboardSegue)
    {
        render()
    }    
}
