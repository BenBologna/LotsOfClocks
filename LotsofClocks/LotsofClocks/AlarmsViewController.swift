//
//  AlarmsTableViewController.swift
//  LotsofClocks
//
//  Created by Ben Malaga on 1/7/21.
//

import UIKit
import CoreData
import UserNotifications

// MARK:- Alarm Cell Class

// Class for the alarm cell, includes handling for the activation switch
class AlarmCell: UITableViewCell, UNUserNotificationCenterDelegate{
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activateSwitch: UISwitch!
    @IBOutlet weak var editImage: UIImageView!
    
    var alarmID:Int = 0
    
    var notifID:String = ""
    var alarmActivated:NSObject = NSObject.init()
    
    @IBAction func onAlarmActivated(_ sender: UISwitch)
    {
        let alarmsVC = AlarmsViewController()
        
        // CoreData set up
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else{return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
      
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alarm")
        
        do
        {
            // Array of all folder entities
            let alarms = try managedContext.fetch(fetchRequest)
            
            // Iterates through all objects in the alarms array, finding the object that has been activated, and updating its view and attribute in CoreData
            for object in alarms
            {
                if object.value(forKey:"alarmID") as? Int == alarmID
                {
                    alarmActivated = object
                    
                }
            }
        }
        catch _ as NSError{}
    
        alarmsVC.createNotif(label: label.text!, time: time.text!, alarm: alarmActivated, sender.isOn)
            
        if sender.isOn
        {
            time.textColor = UIColor.label
            label.textColor = UIColor.label
        }
        else
        {
            time.textColor = UIColor.gray
            label.textColor = UIColor.gray
        }
    }
}


// MARK:- Table View Controller Class


class AlarmsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate{
    
    // MARK: - Variables
    
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var alarmsEditButton: UIBarButtonItem!
    
    @IBOutlet weak var alarmsTitle: UINavigationItem!
    

    var currentFolderID:Int = 0
    
    var currentFolderName:String = ""
    
    public var alarms:[NSManagedObject] = []
    
    var isTrashEnabled:Bool = false
    
    var isEditOn:Bool = false
    
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        alarmsTitle.title = currentFolderName
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        isEditOn = false
        alarmsEditButton.title = "Edit"
        print("hi")
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        displayAlarms()
        tableView.reloadData()
        print("hello")
        
    }
    
    
    // MARK: - IBActions
    
    
    @IBAction func onNewAlarmPress(_ sender: Any)
    {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let createAlarmVC = storyBoard.instantiateViewController(withIdentifier: "CreateAlarmViewController") as! CreateAlarmViewController
        
        createAlarmVC.currentFolderID = currentFolderID
        
        // Presents the VC
        createAlarmVC.modalPresentationStyle = .fullScreen
        self.present(createAlarmVC, animated: true, completion: nil)
    }
    
    @IBAction func onEditPress(_ sender: Any)
    {
        if isEditOn
        {
            isEditOn = false
            alarmsEditButton.title = "Edit"
        }
        else
        {
            isEditOn = true
            alarmsEditButton.title = "Done"
        }
        tableView.reloadData()
    }
    
    @IBAction func onClosePress(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    
    

    // MARK: - General Functions
    
    func createNotif(label: String, time: String, alarm alarmActivated: NSObject, _ isAlarmOn: Bool)
    {
        let notifID = UUID().uuidString

        // CoreData set up
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else{return}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        if isAlarmOn
        {
            // Sets up the content of the alarm
            let content = UNMutableNotificationContent()
            content.title = label
            content.body = ""
            
            // Fetches the sound of the current alarm, and sets the sound of the notification
            let sound:String = alarmActivated.value(forKey: "sound") as! String + ".wav"
            content.sound = UNNotificationSound.init(named: UNNotificationSoundName(rawValue: sound))

            
            // Sets up the time in which the alarm will be displayed
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            
            let date = Date(timeIntervalSinceNow: 0)
            let dayHourDate = Calendar.current.dateComponents([.day, .hour, .minute], from: date)
            
            let totalTimeToday = Int(dayHourDate.value(for: .hour)!) * 60 + Int(dayHourDate.value(for: .minute)!)
            let totalTimeAlarm = getMinutes(time: time)["totalTime"]!
            
            // If the alarm activated has a time that has already passed, it will be alerted tomorrow. If not, it will be alerted today.
            if totalTimeToday < totalTimeAlarm
            {
                dateComponents.day = dayHourDate.value(for: .day)
            }
            else
            {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                dateComponents.day = Calendar.current.dateComponents([.day], from: tomorrow!).value(for: .day)
            }
            
            dateComponents.hour =  getMinutes(time: time)["hours"]!
            dateComponents.minute =  getMinutes(time: time)["minutes"]!
               
            // Create the trigger as a repeating event.
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(identifier: notifID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
            
            alarmActivated.setValue(1, forKeyPath: "activated")
            alarmActivated.setValue(notifID, forKeyPath: "notificationID")
        }
        else
        {
            alarmActivated.setValue(0, forKeyPath: "activated")
            
            // Removes the alarm from the queue
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [notifID])
        }
        do
        {
            try managedContext.save()
            appDelegate.saveContext()
        }
        catch _ as NSError{}
        
    }
    
    // Returns a dictionary of the hours, minutes, and total time of the given time formatted string
    func getMinutes(time: String) -> [String:Int]
    {
        let timeOfDay = time[time.index(after: time.firstIndex(of:" ")!)...]
        let hours:Int = Int(time[..<time.firstIndex(of: ":")!])!
        
        var totalHours:Int = 0
        
        // Converts the total number of hours, from 1 - 24 of the current time.
        if timeOfDay == "AM"
        {
            if hours == 12
            {
                totalHours = 0
            }
            else
            {
                totalHours = hours
            }
        }
        else
        {
            if hours == 12
            {
                totalHours = 12
            }
            else
            {
                totalHours = hours + 12
            }
        }
        
        let start = time.index(after: time.firstIndex(of:":")!)
        let end = time.firstIndex(of: " ")!
        let minutes:Int = Int(time[start..<end])!
        
        let totalTime:Int = (totalHours * 60) + minutes
        
        return ["hours":totalHours, "minutes":minutes, "totalTime":totalTime]
    }
    
    // Deletes all alarms
    func deleteAllAlarms() -> Void
    {
        // Core data setup
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alarm")

        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedContext.execute(batchDeleteRequest)

        } catch {
            // Error Handling
        }
    }
    

