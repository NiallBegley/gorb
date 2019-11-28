//
//  PickerTableViewController.swift
//  gorb
//
//  Created by Niall on 9/19/19.
//  Copyright © 2019 Niall Begley. All rights reserved.
//

import UIKit

protocol PickerDelegate : class {
    func didSelect(_ value : String)
}

class PickerTableViewController: UITableViewController, UITextFieldDelegate {

    private var setter : ((_ : String) -> ())?
    private var getter : (() -> String)?
    private var dataSetter : ((_ : [String]) -> ())?
    private var data : [String] = []
    private var validator : ((_ : String) -> Bool)?
    var delegate : PickerDelegate?
    private var validatorErrorMessage : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func setData(_ data : [String], withDataSetter dataSetter: @escaping ((_ : [String]) -> ()), valueGetter get: @escaping (() -> String), andSetter set: @escaping ((_ : String) -> ())) {
        setData(data, withGetter: get, andSetter: set)
        self.dataSetter = dataSetter
        
    }
    
    func setData(_ data : [String], withGetter get: @escaping (() -> String), andSetter set: @escaping ((_ : String) -> ())) {
        self.data = data
        setter = set
        getter = get
        
        tableView.reloadData()
    }
    
    func setValidator(_ validator : @escaping((_ : String) -> Bool), withErrorMessage errormsg : String) {
        self.validator = validator
        validatorErrorMessage = errormsg
    }
    
    fileprivate func commitExistingData() {
        if let cell = tableView.cellForRow(at: IndexPath.init(row: data.count, section: 0)) as? PickerCustomTableViewCell {
            
            //Only validate the text in the last row if it isn't empty.  Return without commiting if it isn't valid
            if let text = cell.textField.text,
                !text.isEmpty,
                !validateText(text) {
                    return
                }
            
            if let dataSetter = self.dataSetter {
                dataSetter(data)
            }

        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if isMovingFromParent || isBeingDismissed,
            tableView.isEditing {
            
            commitExistingData()
        }
    }

    // MARK: - User Interaction
    
    @IBAction func buttonClickedEdit(_ sender: Any) {
        let button = sender as! UIBarButtonItem
        
        if tableView.isEditing {
            button.title = "Edit"
            tableView.setEditing(false, animated: true)
            
            commitExistingData()
        } else {
            button.title = "Done"
            tableView.setEditing(true, animated: true)
        }
        
        tableView.reloadData()
    }
    
    // MARK - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        _ = validateText(textField.text)
        
        return false
    }
    
    func validateText(_ string : String?) -> Bool {
        if let text = string,
            !text.isEmpty,
            let valid = validator {
            if(valid(text)) {
                data.append(text)
                tableView.reloadData()
                
                return true
            } else {
                
                let alert = UIAlertController.init(title: "Error", message: validatorErrorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Okay", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                
            }
        }

        return false
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return tableView.isEditing ? data.count + 1 : data.count
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete,
            indexPath.row >= 0,
            indexPath.row < data.count {
                
                //Deselect the row if its selected before we delete it
                if let get = getter,
                    let set = setter,
                    data[indexPath.row] == get() {
                    set(data[0])
                }
            
            
           // tableView.beginUpdates()
            data.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
          //  tableView.endUpdates()
        } else if editingStyle == .insert {
            
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            if indexPath.row == data.count {
                return .insert
            } else if data.count == 1 {
                return .none
            } else {
                return .delete
            }
        }
        
        return .none
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_ELEMENT_CELL", for: indexPath)
        if indexPath.row >= 0,
            indexPath.row < data.count {

                cell.textLabel?.text = data[indexPath.row]

                if let get = getter,
                    data[indexPath.row] == get() {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            
        } else if indexPath.row == data.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PICKER_CUSTOM_CELL", for: indexPath) as! PickerCustomTableViewCell
            cell.textField.delegate = self
            cell.textField.text = ""
            return cell

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
