//
//  ViewController.swift
//  GLNotificationBar
//
//  Created by gokul on 11/11/2016.
//  Copyright (c) 2016 gokul. All rights reserved.
//

import UIKit
import AVFoundation
import GLNotificationBar

class ViewController: UIViewController {
    
    @IBOutlet weak var notificationTitle: UITextField!
    @IBOutlet weak var notificationMessage: UITextField!
    @IBOutlet weak var soundName: UITextField!
    @IBOutlet weak var soundType: UITextField!
    
    @IBOutlet weak var vibrate: UISwitch!
    @IBOutlet weak var sound: UISwitch!
    @IBOutlet weak var notificationAction: UISwitch!
    
    @IBOutlet weak var timeOutLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var notificationBarType: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        self.view .addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func showNotification(_ sender: AnyObject) {
        
        var style:GLNotificationStyle!
        
        if notificationBarType.selectedSegmentIndex == 0 {
            style = .detailedBanner
        }else{
            style = .simpleBanner
        }
        
        let notificationBar = GLNotificationBar(title: notificationTitle.text!, message:notificationMessage.text! , preferredStyle:style) { (bool) in
            let alert = UIAlertController(title: "Handler", message: "Catch didSelectNotification action in GLNotificationBar completion handler.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        if notificationAction.isOn {
            //Type: .Cancel
            notificationBar.addAction(GLNotifyAction(title: "Cancel", style: .cancel, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply a style that indicates the action cancels the operation and leaves things unchanged.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            
            //Type: .Destructive
            notificationBar.addAction(GLNotifyAction(title: "Destructive", style: .destructive, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: " Apply a style that indicates the action might change or delete data.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            
            //Type: .Default
            notificationBar.addAction(GLNotifyAction(title: "Default", style: .default, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply the default style to the action’s button.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            
            //Type: .TextInput
            notificationBar.addAction(GLNotifyAction(title: "Text Input", style: .textInput, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply a style that indicates the action opens an textinput field helps to respond notification as string.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }))
            
            
//            //Type: .OnlyTextInput
//            
//            notificationBar.addAction(GLNotifyAction(title: "Reply", style: .OnlyTextInput, handler: { (result) in
//                let alert = UIAlertController(title: result.actionTitle, message: " Apply a style which removes all other action added and simply adds text field as input to respond notification.", preferredStyle: .Alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }))
        }
        
        
        notificationBar.showTime(stepper.value)
        
        if sound.isOn {
            notificationBar.notificationSound(soundName.text, ofType: soundType.text, vibrate: vibrate.isOn)
        }
        
    }
    
    @IBAction func hideKeyboard(_ sender: UIButton!) {
        self.view.endEditing(true)
    }
    
    @IBAction func timeOutInterval(_ sender: UIStepper) {
        timeOutLabel.text = "Time out interval  \(String(sender.value))"
    }
    
}


extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

