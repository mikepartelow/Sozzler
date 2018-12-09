import UIKit

class EditUnitViewController: UIViewController {

    @IBOutlet weak var unitNameSingular: UITextField!
    @IBOutlet weak var unitNamePlural: UITextField!

    var added = false
    var unit: Unit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if unit == nil {
            navigationItem.title = "Add Unit"
            unitNameSingular.becomeFirstResponder()
        } else {
            unitNameSingular.text = unit!.name
            unitNamePlural.text = unit!.plural_name
            navigationItem.title = "Edit Unit"
        }
    }
    
    // FIXME: DRY
    func errorAlert(title: String, button: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: button, style: .default) { (action: UIAlertAction) -> Void in }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onSave(_ sender: UIBarButtonItem) {
        if unit == nil {
            if Unit.find(name: unitNameSingular.text!) != nil {
                self.errorAlert(title: "Unit already exists.", button: "Oops")
            } else {
                unit = Unit.create(name: unitNameSingular.text!, plural_name: unitNamePlural.text!)
            }
        } else {
            unit!.name = Unit.fancyName(name: unitNameSingular.text!)
            unit!.plural_name = Unit.fancyName(name: unitNamePlural.text!)
        }
        
        if unit != nil {
            if let error = CoreDataHelper.save() {
                NSLog("Save Failed!: \(error)")
                assert(false)
                fatalError()
            } else {
                added = true
                performSegue(withIdentifier: "unwindToUnitTable", sender: self)
            }
        }
    }
}
