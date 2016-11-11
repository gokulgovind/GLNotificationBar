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
    
    
    @IBAction func showNotification(sender: AnyObject) {
        
        var style:GLNotificationStyle!
        
        if notificationBarType.selectedSegmentIndex == 0 {
            style = .DetailedBanner
        }else{
            style = .SimpleBanner
        }
        
        let notificationBar = GLNotificationBar(title: notificationTitle.text, message:notificationMessage.text , preferredStyle:style) { (bool) in
            let alert = UIAlertController(title: "Handler", message: "Catch didSelectNotification action in GLNotificationBar completion handler.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        if notificationAction.on {
            //Type: .Cancel
            notificationBar.addAction(GLNotifyAction(title: "Cancel", style: .Cancel, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply a style that indicates the action cancels the operation and leaves things unchanged.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }))
            
            //Type: .Destructive
            notificationBar.addAction(GLNotifyAction(title: "Destructive", style: .Destructive, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: " Apply a style that indicates the action might change or delete data.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }))
            
            //Type: .Default
            notificationBar.addAction(GLNotifyAction(title: "Default", style: .Default, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply the default style to the action’s button.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }))
            
            //Type: .TextInput
            notificationBar.addAction(GLNotifyAction(title: "Text Input", style: .TextInput, handler: { (result) in
                let alert = UIAlertController(title: result.actionTitle, message: "Apply a style that indicates the action opens an textinput field helps to respond notification as string.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }))
            
            
            //Type: .OnlyTextInput
            
//            notificationBar.addAction(GLNotifyAction(title: "OK", style: .OnlyTextInput, handler: { (result) in
//                let alert = UIAlertController(title: result.actionTitle, message: " Apply a style which removes all other action added and simply adds text field as input to respond notification.", preferredStyle: .Alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            }))
        }
        
        
        notificationBar.showTime(stepper.value)
        
        if sound.on {
            notificationBar.notificationSound(soundName.text, ofType: soundType.text, vibrate: vibrate.on)
        }
        
    }
    
    @IBAction func hideKeyboard(sender: UIButton!) {
        self.view.endEditing(true)
    }
    
    @IBAction func timeOutInterval(sender: UIStepper) {
        timeOutLabel.text = "Time out interval  \(String(sender.value))"
    }
    
}


extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

