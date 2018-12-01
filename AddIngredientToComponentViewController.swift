import UIKit
import CoreData

class AddIngredientToComponentViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    var ingredient: Ingredient?
    
    var searchController: UISearchController?
    var searchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension

        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableView.ScrollPosition.top, animated: false)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ingredient = (frc!.object(at: indexPath as IndexPath) as! Ingredient)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ingredientCell", for: indexPath as IndexPath) 
        let ingredient = frc!.object(at: indexPath as IndexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        
        return cell
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchText != "" {
            return []
        } else {
            return [ UITableView.indexSearch ] + frc!.sectionIndexTitles
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index > 0 {
            return frc!.section(forSectionIndexTitle: title, at: index - 1)
        } else {
            let searchBarFrame = searchController!.searchBar.frame
            tableView.scrollRectToVisible(searchBarFrame, animated: false)
            return NSNotFound
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addQuantityToComponent" {
            let nav = segue.destination as! UINavigationController
            let addQuantityToComponentViewController = nav.topViewController as! AddQuantityToComponentViewController
            let idx = tableView.indexPathForSelectedRow
            
            addQuantityToComponentViewController.ingredient = (frc!.object(at: idx!) as! Ingredient)
        }
    }
    
    func refresh() {
        let predicate: NSPredicate?

        if searchText != "" {
            predicate = NSPredicate(format: "name contains[c] %@", searchText)
        } else {
            predicate = nil
        }

        frc = Ingredient.fetchedResultsController(predicate: predicate)
        
        frc!.delegate = self
        
        do {
            // FIXME: nil seems like a bad idea
            try frc!.performFetch()
        } catch _ {
        }
                
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    func errorAlert(title: String, button: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: button, style: .default) { (action: UIAlertAction) -> Void in }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func onAdd(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add Ingredient", message: "", preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { (action: UIAlertAction) -> Void in
            let textField = alert.textFields![0] 
            let ingredientName = textField.text!
            
            if let _ = Ingredient.find(name: ingredientName) {
                self.errorAlert(title: "Ingredient already exists.", button: "Oops")
            } else {
                let ingredient = Ingredient.create(name: ingredientName)
                
                var error: NSError?
                // NOTE: unlike in IngredientTableViewController we can't save here because the moc has a partially construted, invalid Recipe
                //
                do {
                    try ingredient.validateForInsert()
                    self.refresh()
                    let indexPath = self.frc!.indexPath(forObject: ingredient)
                    self.tableView.selectRow(at: indexPath!, animated: true, scrollPosition: UITableView.ScrollPosition.middle)
                } catch let error1 as NSError {
                    error = error1
                    // FIXME:
                    // alert: could not blah blah
                    NSLog("Save Failed!: \(String(describing: error))")
                } catch {
                    fatalError()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addTextField { (textField: UITextField!) -> Void in
            textField.placeholder = "Disgusting Artichoke"
            textField.autocapitalizationType = UITextAutocapitalizationType.words
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        refresh()
    }
    
    @IBAction func unwindToAddIngredientToComponent(sender: UIStoryboardSegue)
    {
    }
}
