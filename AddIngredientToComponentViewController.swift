import UIKit
import CoreData

class AddIngredientToComponentViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    var frc: NSFetchedResultsController?
    var ingredient: Ingredient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        refresh()
    }
    
    // NSFetchedResultsControllerDelegate
    //
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        ingredient = (frc!.objectAtIndexPath(indexPath) as! Ingredient)
        performSegueWithIdentifier("unwindToAddRecipe", sender: self)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ingredientCell", forIndexPath: indexPath) as! UITableViewCell
        let ingredient = frc!.objectAtIndexPath(indexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        
        return cell
    }
    //
    // NSFetchedResultsControllerDelegate

    // FIXME: DRY
    func refresh() {
        let fetchRequest = Ingredient.fetchRequest()
        
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
                
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }

}
