
import UIKit
import HealthKit

//MARK:- HealthKit Type Enum
enum QuantityType {
    case stepsQuantityType
    case distanceType
    case heartRateType
    case BPSystolicType
    
    var value: HKQuantityType {
        
        switch self {
            
        case .stepsQuantityType:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)!
            
        case .distanceType:
            return HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
            
        case .heartRateType:
            return HKQuantityType.quantityType(forIdentifier: .heartRate)!
            
        case .BPSystolicType:
            return HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        }
    }
}

//Do not forget to checkmark background fetch in edit scheme -> Run -> Options -> Background fetch
//MARK:- Class ViewController
class ViewController: UIViewController {
    
    //MARK:- IBOutlets
    @IBOutlet weak var lblStepsCount        : UILabel!
    @IBOutlet weak var lblWalkingDistance   : UILabel!
    @IBOutlet weak var lblBP                : UILabel!
    
    //MARK:- Variables
    var healthStore                         = HKHealthStore()
    
    let now                                 = Date()
    var startOfDay                          = Date() - 7 * 24 * 60 * 60
    let cal                                 = Calendar(identifier: Calendar.Identifier.gregorian)
    var predicate                           : NSPredicate?
    var steps                               = QuantityType.stepsQuantityType
    
    let allTypes                            = Set([ HKObjectType.quantityType(forIdentifier: .stepCount)!,
                                                    HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
                                                    HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                                    HKObjectType.quantityType(forIdentifier: .heartRate)!])
    //MARK:- View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        startOfDay = cal.startOfDay(for: now)
        predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        //#1
        if HKHealthStore.isHealthDataAvailable(){
            
            //#2 Request Authorization of all sets
            healthStore.requestAuthorization(toShare: allTypes, read: allTypes, completion: { (success, error) in
                
                if(!success){
                    //#3
                    print("error")
                    return
                    
                } else {
                    //#4
                    self.getHealthData(type: self.steps)
                    
                }
            })
        }
    }
    
    //MARK:- Custom Methods
    func getHealthData(type:QuantityType) {
        switch type {
            
        case .stepsQuantityType:
            //==> Steps Here <==
            self.getStepsDistanceData(quantityType: type) { (data) in
                
                DispatchQueue.main.async {
                    self.lblStepsCount.text = "\(data!)"
                    self.getHealthData(type: QuantityType.distanceType)
                }
            }
            break
            
        case .distanceType:
            //==> Running + Walking Distance Here <==
            self.getStepsDistanceData(quantityType: type) { (walkingValue) in
                if let value = walkingValue as? Double {
                    let walkingDistance = value.convert(from: .miles, to: .kilometers)
                    DispatchQueue.main.async {
                        self.lblWalkingDistance.text = "\(Double(round(100*walkingDistance)/100)) KM"
                        self.getHealthData(type: QuantityType.BPSystolicType)
                    }
                } else {
                    self.lblWalkingDistance.text = "0 KM"
                }
            }
            break
            
        case .BPSystolicType:
            //==> Blood Pressure of Systolic Type Here <==
            self.getHealthBPData(HealthQuantityType: type.value, strUnitType: "mmHg"
            ) { (arrHealth) -> Void in
                DispatchQueue.main.async {
                    if arrHealth != nil {
                        if let tempText = arrHealth?.joined(separator: ", ") {
                            self.lblBP.text = "\(tempText) Systolic"
                        }
                    } else {
                        self.lblBP.text = "0 Systolic"
                    }
                }
            }
            
        case .heartRateType:
            //==> Avg Heart Rate Here <==
            self.getAVGHeartRate()
        }
    }
    
    //MARK:- Blood Pressure
    // Get BP values according to quantity type
    func getHealthBPData ( HealthQuantityType : HKQuantityType , strUnitType : String , completion: @escaping ([String]?) -> Void)
    {
        if (HKHealthStore.isHealthDataAvailable()  ){
            
            let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            // Execute query on steps quantity type
            let query = HKSampleQuery(sampleType:QuantityType.BPSystolicType.value, predicate:nil, limit:7, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
                
                guard let results = results else {
                    if let errorDescription = error?.localizedDescription
                    {
                        print(errorDescription)
                        completion(nil)
                    }
                    return
                }
                
                var arrBPHealth = [String]()
                for quantitySample in results {
                    let quantity = (quantitySample as! HKQuantitySample).quantity
                    let healthDataUnit : HKUnit
                    if (strUnitType.count > 0 ){
                        healthDataUnit = HKUnit(from: strUnitType)
                    } else{
                        healthDataUnit = HKUnit.count()
                    }
                    
                    let tempActualhealthData = "\(quantity.doubleValue(for: healthDataUnit))"
                    let tempActualRecordedDate = "\(dateFormatter.string(from: quantitySample.startDate))"
                    arrBPHealth.append(tempActualhealthData)
                    print(tempActualhealthData,tempActualRecordedDate)
                }
                DispatchQueue.main.async {
                    completion(arrBPHealth)
                }
            })
            self.healthStore.execute(query)
        }
    }
    
    //MARK:- Steps & Walking + Running Distance
    func getStepsDistanceData(quantityType: QuantityType, completion: @escaping (Any?) -> Void) {
        let query = HKStatisticsQuery(quantityType: quantityType.value, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            
            if (HKHealthStore.isHealthDataAvailable() ){
                
                switch quantityType {
                    
                case .BPSystolicType:
                    break
                    
                case .stepsQuantityType:
                    var resultCount = 0.0
                    
                    guard let result = result else {
                        print("Steps Error =>\(String(describing: error?.localizedDescription)) ")
                        completion(resultCount)
                        return
                    }
                    
                    if let sum = result.sumQuantity() {
                        resultCount = sum.doubleValue(for: HKUnit.count())
                    }
                    
                    DispatchQueue.main.async {
                        completion(resultCount)
                    }
                    break
                    
                case .distanceType:
                    var value: Double = 0
                    
                    if error != nil {
                        print("Walking Distance Error => \(String(describing:error?.localizedDescription))")
                        
                    } else if let quantity = result?.sumQuantity() {
                        value = quantity.doubleValue(for: HKUnit.mile())
                    }
                    
                    DispatchQueue.main.async {
                        completion(value)
                    }
                    
                    break
                case .heartRateType:
                    break
                }
            }
        }
        self.healthStore.execute(query)
    }
    
    // MARK:- Heart Rate
    //Get average heart rate
    func getAVGHeartRate() {
        
        let startDate = Date() - 7 * 24 * 60 * 60 // start date is a week
        predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: HKQueryOptions.strictEndDate)
        
        let squery = HKStatisticsQuery(quantityType: QuantityType.heartRateType.value, quantitySamplePredicate: predicate, options: .discreteAverage, completionHandler: {(query: HKStatisticsQuery,result: HKStatistics?, error: Error?) -> Void in
            DispatchQueue.main.async(execute: {() -> Void in
                let quantity: HKQuantity? = result?.averageQuantity()
                let beats: Double? = quantity?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                print("got: \(String(format: "%.f", beats!))")
            })
        })
        healthStore.execute(squery)
    }
}

