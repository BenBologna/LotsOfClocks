//
//  FoldersTableViewController.swift
//  LotsofClocks
//
//  Created by Ben Malaga on 1/7/21.
//

import UIKit
import CoreData
import UserNotifications

// Class for the folder cell
class FolderCell: UITableViewCell{
    @IBOutlet weak var folderName: UILabel!
    @IBOutlet weak var folderSelectImage: UIImageView!
    @IBOutlet weak var alarmCountLabel: UILabel!
    @IBOutlet weak var folderSwitch: UISwitch!
    
    
    var folderID:Int!
    var alarmActivatedList:[NSObject] = []
    
    @IBAction func onFolderSwitchActivated(_ sender: UISwitch)
    {
        let alarmVC = AlarmsViewController()
        
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
                if object.value(forKey:"folderID") as? Int == folderID
                {
                    alarmActivatedList.append(object)
                    
                }
            }
        }
        catch _ as NSError{}
        
        for alarm in alarmActivatedList
        {
            let name:String = alarm.value(forKey: "name") as! String
            let time:String = alarm.value(forKey: "time") as! String
            alarmVC.createNotif(label: name, time: time, alarm: alarm, sender.isOn)
            
            if sender.isOn
            {
                
            }
        }
    
       
    }
    
}

class FoldersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    // MARK:- Variables
    
    @IBOutlet weak var foldersEditButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var folders:[NSManagedObject] = []
    
    var alarms:[NSManagedObject] = []
    
    var alarmsCount:Int = 0
    
    var isTrashEnabled:Bool = false
    
    var isEditOn:Bool = false
    
    
    // MARK:- View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let center = UNUserNotificationCenter.current()

            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if granted
                {
                    print("granted")
                }
            }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        isEditOn = false
        foldersEditButton.title = "Edit"
      
        // Core data setup
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
      
        // Fetches all entities with the entity name of Folder
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Folder")
      
        do
        {
            // Sets the array of all folders that need to be displayed to the fetch request
            folders = try managedContext.fetch(fetchRequest)
        }
        catch let error as NSError
        {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        isTrashEnabled = false
    }
    
    
    // MARK:- IBActions
    
  
    @IBAction func onEditPress(_ sender: Any)
    {
        if isEditOn
        {
            isEditOn = false
            foldersEditButton.title = "Edit"
        }
        else
        {
            isEditOn = true
            foldersEditButton.title = "Done"
        }
        tableView.reloadData()
        
        print("hello world!!!!!")
    }
    
    @IBAction func onClosePress(_ sender: Any)
    {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK:- General Functions
    
    func deleteAllFolders() -> Void
    {
        // Core data setup
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Folder")

        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(batchDeleteRequest)

        } catch {
            // Error Handling
        }
    }
    
    func countAlarms(_ folderID: Int) -> Void
    {
        
        alarmsCount = 0
        
        // Core data setup
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else {return}
      
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Alarm")

        do
        {
            alarms = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            
            for object in alarms
            {
                if object.value(forKey: "folderID") as! Int == folderID
                {
                    alarmsCount = alarmsCount + 1
                }
            }

        }
        catch
        {
           
        }
    }
    

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Displays all folders onto the main screen
        
        let folder = folders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "folder", for: indexPath) as! FolderCell
        
        let name:String = (folder.value(forKeyPath: "name") as? String)!
        
        cell.folderName?.text = name.count >= 15 ? String(name.prefix(15)) + "..." : name
  
        cell.folderID = (folder.value(forKeyPath: "folderID") as? Int)!
        
        cell.folderSelectImage?.image! = isEditOn ? UIImage(systemName: "gearshape")! : UIImage(systemName: "chevron.right")!
        
        countAlarms(folder.value(forKey:"folderID") as! Int)
        
        cell.alarmCountLabel?.text = alarmsCount == 1 ? String(alarmsCount) + " alarm" : String(alarmsCount) + " alarms"
        
    

        return cell
    }
    
    // Called when a folder is selected, saves the selected folders id into the alarms view controller and present the VC.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // If the trash button is enabled, it will delete the folder as well as all of its alarms
        
        // Stores an instance of the storyboard, and the alarms view controller
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let currentFolderID:Int = (folders[indexPath.row].value(forKey:"folderID") as? Int)!
        
        if isEditOn == true
        {
            let createFolderVC = storyBoard.instantiateViewController(withIdentifier: "CreateFolderViewController") as! CreateFolderViewController
            
            createFolderVC.editingFolderID = currentFolderID
            createFolderVC.isEditOn = true
            
            createFolderVC.modalPresentationStyle = .fullScreen
            self.present(createFolderVC, animated: true, completion: nil)

        }
        else
        {
            // Stores an instance of the storyboard, and the alarms view controller
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let alarmsVC = storyBoard.instantiateViewController(withIdentifier: "AlarmsViewController") as! AlarmsViewController
            
            // Sets the current folder id to the selected folders id, and sets the variable in the alarms VC to that ID
            let currentFolderName:String = (folders[indexPath.row].value(forKey:"name") as? String)!
            
            alarmsVC.currentFolderID = currentFolderID
            alarmsVC.currentFolderName = currentFolderName
            
            alarmsVC.modalPresentationStyle = .fullScreen
            self.present(alarmsVC, animated: true, completion: nil)
            
            
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
