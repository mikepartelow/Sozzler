import CoreData

@objc(Unit)
class Unit: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var plural_name: String

    @NSManaged var recipe_count: Int16
    @NSManaged var index: Int16
    @NSManaged var components: NSSet
    
    class func fancyName(name: String) -> String {
        return name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    class func all() -> [Unit] {
        return CoreDataHelper.all(entityName: "Unit", predicate: nil) as! [Unit]
    }
    
    class func fetchedResultsController() -> NSFetchedResultsController<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Unit")

        let sortByIndex = NSSortDescriptor(key: "index", ascending: true)
        
        fetchRequest.sortDescriptors = [sortByIndex]
        
        return CoreDataHelper.fetchedResultsController(fetchRequest: fetchRequest)
    }

    class func find(name: String) -> Unit? {
        let predicate = NSPredicate(format: "name == %@", Unit.fancyName(name: name))
        return CoreDataHelper.find(entityName: "Unit", predicate: predicate) as! Unit?
    }
    
    class func create(name: String, plural_name: String, index: Int = Unit.count()) -> Unit {
        return CoreDataHelper.create(entityName: "Unit", initializer: {
            (entity, context) -> NSManagedObject in
            let unit = Unit(entity: entity, insertInto: context)

            unit.name = Unit.fancyName(name: name)
            unit.plural_name = Unit.fancyName(name: plural_name)
                unit.index = Int16(index)
                unit.recipe_count = 0
                return unit
            }
        ) as! Unit
    }
    
    class func findOrCreate(name: String, plural_name: String) -> Unit {
        let fancyName = Unit.fancyName(name: name)

        if let unit = Unit.find(name: fancyName) {
            return unit
        } else {
            return Unit.create(name: fancyName, plural_name: plural_name)
        }
    }
    
    class func count() -> Int {
        return CoreDataHelper.count(entityName: "Unit", predicate: nil)
    }

    func computeRecipeCount(adjustment: Int = 0) {
        var recipeCounts: [Recipe:Int] = [:]

        for component in components.allObjects as! [Component] {
            if recipeCounts[component.recipe] == nil {
                recipeCounts[component.recipe] = 1
            } else {
                recipeCounts[component.recipe]! += 1
            }
        }
        
        let count = recipeCounts.values.count + adjustment
        setPrimitiveValue(count, forKey: "recipe_count")

        assert(recipe_count >= 0, "unit recipe count went negative")
    }
    
    override func willSave() {
        if !isDeleted {
            setPrimitiveValue(Unit.fancyName(name: name), forKey: "name")
            
            if plural_name.isEmpty {
                setPrimitiveValue(name, forKey: "plural_name")
            }
            
            computeRecipeCount()
        }
    }    
}
