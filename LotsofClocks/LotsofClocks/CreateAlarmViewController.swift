//
//  CreateAlarmViewController.swift
//  LotsofClocks
//
//  Created by Ben Malaga on 1/24/21.
//

import UIKit
import CoreData

class CreateAlarmViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    
    // MARK:- Variables

    
    // User input for the alarm being created
    @IBOutlet weak var alarmLabelTextField: UITextField!
    @IBOutlet weak var alarmTimePicker: UIDatePicker!
    @IBOutlet weak var alarmSoundPicker: UIPickerView!
    
    // Save, and cancel buttons. Closes or saves the alarm
    @IBOutlet weak var saveAlarmButton: UIBarButtonItem!
    @IBOutlet weak var cancelAlarmButton: UIBarButtonItem!
    
    // The navigation bar, used to set the title of the screen
    @IBOutlet weak var createAlarmsNavBar: UINavigationItem!
    
    // The deletion label and selection, only shows if edit mode is on
    @IBOutlet weak var deleteAlarmControl: UISegmentedControl!
    @IBOutlet weak var deleteAlarmLabel: UILabel!
    
    
    // The current folders ID in which the alarm belongs to
    var currentFolderID:Int = 0
    
    // CoreData variables, stores the current alarm, list of alarms, and the alarm being edited if edit mode is on.
    var alarm:NSManagedObject? = NSManagedObject()
    var alarms:[NSManagedObject] = []
    var editedAlarm:NSManagedObject? = NSManagedObject()

    // Stores all notification sounds
    var soundsList:[String] = [String]()
    
    // Variables for setting the alarms name, time, and sound for CoreData usage
    var alarmName:String = ""
    var alarmSound:String = ""
    var alarmTime:String = ""
    
    // If the edit mode is on, the variable will be used to find the alarm being edited
    var editingTime:String = ""
    
    // Boolean values for the edit mode, and deletion option
    var isEditOn:Bool = false
    var isDeleteOn:Bool = false
    
    
    // MARK:- View Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.alarmSoundPicker.delegate = self
        self.alarmSoundPicker.dataSource = self
        
        soundsList = ["Alert", "Pinging", "Radar"]
        
        // If the edit mode is on, show the deletion options as well as the interface
        if isEditOn
        {
            createAlarmsNavBar.title = "Edit Alarm"
            deleteAlarmLabel.isHidden = false
            deleteAlarmControl.isHidden = false
        }
        else
        {
            createAlarmsNavBar.title = "Create Alarm"
            deleteAlarmLabel.isHidden = true
            deleteAlarmControl.isHidden = true
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isDeleteOn = false
    }
    
    
    // MARK:- IBActions
    
    @IBAction func onSavePress(_ sender: Any)
    {
        
        let name = alarmLabelTextField.text!
        
        // Sets the default name for an alarm if nothing is there
        if name.count == 0
        {
            alarmName = "Alarm"
        }
        else
        {
            alarmName = name
        }
        
        alarmTime = getDate(date: alarmTimePicker.date)
        
        self.save(name: alarmName, sound: alarmSound, time: alarmTime, folderID: currentFolderID)
        
    }
    
    @IBAction func onCancelPress(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteSwitchActivated(_ sender: UISegmentedControl)
    {
        if deleteAlarmControl.selectedSegmentIndex == 0
        {
            isDeleteOn = true
        }
        else
        {
            isDeleteOn = false
        }
    }
    
    
    @IBAction func returnPressed(_ sender: UITextField)
    {
        sender.resignFirstResponder()
    }
    
    
    // MARK: - General Functions
    
    // Saves the object being made into the database
    func save(name: String, sound: String, time: String, folderID: Int)
    {
      
        // CoreData set up
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else{return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        
        // Fetches the entity that the object will be saved in, in this case its the alarm entity
        let entity = NSEntityDescription.entity(forEntityName: "Alarm", in: managedContext)!
      
        // A fetch request for all alarm entities, compared to the folder being created to ensure no duplication
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alarm")
        
        do
        {
            // Array of all folder entities
            alarms = try managedContext.fetch(fetchRequest)
            
            // Iterates through all alarms and checks for duplication, or if the edit mode is on, finds the alarm that is being edited
            for object in alarms
            {
                
                if isEditOn
                {
                    if object.value(forKey: "time") as? String == editingTime
                    {
                        editedAlarm = object

                    }
                }
            
            }
            
            // If the edit mode is on, check to see if deletion has been selected, and edit all of the alarms changed values
            if isEditOn
            {
                if isDeleteOn
                {
                    // Core data setup
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    else {return}
                              
                    let managedContext = appDelegate.persistentContainer.viewContext
                                
                    let center = UNUserNotificationCenter.current()
                    
                    // Makes sure that the notification ID is not empty
                    let iden:String = (editedAlarm!.value(forKey:"notificationID") as? String)!
                    
                    if iden != ""
                    {
                        center.removePendingNotificationRequests(withIdentifiers: [iden])
                    }
                                
                    managedContext.delete(editedAlarm!)
                    alarms.remove(at: alarms.firstIndex(of: editedAlarm!)!)
                    appDelegate.saveContext()
                }
                
                // Edits all of the alarms information
                editedAlarm!.setValue(name, forKeyPath: "name")
                editedAlarm!.setValue(time, forKeyPath: "time")
                editedAlarm!.setValue(sound, forKeyPath: "sound")
                
                do
                {
                    // Saves the entity
                    try managedContext.save()
                    appDelegate.saveContext()
                }
                catch let error as NSError
                {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
            }
            
            else
            {
                // The object that the name will be saved into
                alarm = NSManagedObject(entity: entity, insertInto: managedContext)
            
                // Sets all the values in the alarm entity
                alarm!.setValue(name, forKeyPath: "name")
                alarm!.setValue(time, forKeyPath: "time")
                alarm!.setValue(sound, forKeyPath: "sound")
                alarm!.setValue(folderID, forKeyPath: "folderID")
                alarm!.setValue(false, forKeyPath:"activated")
                alarm!.setValue("", forKeyPath:"notificationID")
            
                if alarms.isEmpty == true
                {
                    alarm!.setValue(1, forKeyPath: "alarmID")
                }
                else
                {
                    let nextId = alarms[alarms.count - 1].value(forKey: "alarmID") as! Int + 1
                    alarm!.setValue(nextId, forKeyPath: "alarmID")
                }
                
                do
                {
                    // Saves the entity
                    try managedContext.save()
                    appDelegate.saveContext()
                }
                catch let error as NSError
                {
                    print("Could not fetch. \(error), \(error.userInfo)")
                }
                
            }
        }
        
        catch let error as NSError
        {
          print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        dismiss(animated: true, completion: nil)

    }
    
    // Converts the date in the time picker to a string in format "HOUR:MINUTE AM/PM"
    func getDate(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.short
        dateFormatter.timeZone = TimeZone.current
        let time = dateFormatter.string(from: date)
        return time
    }
    
    
    // MARK:- Picker View Protocals
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return soundsList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // Initializing alarm sound so its not nil if user selects default sound
        alarmSound = soundsList[0]
        return soundsList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        alarmSound = soundsList[row]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
