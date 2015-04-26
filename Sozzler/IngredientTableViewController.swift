import UIKit
import CoreData

class IngredientTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let userSettings = (UIApplication.sharedApplication().delegate as! AppDelegate).userSettings
    
    var frc: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        refresh()
    }
    
    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.ingredientSortOrder = .Name
            self.refresh()
        })
        
        let sortByNumberOfIngredients = UIAlertAction(title: "Sort by Number of Recipes", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.ingredientSortOrder = .NumberOfRecipes
            self.refresh()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        sheet.addAction(sortByName)
        sheet.addAction(sortByNumberOfIngredients)
        sheet.addAction(cancel)
        
        presentViewController(sheet, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navController = segue.destinationViewController as! UINavigationController
        let rtvc = navController.topViewController! as! RecipeTableViewController
        
        let index = tableView.indexPathForSelectedRow()!
        rtvc.ingredient = frc!.objectAtIndexPath(index) as? Ingredient
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
        let cell = tableView.dequeueReusableCellWithIdentifier("IngredientCell", forIndexPath: indexPath) as! UITableViewCell
        let ingredient = frc!.objectAtIndexPath(indexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        cell.detailTextLabel!.text = "\(ingredient.recipe_count) recipes"
        return cell
    }
    //
    // NSFetchedResultsControllerDelegate
    
    // FIXME: DRY
    func refresh() {
        // FIXME: progress indicator is needed especially during onSort()
        //        modal grey translucent alert with swriy : howto?
        frc = Ingredient.fetchedResultsController()
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Ingredients by \(userSettings.ingredientSortOrderName)"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
}
