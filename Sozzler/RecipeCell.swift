import UIKit

class RecipeCell: UITableViewCell {

    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var ingredients: UILabel!
    @IBOutlet weak var ratingView: RatingView!

    func populate(recipe: Recipe) {
        recipeName.text = recipe.name
        
        let sortedIngredientNames = map(sorted(recipe.components.allObjects as! [Component], { (l: Component, r: Component) in l.ingredient.name < r.ingredient.name }), { $0.ingredient.name })
        ingredients!.text = ", ".join(sortedIngredientNames)
        
        ratingView!.rating = Int(recipe.rating)
//        super.layoutSubviews()
    }
}
