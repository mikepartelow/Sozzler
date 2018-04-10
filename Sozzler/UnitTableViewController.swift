import UIKit
import CoreData

class UnitTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    var shouldRefresh = false
    let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        refresh()

        tableView.isEditing = true
        
//        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        
        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "data.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "recipe.deleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "recipe.updated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver("data.reset")
        NotificationCenter.default.removeObserver("recipe.deleted")
        NotificationCenter.default.removeObserver("recipe.updated")
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 56;
    }
    
    func dataReset() {
        shouldRefresh = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }
    
    // FIXME: DRY
    func errorAlert(title: String, button: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: button, style: .default) { (action: UIAlertAction) -> Void in }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
        
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            let unit = self.frc!.object(at: indexPath) as! Unit
            
            if unit.recipe_count > 0 {
                self.errorAlert(title: "Unit is used by a recipe", button: "OK")
            } else {
                CoreDataHelper.delete(recipe: unit)
                
                let remainingUnits = (self.frc!.fetchedObjects as! [Unit]).filter { $0 != unit }
                for (index, unit) in remainingUnits.enumerate() {
                    unit.index = Int16(index)
                }
                
                if let error = CoreDataHelper.save() {
                    NSLog("Delete Failed!: \(error)")
                    assert(false)
                    fatalError()
                } else {
                    self.refresh()
                }
            }
            
            // this is intentional, believe it or not.
            //
            tableView.isEditing = false
            tableView.isEditing = true
        }
        
        return [ deleteAction ]
    }
    
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let unit = frc!.object(at: indexPath as IndexPath) as! Unit
        return unit.name != ""

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editUnit" {
            let navController = segue.destination as! UINavigationController
            let euvc = navController.topViewController! as! EditUnitViewController
            let index = tableView.indexPathForSelectedRow!
            
            euvc.unit = frc!.object(at: index) as? Unit
            
            tableView.deselectRow(at: index, animated: false)
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitCell", for: indexPath as IndexPath) 
        let unit = frc!.object(at: indexPath as IndexPath) as! Unit
        
        cell.textLabel!.text = unit.plural_name != unit.name ? "\(unit.name) / \(unit.plural_name)" : unit.name
        
        return cell
    }
    
    override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
        return frc!.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return frc!.section(forSectionIndexTitle: title, at: index)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(52)
    }
    
    func refresh() {
        frc = Unit.fetchedResultsController()
        
        frc!.delegate = self
        
        do {
            // FIXME: nil seems like a bad idea
            try frc!.performFetch()
        } catch _ {
        }
        
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
            sortedUnits[toIndexPath.row..<fromIndexPath.row].map({ (unit) in
                unit.index += 1
            })
        } else if fromIndexPath.row < toIndexPath.row {
            sortedUnits[fromIndexPath.row+1...toIndexPath.row].map({ (unit) in
                unit.index -= 1
            })
        }

        sortedUnits[fromIndexPath.row].index = Int16(toIndexPath.row)        

        var error: NSError?
        do {
            try moc.save()
            assert(error == nil)
            refresh()
        } catch let error1 as NSError {
            error = error1
            // FIXME: DO SOMETHING
        }

    }
    
    @IBAction func unwindToUnitTable(sender: UIStoryboardSegue) {
        if let euvc = sender.source as? EditUnitViewController {
            if euvc.added {
                self.refresh()
                let indexPath = self.frc!.indexPath(forObject: euvc.unit!)
                self.tableView.selectRow(at: indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            }
        }
    }
}

