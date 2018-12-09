import UIKit
import CoreData

class AddQuantityToComponentViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var integerPicker: UIPickerView!
    @IBOutlet weak var fractionPicker: UIPickerView!
    @IBOutlet weak var unitPicker: UIPickerView!
    
    var ingredient: Ingredient?
    
    let moc = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext!
    let frc: NSFetchedResultsController<NSFetchRequestResult>
    
    let integers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    let fractions = ["⅛", "¼", "½", "¾", "⅓", "⅔"]
    let fractionArrs = [[1, 8], [1, 4], [1, 2], [3, 4], [1, 3], [2, 3]]
        
    var quantity_i: Int?
    var quantity_f: [Int]?
    var unit: Unit?
    
    required init?(coder aDecoder: NSCoder) {
        _ = UIApplication.shared.delegate as! AppDelegate
        
        frc = Unit.fetchedResultsController()
        do {
            try frc.performFetch()
        } catch _ {
        }
        
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case integerPicker:
            return integers.count + 1
        case fractionPicker:
            return fractions.count + 1
        case unitPicker:
            return frc.sections![component].numberOfObjects
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case integerPicker:
            return row == 0 ? "" : "\(integers[row-1])"
        case fractionPicker:
            return row == 0 ? "" : fractions[row-1]
        case unitPicker:
            let unit = frc.object(at: NSIndexPath(row: row, section: 0) as IndexPath) as! Unit
            return unit.name
        default:
            return ""
        }
    }

    @IBAction func onDone(_ sender: UIBarButtonItem) {
        let selectedUnit        = unitPicker.selectedRow(inComponent: 0)
        unit                    = frc.object(at: IndexPath(row: selectedUnit, section: 0) as IndexPath) as? Unit
        
        let selectedInteger     = integerPicker.selectedRow(inComponent: 0)
        quantity_i              = selectedInteger == 0 ? 0 : integers[selectedInteger-1]

        let selectedFraction    = fractionPicker.selectedRow(inComponent: 0)
        quantity_f              = selectedFraction == 0 ? [0, 1] : fractionArrs[selectedFraction-1]
        
        performSegue(withIdentifier: "unwindToAddRecipe", sender: self)
    }
}
