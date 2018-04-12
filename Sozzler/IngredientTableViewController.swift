import UIKit
import CoreData

// http://stackoverflow.com/questions/2809192/core-data-fetchedresultscontroller-question-what-is-sections-for

class IngredientTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    let userSettings = (UIApplication.shared.delegate as! AppDelegate).userSettings

    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    
    var shouldRefresh = true
    
    var searchController: UISearchController?
    var searchText = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self

        tableView.rowHeight = UITableViewAutomaticDimension

        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableViewScrollPosition.top, animated: false)

        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "data.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "recipe.deleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("dataReset")), name: NSNotification.Name(rawValue: "recipe.updated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver("data.reset")
        NotificationCenter.default.removeObserver("recipe.deleted")
        NotificationCenter.default.removeObserver("recipe.updated")
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 32;
    }

    func dataReset() {
        shouldRefresh = true
        searchText = ""
        searchController?.isActive = false
    }

    override func viewWillAppear(_ animated: Bool) {
        if shouldRefresh {
            refresh()
        }
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
                
                if let error = CoreDataHelper.save() {
                    NSLog("Save Failed!: \(error)")
                    assert(false)
                    fatalError()
                } else {
                    self.refresh()
                    let indexPath = self.frc!.indexPath(forObject: ingredient)
                    self.tableView.selectRow(at: indexPath!, animated: true, scrollPosition: UITableViewScrollPosition.middle)
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            let ingredient = self.frc!.object(at: indexPath) as! Ingredient

            if ingredient.recipe_count > 0 {
                self.errorAlert(title: "Ingredient is used by a recipe", button: "OK")
            } else {
                CoreDataHelper.delete(obj: ingredient)
            
                if let error = CoreDataHelper.save() {
                    NSLog("Delete Failed!: \(error)")
                    assert(false)
                    fatalError()
                } else {
                    self.refresh()
                }
            }
            
            tableView.isEditing = false
        }
        
        return [ deleteAction ]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let rtvc = segue.destination as! RecipeTableViewController
        
        rtvc.navigationItem.leftBarButtonItem = nil
        rtvc.navigationItem.rightBarButtonItem = nil

        let index = tableView.indexPathForSelectedRow!
        rtvc.ingredient = frc!.object(at: index) as? Ingredient
        tableView.deselectRow(at: index, animated: false)        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath as IndexPath) 
        let ingredient = frc!.object(at: indexPath as IndexPath) as! Ingredient
        
        cell.textLabel!.text = ingredient.name
        
        let plural = ingredient.recipe_count > 1 ? "s" : ""
        cell.detailTextLabel!.text = "\(ingredient.recipe_count) recipe\(plural)"
        
        return cell
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchText != "" {
            return []
        } else {
            return [ UITableViewIndexSearch ] + frc!.sectionIndexTitles
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(52)
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
        
        navigationItem.title = "Ingredients"
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        tableView.reloadData()
        
        shouldRefresh = false
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        refresh()
    }
}
