import UIKit
import CoreData

class RecipeTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var frc: NSFetchedResultsController?
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        
        if Recipe.count(moc) == 0 {
            Recipe.populate(moc)
        }
        
        refresh()
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
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
}
