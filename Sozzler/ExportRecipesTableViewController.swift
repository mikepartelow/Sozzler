import UIKit
import CoreData

class ExportRecipesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    let userSettings = (UIApplication.shared.delegate as! AppDelegate).userSettings
    
    var exporter: RecipeExporter?
    
    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    var recipeNameFilter: [String]?
    
    var shouldRefresh = true
    var shouldScroll = true
    
    var searchController: UISearchController?
    var searchText = ""
    
    var selectedRecipes = Set<String>(Recipe.all().map({ $0.name }))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "RecipeCell", bundle: nil), forCellReuseIdentifier: "RecipeCell")
        tableView.rowHeight = UITableView.automaticDimension
        
//        navigationItem.title = "Export"

        definesPresentationContext = true
        refresh()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController!.searchResultsUpdater = self
        searchController!.searchBar.delegate = self
        searchController!.dimsBackgroundDuringPresentation = false
        
        tableView.tableHeaderView = searchController!.searchBar
        searchController!.searchBar.sizeToFit()
        

        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.onCancel))
        let sort = UIBarButtonItem(title: "Sort", style: .plain, target: self, action: #selector(self.onSort))
        
        navigationItem.leftBarButtonItems = [cancel, sort]
        
        let selectAll = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(self.onSelectAll))
        let export = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(self.onDone))
        
        navigationItem.rightBarButtonItems = [export, selectAll]
        
        
        if (frc?.sections?.count)! > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableView.ScrollPosition.top, animated: false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataReset), name: NSNotification.Name(rawValue: "data.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataReset), name: NSNotification.Name(rawValue: "asset.reset"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.recipeUpdated), name: NSNotification.Name(rawValue: "recipe.updated"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver("data.reset")
        NotificationCenter.default.removeObserver("asset.reset")
        NotificationCenter.default.removeObserver("recipe.updated")
    }
    
    @objc func dataReset() {
        shouldScroll = true
        searchText = ""
        searchController?.isActive = false
        refresh()
    }
    
    @objc func recipeUpdated() {
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if shouldRefresh {
            refresh()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    @IBAction func onSelectAll(sender: UIBarButtonItem) {
        if sender.title == "Select All" {
            sender.title = "Deselect All"
            selectedRecipes = Set<String>(Recipe.all().map({ $0.name }))
            refresh()
        } else {
            sender.title = "Select All"
            selectedRecipes.removeAll()
            refresh()
        }
    }

    @IBAction func onDone(sender: UIBarButtonItem) {
        exporter = RecipeExporter(viewController: self)
        exporter!.export(recipes: Recipe.all().filter({ self.selectedRecipes.contains($0.name) }),
                         completion: { self.performSegue(withIdentifier: "unwindToData", sender: self) })
    }

    @IBAction func onCancel(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToData", sender: self)
    }

    @IBAction func onSort(sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let sortByRating = UIAlertAction(title: "Sort by Rating", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Rating
            self.shouldScroll = true
            self.refresh()
        })
        
        let sortByName = UIAlertAction(title: "Sort by Name", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.userSettings.recipeSortOrder = .Name
            self.shouldScroll = true
            self.refresh()
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        sheet.addAction(sortByName)
        sheet.addAction(sortByRating)
        sheet.addAction(cancel)
        
        present(sheet, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recipe = (frc!.object(at: indexPath as IndexPath) as! Recipe)

        if selectedRecipes.contains(recipe.name) {
            selectedRecipes.remove(recipe.name)
        } else {
            selectedRecipes.insert(recipe.name)
        }
        
        tableView.reloadRows(at: [indexPath as IndexPath], with: UITableView.RowAnimation.none)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return frc!.sections!.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frc!.sections![section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath as IndexPath) as! RecipeCell
        let recipe = (frc!.object(at: indexPath as IndexPath) as! Recipe)
        cell.populate(recipe: recipe)
        if selectedRecipes.contains(recipe.name) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.selectionStyle = .none
        return cell
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchText != "" || userSettings.recipeSortOrder != .Name {
            return []
        }
        
        return [ UITableView.indexSearch ] + frc!.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if userSettings.recipeSortOrder == .Name {
            if index > 0 {
                return frc!.section(forSectionIndexTitle: title, at: index - 1)
            } else {
                let searchBarFrame = searchController!.searchBar.frame
                tableView.scrollRectToVisible(searchBarFrame, animated: false)
                return NSNotFound
            }
        } else {
            return frc!.section(forSectionIndexTitle: title, at: index)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let recipe = self.frc!.object(at: indexPath as IndexPath) as! Recipe
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            CoreDataHelper.delete(recipe: recipe)
            
            if let error = CoreDataHelper.save() {
                NSLog("Save Failed!: \(error)")
                assert(false)
                fatalError()
            } else {
                self.refresh()
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "recipe.deleted"), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "data.reset"), object: self)
            }
            
            tableView.isEditing = false
        }
        
        let exportAction = UITableViewRowAction(style: .normal, title: "Export") { (action, indexPath) -> Void in
            self.exporter = RecipeExporter(viewController: self)
            self.exporter!.export(recipes: [recipe])
            
            tableView.isEditing = false
        }
        
        return [ deleteAction, exportAction ]
    }
    
    func refresh() {
        let predicate: NSPredicate?
        if searchText != "" {
            predicate = NSPredicate(format: "(name contains[c] %@) OR (components.ingredient.name contains[c] %@)", searchText, searchText)
        } else {
            predicate = nil
        }
        
        frc = Recipe.fetchedResultsController(predicate: predicate)
        frc!.delegate = self
        
        do {
            // FIXME: nil seems like a bad idea
            try frc!.performFetch()
        } catch _ {
        }
        
        tableView.reloadData()
        
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        shouldRefresh = false
        if shouldScroll {
            shouldScroll = false
            if (frc?.sections?.count)! > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0) as IndexPath, at: UITableView.ScrollPosition.top, animated: false)
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        refresh()
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
}
