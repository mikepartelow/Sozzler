import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    var frc: NSFetchedResultsController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        
        if Recipe.count(moc) == 0 {
            Recipe.populate(moc)
        }
        
        refresh()
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

    func refresh() {
        let fetchRequest = Recipe.fetchRequest()
        
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Recipes"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
}
