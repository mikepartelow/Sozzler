import UIKit
import CoreData

class UnitTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var frc: NSFetchedResultsController?
    var shouldRefresh = false
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        refresh()

        tableView.editing = true
        
//        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "data.reset", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "recipe.deleted", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataReset", name: "recipe.updated", object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver("data.reset")
        NSNotificationCenter.defaultCenter().removeObserver("recipe.deleted")
        NSNotificationCenter.defaultCenter().removeObserver("recipe.updated")
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56;
    }
    
    func dataReset() {
        shouldRefresh = true
    }
    
    override func viewWillAppear(animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }
    
    // FIXME: DRY
    func errorAlert(title: String, button: String) {
        var alert = UIAlertController(title: title, message: "", preferredStyle: .Alert)
        let action = UIAlertAction(title: button, style: .Default) { (action: UIAlertAction!) -> Void in }
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
        
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            let unit = self.frc!.objectAtIndexPath(indexPath) as! Unit
            
            if unit.recipe_count > 0 {
                self.errorAlert("Unit is used by a recipe", button: "OK")
            } else {
                CoreDataHelper.delete(unit)
                
                var remainingUnits = filter(self.frc!.fetchedObjects as! [Unit]) { $0 != unit }                
                for (index, unit) in enumerate(remainingUnits) {
                    unit.index = Int16(index)
                }
                
                var error: NSError?
                if CoreDataHelper.save(&error) {
                    assert(error == nil)
                    self.refresh()
                } else {
                    // FIXME:
                    // alert: could not blah blah
                    NSLog("Delete Failed!: \(error)")
                }
            }
            
            // this is intentional, believe it or not.
            //
            tableView.editing = false
            tableView.editing = true
        }
        
        return [ deleteAction ]
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let unit = frc!.objectAtIndexPath(indexPath) as! Unit
        return unit.name != ""

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editUnit" {
            let navController = segue.destinationViewController as! UINavigationController
            let euvc = navController.topViewController! as! EditUnitViewController
            let index = tableView.indexPathForSelectedRow()!
            
            euvc.unit = frc!.objectAtIndexPath(index) as? Unit
            
            tableView.deselectRowAtIndexPath(index, animated: false)
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects!
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UnitCell", forIndexPath: indexPath) as! UITableViewCell
        let unit = frc!.objectAtIndexPath(indexPath) as! Unit
        
        cell.textLabel!.text = unit.plural_name != unit.name ? "\(unit.name) / \(unit.plural_name)" : unit.name
        
        return cell
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return frc!.sectionIndexTitles
    }
    
    override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return frc!.sectionForSectionIndexTitle(title, atIndex: index)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(52)
    }
    
    func refresh() {
        let predicate: NSPredicate?
        frc = Unit.fetchedResultsController()
        
        frc!.delegate = self
        
        // FIXME: nil seems like a bad idea
        frc!.performFetch(nil)
        
        navigationItem.title = "Units"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
        
        shouldRefresh = false
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        NSLog("\(fromIndexPath.row) => \(toIndexPath.row)")

        if fromIndexPath == toIndexPath {
            return
        }

        var sortedUnits = frc!.fetchedObjects as! [Unit]
        
        if toIndexPath.row < fromIndexPath.row {
            map(sortedUnits[toIndexPath.row..<fromIndexPath.row], { (unit) in
                unit.index += 1
            })
        } else if fromIndexPath.row < toIndexPath.row {
            map(sortedUnits[fromIndexPath.row+1...toIndexPath.row], { (unit) in
                unit.index -= 1
            })
        }

        sortedUnits[fromIndexPath.row].index = Int16(toIndexPath.row)        

        var error: NSError?
        if moc.save(&error) {
            assert(error == nil)
            refresh()
        } else {
            // FIXME: DO SOMETHING
        }

    }
    
    @IBAction func unwindToUnitTable(sender: UIStoryboardSegue) {
        if let euvc = sender.sourceViewController as? EditUnitViewController {
            if euvc.added {
                self.refresh()
                let indexPath = self.frc!.indexPathForObject(euvc.unit!)
                self.tableView.selectRowAtIndexPath(indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
            }
        }
    }
}