    // Displays all the alarms ascociated with the current folder onto the screen, and sorts them from least to greatest (in terms of time)
    func displayAlarms() -> Void
    {
        // Core data setup
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
      
        // Fetches all entities with the entity name of Folder
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Alarm")
        
      
        do
        {
            // Sets the array of all folders that need to be displayed to the fetch request
            alarms = try managedContext.fetch(fetchRequest)
            
            if alarms.count > 0
            {
                for object in alarms
                {
                    // Compares folder ID's, removes the alarm if it does not correspond
                    if object.value(forKey: "folderID") as! Int != currentFolderID
                    {
                        alarms.remove(at: alarms.firstIndex(of: object)!)
                    }
                }
            }
            
            if alarms.count > 1
            {
                // Insertion sort algorithm that sorts the alarms in order of time
                for index in 1...alarms.count - 1
                {
                    let value = alarms[index]
                    var position = index

                    while position > 0 && getMinutes(time: alarms[position - 1].value(forKey:"time") as! String)["totalTime"]! > getMinutes(time: value.value(forKey:"time") as! String)["totalTime"]!
                    {
                        alarms[position] = alarms[position - 1]
                        position -= 1
                    }

                    alarms[position] = value
                }
            }
        }
        catch let error as NSError
        {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return alarms.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Displays all folders onto the main screen
        if alarms.count > 0
        {
            
            
            let alarm = alarms[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "alarm", for: indexPath) as! AlarmCell
            
            let name:String = (alarm.value(forKeyPath: "name") as? String)!
            
            cell.label?.text = name.count >= 15 ? String(name.prefix(15)) + "..." : name
            cell.time?.text = alarm.value(forKeyPath: "time") as? String
            
            // If the alarm is activated, it will display as grey, and the switch will be off. Otherwise, it will be white with the switch on.
            let isSwitchOn = alarm.value(forKeyPath: "activated") as! Int == 1 ? true : false
            cell.activateSwitch.setOn(isSwitchOn, animated: false)
            
            if cell.activateSwitch.isOn
            {
                cell.time?.textColor = UIColor.white
                cell.label?.textColor = UIColor.white
            }
            else
            {
                cell.time?.textColor = UIColor.gray
                cell.label?.textColor = UIColor.gray
            }
            
            cell.editImage!.isHidden = !isEditOn
            cell.activateSwitch!.isHidden = isEditOn
            
            cell.alarmID = (alarm.value(forKeyPath: "alarmID") as? Int)!
            
            return cell
        }
        
        return UITableViewCell()

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let currentTime:String = (alarms[indexPath.row].value(forKey:"time") as? String)!
        
        print(currentTime)
        
        if isEditOn == true
        {
            let createAlarmVC = storyBoard.instantiateViewController(withIdentifier: "CreateAlarmViewController") as! CreateAlarmViewController
            
            createAlarmVC.editingTime = currentTime
            createAlarmVC.isEditOn = true
            
            createAlarmVC.modalPresentationStyle = .fullScreen
            self.present(createAlarmVC, animated: true, completion: nil)

        }
        
            
    }
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// Given a time in the format hour:minutes AM/PM, returns how many minutes away from 12AM that time is.
// The function will return an array of three integers, which is in the format of: [HOURS, MINUTES, TOTAL MINUTES]



