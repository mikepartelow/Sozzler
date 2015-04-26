import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    required init!(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)

        if Recipe.count() == 0 {
            Recipe.populate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self

        // FIXME: use this to add the Sort button when we're root view controller, but not when we're coming from IngredientTable
        //        IngredientTable should display Back

        //        navigationItem.leftBarButtonItem =

        tableView.registerNib(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableViewAutomaticDimension

        refresh()
    }

    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Rating
            self.refresh()
        })

        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.refresh()
        })

        let sortByNumberOfIngredients = UIAlertAction(title: "Sort by Number of Ingredients", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .NumberOfIngredients
            self.refresh()
        })

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })

        sheet.addAction(sortByRating)
        sheet.addAction(sortByName)
        sheet.addAction(sortByNumberOfIngredients)
        sheet.addAction(cancel)

        presentViewController(sheet, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        
        if segue.identifier == "recipeDetails" {
            let rvc = navController.topViewController! as! RecipeViewController
            let index = tableView.indexPathForSelectedRow()!
            rvc.recipe = frc!.objectAtIndexPath(index) as? Recipe
        }
    }

    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 88;
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("recipeDetails", sender: self)
    }
    
    // NSFetchedResultsControllerDelegate
    //
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipeCell", forIndexPath: indexPath) as! RecipeCell
        let recipe = frc!.objectAtIndexPath(indexPath) as! Recipe
        
        cell.recipeName!.text = recipe.name
        cell.ingredients!.text = "detail"
        cell.ratingView!.rating = Int(recipe.rating)
        
        return cell
    }
    //
    // NSFetchedResultsControllerDelegate

    // FIXME: DRY
    func refresh() {
        // FIXME: progress indicator is needed especially during onSort()
        //        modal grey translucent alert with swriy : howto?

        let predicate: NSPredicate?
        if ingredient != nil {
            predicate = NSPredicate(format: "ANY components.ingredient.name == %@", ingredient!.name)
            navigationItem.title = "Recipes with \(ingredient!.name)"
        } else {
            predicate = nil
            navigationItem.title = "Recipes by \(userSettings.recipeSortOrderName)"
        }
        
        frc = Recipe.fetchedResultsController(predicate: predicate)
        frc!.delegate = self

        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    @IBAction func unwindToRecipes(sender: UIStoryboardSegue)
    {
        if let arvc = sender.sourceViewController as? AddRecipeViewController {
            if arvc.added {
                refresh()
            }
        }
    }
}
