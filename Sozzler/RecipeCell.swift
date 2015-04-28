import UIKit

class RecipeCell: UITableViewCell {

    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var ingredients: UILabel!
    @IBOutlet weak var ratingView: RatingView!

    var recipe: Recipe?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        recipeName!.text = recipe!.name
        
        let sortedIngredientNames = map(sorted(recipe!.components.allObjects as! [Component], { (l: Component, r: Component) in l.ingredient.name < r.ingredient.name }), { $0.ingredient.name })
        ingredients!.text = ", ".join(sortedIngredientNames)
        
        ratingView!.rating = Int(recipe!.rating)

        super.layoutSubviews()
    }
}
