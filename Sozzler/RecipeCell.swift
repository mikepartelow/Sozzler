import UIKit

class RecipeCell: UITableViewCell {

    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var ingredients: UILabel!
    @IBOutlet weak var ratingView: RatingView!

    func populate(recipe: Recipe) {
        recipeName.text = recipe.name
        
        let sortedIngredientNames = recipe.sortedComponents.map({ $0.ingredient.name })
        ingredients!.text = sortedIngredientNames.joinWithSeparator(", ")
        
        ratingView!.rating = Int(recipe.rating)
        
        ratingView!.oliveHeight = 16
        ratingView!.setNeedsLayout()
        ratingView!.layoutIfNeeded()
    }
}
