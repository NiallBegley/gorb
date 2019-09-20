//
//  PickerTableViewController.swift
//  VideoForReddit
//
//  Created by Niall on 9/19/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

protocol PickerDelegate : class {
    func didSelect(_ value : String)
}

class PickerTableViewController: UITableViewController {

    private var setter : ((_ : String) -> ())?
    private var getter : (() -> String)?
    private var data : [String] = []
    var delegate : PickerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func setData(_ data : [String], withGetter get: @escaping (() -> String), andSetter set: @escaping ((_ : String) -> ())) {
        self.data = data
        setter = set
        getter = get
        tableView.reloadData()
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_ELEMENT_CELL", for: indexPath)

        cell.textLabel?.text = data[indexPath.row]

        if let get = getter,
            data[indexPath.row] == get() {
            
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = data[indexPath.row]
        
        if let set = setter {
            set(value)
        }
        
        tableView.reloadData()
        delegate?.didSelect(value)
    }

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
