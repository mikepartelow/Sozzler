import UIKit
import CoreData

class AddQuantityToComponentViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var integerPicker: UIPickerView!
    @IBOutlet weak var fractionPicker: UIPickerView!
    @IBOutlet weak var unitPicker: UIPickerView!
    
    var ingredient: Ingredient?
    
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    let frc: NSFetchedResultsController
    
    let integers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    let fractions = ["⅛", "¼", "½", "¾", "⅓", "⅔"]
    let fractionArrs = [[1, 8], [1, 4], [1, 2], [3, 4], [1, 3], [2, 3]]
        
    var quantity_i: Int?
    var quantity_f: [Int]?
    var unit: Unit?
    
    required init(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        frc = NSFetchedResultsController(fetchRequest: Unit.fetchRequest(), managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        frc.performFetch(nil)
        
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        integerPicker.delegate = self
        integerPicker.dataSource = self
        
        fractionPicker.delegate = self
        fractionPicker.dataSource = self
        
        unitPicker.delegate = self
        unitPicker.dataSource = self
        
        navigationItem.title = ingredient!.name
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case integerPicker:
            return integers.count
        case fractionPicker:
            return fractions.count
        case unitPicker:
            return frc.sections![component].numberOfObjects!
        default:
            return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        switch pickerView {
        case integerPicker:
            return "\(integers[row])"
        case fractionPicker:
            return fractions[row]
        case unitPicker:
            let unit = frc.objectAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as! Unit
            return unit.name
        default:
            return ""
        }
    }

    @IBAction func onDone(sender: UIBarButtonItem) {
        let selectedUnit = unitPicker.selectedRowInComponent(0)
        unit        = frc.objectAtIndexPath(NSIndexPath(forRow: selectedUnit, inSection: 0)) as? Unit
        quantity_i  = integers[integerPicker.selectedRowInComponent(0)]
        quantity_f  = fractionArrs[fractionPicker.selectedRowInComponent(0)]
        
        performSegueWithIdentifier("unwindToAddRecipe", sender: self)
    }
}
