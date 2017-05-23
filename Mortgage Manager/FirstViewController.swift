//
//  FirstViewController.swift
//  Mortgage Manager
//
//  Created by Siddhi Suthar on 5/17/17.
//  Copyright © 2017 Siddhi. All rights reserved.
//

import UIKit
import DropDown
import CoreLocation
import GoogleMaps
import Firebase
import FirebaseDatabase

class FirstViewController: UIViewController {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var propertyType: UIButton!
    let selectPropertyType = DropDown()
    @IBOutlet weak var street: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var selectState: UIButton!
    @IBOutlet weak var zipcode: UITextField!
    let selectStateDropdown = DropDown()
    @IBOutlet weak var housePrice: UITextField!
    @IBOutlet weak var annualInterestRate: UITextField!
    @IBOutlet weak var downPaymentAmount: UITextField!
    @IBOutlet weak var monthlyPayment: UILabel!
    @IBOutlet weak var mortgageLoanLength: UIButton!
    let selectLoanLength = DropDown()
    
    var lati : Double = 0.0
    var long : Double = 0.0
   
    var coordinate = CLLocationCoordinate2D()
    var geocoder = CLGeocoder()
    
    var dbkey : String = ""
    var loanAmt : Double = 0.0
    var mAmt : Double = 0.0
   
    
    @IBAction func selectPropertyType(_ sender: Any) {
        selectPropertyType.show()
    }
    @IBAction func selectMortgageLoanLength(_ sender: Any) {
        selectLoanLength.show()
    }
    @IBAction func selectStateClick(_ sender: Any) {
        selectStateDropdown.show()
    }
    
    
    
    
    @IBAction func calculatePayment(_ sender: Any) {
        
        let validAddr : Bool = checkAddress()
        let validAmt : Bool = checkAmount()
        
        if !validAddr {
            giveAlert("Please enter valid address !")
            
        }
        else if !validAmt {
            giveAlert("Please enter valid amount !")
            
        }
        else {
            let lengthOfMortgageLoan : Int = Int(self.mortgageLoanLength.titleLabel!.text!)!
            let monthlyIntRate: Double = Double(self.annualInterestRate.text!)! / (12 * 100);
            let months: Double = Double(lengthOfMortgageLoan * 12);
            
            let loanAmount = Double(self.housePrice.text!)! - Double(self.downPaymentAmount.text!)!;
            self.loanAmt = loanAmount
            
            let monthlyPaymentAmount: Double = (loanAmount * monthlyIntRate) / (1 - pow((1+monthlyIntRate), -months))
            
            //to check if the monthly amount is greater than zero
            if monthlyPaymentAmount < 0.00 {
                
                giveAlert("Please enter valid amount !")
                
            }
            else {
                monthlyPayment.text = String(format: "%.2f", monthlyPaymentAmount)
                self.mAmt = monthlyPaymentAmount
                
                print("\n monthly payment: \(monthlyPaymentAmount)")
                
            }
            
        }
        
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupStateDropDown()
        setupLoanLengthDropDown()
        setupPropertyTypeDropDown()
        
        if !(dbkey.isEmpty){
            
            prefill()
        }
    }

    
    //save button click
    @IBAction func didTapSave(_ sender: Any) {
        
        let validAddr : Bool = checkAddress()
        let validAmt : Bool = checkAmount()
        
        if !validAddr {
            giveAlert("Please enter valid address !")
            
        }
        else if !validAmt {
            giveAlert("Please enter valid amount !")
            
        }
        else if ((self.monthlyPayment.text?.characters.count)! < 1) {
            giveAlert(" please calculate the monthly price first !")
        }
        else {
            let address = "\(street.text!), \(city.text!),  \(selectState.titleLabel!.text!) \(zipcode.text!)"
            print("address is: \(address)")
            
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                // Process Response
                self.processResponse(withPlacemarks: placemarks, error: error)
                
                self.performSegue(withIdentifier: "jumpToMapSeg", sender: self)
        }

        
      }

    }
    
    
     func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        
        if let error = error {
            print("Unable to Forward Geocode Address (\(error))")
            locationLabel.text = "Unable to Find Location for Address"
            
        } else {
            var location: CLLocation?
            
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
            
            if let location = location {
                coordinate = location.coordinate
                locationLabel.text = "\(coordinate.latitude) \(coordinate.longitude)"
              
                self.lati = coordinate.latitude
                self.long = coordinate.longitude
                
                postToDatabase()
                
            } else {
                locationLabel.text = "No Matching Location Found"
            }
        }
    }
    
    
    
    //setting up dropdowns
    func setupStateDropDown(){
    
        selectStateDropdown.anchorView = selectState
        selectStateDropdown.direction = .bottom
        selectStateDropdown.dataSource = ["AL", "AK", "AZ", "AR", "CA", "CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"]
        selectStateDropdown.bottomOffset = CGPoint(x: 0, y: selectState.bounds.height)
        
        selectStateDropdown.selectionAction = { [unowned self] (index, item) in
            self.selectState.setTitle(item, for: .normal)
        }
    }
    func setupLoanLengthDropDown(){
        selectLoanLength.anchorView = mortgageLoanLength
        selectLoanLength.direction = .bottom
        selectLoanLength.dataSource = ["15", "30"]
        selectLoanLength.bottomOffset = CGPoint(x: 0, y: mortgageLoanLength.bounds.height)
        
        selectLoanLength.selectionAction = { [unowned self] (index, item) in
            self.mortgageLoanLength.setTitle(item, for: .normal)
        }
    }
    func setupPropertyTypeDropDown(){
        selectPropertyType.anchorView = propertyType
        selectPropertyType.direction = .bottom
        selectPropertyType.dataSource = ["House", "Townhouse", "Condo"]
        selectPropertyType.bottomOffset = CGPoint(x: 0, y: propertyType.bounds.height)
        
        selectPropertyType.selectionAction = { [unowned self] (index, item) in
            self.propertyType.setTitle(item, for: .normal)
        }
    }
    
    func postToDatabase(){
        
        if self.lati != 0.0 && self.long != 0.0 {
        
        let calculation: NSDictionary = [
            "propertyType" : propertyType.titleLabel!.text!,
         "streetAddr" : street.text!,
         "cityAddr" : city.text!,
         "stateAddr" : selectState.titleLabel!.text!,
         "zip" : zipcode.text!,
         "hPrice" : housePrice.text!,
         "anr" : annualInterestRate.text!,
         "dPayment" : downPaymentAmount.text!,
         "loanlength" : mortgageLoanLength.titleLabel!.text!,
         "mAmount" : monthlyPayment.text!,
         "loanAmount" : self.loanAmt as Double!,
         "latitude": lati,
         "longitude": long]
        
        print("calculation: ")
        print(calculation)
        let databaseRef = Database.database().reference()
        
        if !(dbkey.isEmpty) {
            
            databaseRef.child("calculations").child(dbkey as! String).setValue(calculation)
            
            print(" \n existing child updated")
        }else{
        
        databaseRef.child("calculations").childByAutoId().setValue(calculation)
            print("\n new child created ")
        }
        
    
    clearFlags()
        }
        else {
            giveAlert(" Please enter valid address and try again !")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearFlags() {
        //necessary step to clear the environmental variable after usage.
        self.dbkey = ""
        self.loanAmt = 0.0
        
                       print("\n ALERT for clear flags called !! \n")
    }
    
    
    
    func prefill(){
        
        Database.database().reference().child("calculations").child((self.dbkey as? String)!).observe(.value, with: { snapshot in
            
            let child = snapshot as DataSnapshot
            
        let dict = child as? NSDictionary
            
            self.propertyType.titleLabel!.text! = dict!.value(forKey: "propertyType") as! String
            self.street.text! = dict!.value(forKey: "streetAddr") as! String
            self.city.text! = dict!.value(forKey: "cityAddr") as! String
            self.selectState.titleLabel!.text! = dict!.value(forKey: "stateAddr") as! String
            self.zipcode.text! = dict!.value(forKey: "zip") as! String
            self.housePrice.text! = dict!.value(forKey: "hPrice") as! String
            self.annualInterestRate.text! = dict!.value(forKey: "anr") as! String
            self.downPaymentAmount.text! = dict!.value(forKey: "dpayment") as! String
            self.mortgageLoanLength.titleLabel!.text! = dict!.value(forKey: "loanlength") as! String
            self.monthlyPayment.text! = dict!.value(forKey: "mAmount") as! String

            
            
            
        })
        
}
    
    func giveAlert (_ msg : String) {
        
        //pop an alert
        let alert1 = UIAlertController(title: "Oops!", message: msg , preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let action1 = UIAlertAction(title: "CANCEL", style: UIAlertActionStyle.default , handler: nil)
        
        alert1.addAction(action1)
        
        self.present(alert1, animated: true, completion: nil)

        
    }
    
    func checkAddress () -> Bool{
        
        let pt : Bool = ( (self.propertyType.titleLabel?.text)?.range(of: "Home") != nil) || ( (self.propertyType.titleLabel?.text)?.range(of: "Townhouse") != nil) || ( (self.propertyType.titleLabel?.text)?.range(of: "Condo") != nil)
        
        let st : Bool = ((self.street.text?.characters.count)! > 0)
        let city : Bool = ((self.city.text?.characters.count)! > 0)
        let zip : Bool = ((self.zipcode.text?.characters.count)! > 0)
        
        let state : Bool = (self.selectState.titleLabel?.text?.characters.count)! < 3
        
        return pt && st && city && zip && state
        
        
    }
    
    func checkAmount () -> Bool {
        
        let hp : Bool = Double(self.housePrice.text!)! > 0.0
        let dp : Bool = Double(self.downPaymentAmount.text!)! > 0.0
        let anr : Bool = Double(self.annualInterestRate.text!)! > 0.0
        let loan : Bool = Double(self.housePrice.text!)! > Double(self.downPaymentAmount.text!)!
        let period : Bool = Int64((self.mortgageLoanLength.titleLabel?.text?.characters.count)!) < 3
        
        return hp && dp && anr && loan && period
        
    }

}
