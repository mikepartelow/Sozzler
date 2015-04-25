import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let app: AppDelegate
    let moc: NSManagedObjectContext
    
    var frc: NSFetchedResultsController?
    
    required init!(coder aDecoder: NSCoder!) {
        app = UIApplication.sharedApplication().delegate as! AppDelegate
        moc = app.managedObjectContext!
        super.init(coder: aDecoder)

        if Recipe.count() == 0 {
            Recipe.populate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        refresh()
    }

    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let sortByName = UIAlertAction(title: "Sort by Name", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.app.userSettings.recipeSortOrder = .Name
            self.refresh()
        })

        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.app.userSettings.recipeSortOrder = .Rating
            self.refresh()
        })

        let sortByNumberOfIngredients = UIAlertAction(title: "Sort by Number of Ingredients", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.app.userSettings.recipeSortOrder = .NumberOfIngredients
            self.refresh()
        })

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })

        sheet.addAction(sortByName)
        sheet.addAction(sortByRating)
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

    // NSFetchedResultsControllerDelegate
    //
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecipeCell", forIndexPath: indexPath) as! UITableViewCell
        let recipe = frc!.objectAtIndexPath(indexPath) as! Recipe
        
        cell.textLabel!.text = recipe.name
        cell.detailTextLabel!.text = "detail"
        
        return cell
    }
    //
    // NSFetchedResultsControllerDelegate

    // FIXME: DRY
    func refresh() {
        // FIXME: progress indicator is needed especially during onSort()
        
        let fetchRequest = Recipe.fetchRequest()
        
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Recipes by \(app.userSettings.recipeSortOrderName)"
        
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
