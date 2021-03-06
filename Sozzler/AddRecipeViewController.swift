import UIKit
import CoreData

class AddRecipeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var componentTable: UITableView!
    @IBOutlet weak var componentTableHeight: NSLayoutConstraint!

    @IBOutlet weak var recipeTextHeight: NSLayoutConstraint!
    @IBOutlet weak var ratingView: RatingView!
    @IBOutlet weak var recipeText: UITextView!
    
    @IBOutlet weak var contentView: UIView!
    
    let recipeTextPlaceholder = "Stir with ice, strain into chilled rocks glass."
    
    var keyboardRect = CGRect()
    
    var added = false
    var recipe: Recipe?
    var editingRecipe = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeName.autocapitalizationType = UITextAutocapitalizationType.words
        
        componentTable!.dataSource = self
        componentTable!.delegate = self
        
        recipeText.delegate = self

        if recipe == nil {
            recipe = Recipe.create(name: "", withRating: 0, withText: "")
            recipeText.text = recipeTextPlaceholder
            recipeText.textColor = UIColor.lightGray
        } else {
            navigationItem.title = "Edit Recipe"

            recipeName!.text = recipe!.name
            if recipe!.text.isEmpty {
                recipeText!.text = recipeTextPlaceholder
                recipeText.textColor = UIColor.lightGray
            } else {
                recipeText!.text = recipe!.text
            }
            
            editingRecipe = true
        }
        
        ratingView!.editing = true // this must come before we set the rating value
        ratingView!.rating = Int(recipe!.rating)
        
        resizeComponentsTable()
        componentTable!.isEditing = true
        resizeRecipeText()
        
        let scrollPoint = CGPoint(x: 0, y: recipeText.frame.origin.y)
        recipeText.setContentOffset(scrollPoint, animated: false)

        // ridiculous hack to avoid "scrolling uitextfield" rotation bug
        //
        recipeName!.layer.borderColor = UIColor.white.cgColor
        recipeName!.layer.borderWidth = 1.0

//        recipeText.layer.borderColor = UIColor.blackColor().CGColor
//        recipeText.layer.borderWidth = 1.0

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        pan.cancelsTouchesInView = false
        pan.delegate = self
        scrollView.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(tap)
        
        recipeName.addTarget(self, action: #selector(self.dismissKeyboard), for: UIControl.Event.editingDidEndOnExit)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !recipeName.isFirstResponder && !recipeText.isFirstResponder
    }

    @objc func dismissKeyboard(_ sender: UIButton) {
        view.endEditing(true)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let r = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
                keyboardRect = r
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resizeComponentsTable()
    }

    override func didRotate(from: UIInterfaceOrientation) {
        resizeComponentsTable()
        recipeText.resignFirstResponder()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text == recipeTextPlaceholder {
                recipeText!.text = ""
                recipeText!.textColor = UIColor.black
            }
            
            scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            
            let contentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardRect.height, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            let h = view.frame.height - keyboardRect.height
            let nbh = navigationController!.navigationBar.frame.size.height
            let sbh = UIApplication.shared.statusBarFrame.size.height
            
            let newHeight = h - 8 - nbh - 8 - sbh

            let y = recipeText.frame.origin.y - 8

            scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
            recipeTextHeight.constant = newHeight
            recipeText.isScrollEnabled = true
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == recipeText {
            if recipeText!.text.isEmpty {
                recipeText!.text = recipeTextPlaceholder
                recipeText!.textColor = UIColor.lightGray
            }

            resizeRecipeText()

            let contentInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            recipeText.scrollRectToVisible(CGRect(x: 0, y: 0, width: 0, height: 0), animated: true)
            recipeText.isScrollEnabled = false
        }
    }
    
    func resizeComponentsTable() {
        componentTableHeight.constant = componentTable.contentSize.height
        componentTable.setNeedsUpdateConstraints()
    }
    
    func resizeRecipeText() {
        let fit = max(176, recipeText.sizeThatFits(recipeText.contentSize).height)
        recipeTextHeight.constant = fit
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipe!.sortedComponents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = componentTable.dequeueReusableCell(withIdentifier: "componentCell")!
        cell.textLabel!.text = recipe!.sortedComponents[indexPath.row].string
        return cell
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) -> Void in
            let component = self.recipe!.sortedComponents[indexPath.row]
            
            self.recipe!.components.remove(component)
            CoreDataHelper.delete(obj: component)
            self.componentTable.reloadData()
            self.resizeComponentsTable()
            
            let row = self.recipe!.sortedComponents.count > 1 ? self.recipe!.sortedComponents.count-1 : NSNotFound
            self.componentTable.scrollToRow(at: IndexPath(row: row, section: 0) as IndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            
            for (index, component) in self.recipe!.sortedComponents.enumerated() {
                component.index = Int16(index)
            }

        }
        
        return [ deleteAction ]
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < recipe!.sortedComponents.count
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // even if it does nothing this needs to be here if we want to get a delete event
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        moc.rollback()
        if editingRecipe {
            performSegue(withIdentifier: "unwindToRecipe", sender: self)
        } else {
            performSegue(withIdentifier: "unwindToRecipes", sender: self)
        }
    }
    
    @IBAction func onSave(_ sender: UIBarButtonItem) {
        recipe!.name = recipeName!.text!
        recipe!.rating = Int16(ratingView!.rating)
        
        if recipeText!.text == recipeTextPlaceholder {
            recipe!.text = ""
        } else {
            recipe!.text = recipeText!.text
        }

        var error: NSError?
        do {
            try moc.save()
            added = true
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "recipe.updated"), object: self)
            if editingRecipe {
                performSegue(withIdentifier: "unwindToRecipe", sender: self)
            } else {
                performSegue(withIdentifier: "unwindToRecipes", sender: self)
            }
        } catch let error1 as NSError {
            error = error1
            NSLog("\(String(describing: error))")
            let errorMessage = error!.userInfo[NSLocalizedDescriptionKey] as! String
            let errorCode = Recipe.ValidationErrorCode(rawValue: error!.code)
            
            if errorCode == Recipe.ValidationErrorCode.Name {
                recipeName.becomeFirstResponder()
            } else {
                recipeText.resignFirstResponder()
            }
            
            let alert = UIAlertController(title: errorMessage, message: nil, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .default) { (action: UIAlertAction) -> Void in }
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func unwindToAddRecipe(sender: UIStoryboardSegue)
    {
        if let _ = sender.source as? AddIngredientToComponentViewController {
        } else if let vc = sender.source as? AddQuantityToComponentViewController {
            if let unit = vc.unit {
                let quantity_d = Int16(vc.quantity_f![1])
                let quantity_n = Int16((vc.quantity_f![1] * vc.quantity_i!) + vc.quantity_f![0])
                
                _ = Component.create(quantity_n: quantity_n, quantity_d: quantity_d, unit: unit, ingredient: vc.ingredient!, recipe: recipe!, index: Int16(recipe!.components.count))
                
                componentTable.reloadData()
                resizeComponentsTable()
                componentTable.scrollToRow(at: IndexPath(row: recipe!.sortedComponents.count-1, section: 0) as IndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt from: IndexPath, to: IndexPath) {
        if from == to {
            return
        }
    
        let sortedComponents = recipe!.sortedComponents
        
        if to.row < from.row {
            _ = sortedComponents[to.row..<from.row].map({ (component) in
                component.index += 1
            })
        } else if from.row < to.row {
            _ = sortedComponents[from.row+1...to.row].map({ (component) in
                component.index -= 1
            })
        }
        
        sortedComponents[from.row].index = Int16(to.row)
    }
}
