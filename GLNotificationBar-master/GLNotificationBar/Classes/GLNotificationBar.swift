//
//  GLNotificationBar.swift
//  GLNotificationBar
//
//  Created by gokul on 17/10/16.
//  Copyright (c) 2016 gokul. All rights reserved.
//

import UIKit
import AVFoundation
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

/**
 Notification action types.
 - Default
 - Destructive
 - TextInput
 - OnlyTextInput
 - Cancel
 */
@objc public enum GLNotificationActionType: Int {
    /// Default: Apply the default style to the action’s button.
    case `default` = 0
    /// Destructive: Apply a style that indicates the action might change or delete data.
    case destructive
    /// TextInput: Apply a style that indicates the action opens an textinput field helps to respond notification as string.
    case textInput
    /// OnlyTextInput: Apply a style which removes all other action added and simply adds text field as input to respond notification.
    case onlyTextInput
    /// Cancel: Apply a style that indicates the action cancels the operation and leaves things unchanged.
    case cancel
}

/**
 Notification action types.
 - SimpleBanner
 - DetailedBanner
 */
@objc public enum GLNotificationStyle: Int {
    /// SimpleBanner: Apply the SimpleBanner style that displays notification as simple banner,it can't open in detail by swiping down.
    case simpleBanner = 0
    /// DetailedBanner: Apply a style that opens message in detail with `GLNotifyAction` if added.
    case detailedBanner
}

enum PanDirection: Int {
    case up = -1
    case down = 1
}

enum DeviceOrientation {
    case portrait
    case landscape
}

/// Default height of `GLNotificationBar` is 100
let BAR_HEIGHT: CGFloat = 100

/// Default display time of `GLNotificationBar` is 5s
var SHOW_TIME: Double = 5

let APP_DELEGATE = UIApplication.shared
let frameWidth: CGFloat = UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.size.width

var appIconName: String!
var appName: String!
var showNotificationInDetail = true
var notificationBar: CustomView!
var audioPlayer = AVAudioPlayer()
var actionArray = [GLNotifyAction]()

var block: (() -> Void)?
var timer: Timer?

var messageDidSelect: ((Bool) -> Void)?

/**
 A GLNotificationBar object displays an banner message to user (**iOS 10 Style**) over top of the screen which helps to handle local or remote notification when app is in active state.

 Can add `GLNotifyAction` as action to the message, which provides `button or text input` fields to respond to notification.

 */
open class GLNotificationBar: NSObject {

    @objc public override init() {
        super.init()
    }

    /**
     Creates and returns a notification bar for displaying an alert to the user.
     An initialized notificatio bar object.

     - Parameter title:  The title of the alert. Use this string to get the user’s attention and communicate the reason for the notification.

     - Parameter message:   Descriptive text that provides additional details about the reason for the alert.

     - Parameter preferredStyle:   The style to use when presenting the notification bar. Use this parameter to configure the notification bar as an `simple banner` or as a `detailed banner (as iOS 10 notification)`.

     - Parameter handler:  A block to execute when the user selects the notification message. This block has no return value and takes the selected action object as its only parameter.

     - Returns: A inilized GLNotificationBar object.
     */

    @objc public init(title: String, message: String, preferredStyle: GLNotificationStyle, handler: ((Bool) -> Void)?) {
        super.init()

        actionArray = [GLNotifyAction]()
        messageDidSelect = handler
        if (APP_DELEGATE.keyWindow?.subviews) == nil {
            let time = DispatchTime.now() + Double(Int64(5.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
                self.setUpNotificationBar(title, body: message, notificationStyle: preferredStyle)
            })
        } else {
            setUpNotificationBar(title, body: message, notificationStyle: preferredStyle)
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            if SHOW_TIME != 0 {
                if timer != nil {
                    timer!.invalidate()
                }
                timer = Timer.scheduledTimer(timeInterval: SHOW_TIME - 1.0, target: self, selector: #selector(self.hideNotification(_:)), userInfo: nil, repeats: false
                )
            }
        }
    }

    /**
     *showTime* hides the notification bar after given time period.

     - Parameter timeInSec:   Enter the time in seconds, the default value is `5 Sec`. If 0 is set, notification bar auto hide will be disabled.

     - Returns: No return value.
     */

    @objc open func showTime(_ timeInSec: Double) {
        SHOW_TIME = timeInSec
    }

    /**
     *notificationSound* helps in playing the sound file while displaying notification, If file name or type does't found.Default sound will be played.

     - Parameter name:   Name of the sound file in bundle.

     - Parameter ofType:   Sound formate `(.waw, .mp3 etc..)`

     - Parameter vibrate:   `Bool` value which helps to tutn on and off vibrate for notification `(NOTE: It may change depending on device sound settings)`.

     - Returns: No return value.
     */
    @objc open func notificationSound(_ name: String!, ofType: String!, vibrate: Bool) {

        if vibrate {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        guard let path = Bundle.main.path(forResource: name, ofType: ofType) else {
            NSLog("\n#NOTE: File name or type does't found.Default sound will be played.\n")
            AudioServicesPlaySystemSound(1054)
            return
        }
        let pianoSound = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: pianoSound, fileTypeHint: nil)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {
            AudioServicesPlaySystemSound(1054)
            print("Unable to play sound.Default sound will be played.")
        }
    }

    /**
     `addAction` helps in adding `GLNotifyAction` to notification bar as options to respond notification.

     - Parameter action:   add's `GLNotifyAction` object as action which including the title to display in the button, button style , and a handler to execute when the user taps the button

     - Returns: No return value.
     */

    @objc open func addAction(_ action: GLNotifyAction) {
        actionArray.append(action) // Action for notification didselect
    }

    @IBAction func hideNotification(_ sender: UIButton) {
        if notificationBar != nil {
            UIView.animate(withDuration: 0.5, animations: {
                notificationBar.frame.origin = CGPoint(x: 0, y: -BAR_HEIGHT)
            }, completion: { (yes) in
                notificationBar.removeFromSuperview()
                APP_DELEGATE.keyWindow?.windowLevel = 0.0
            })
        }
    }

    fileprivate func setUpNotificationBar(_ header: String, body: String, notificationStyle: GLNotificationStyle) {

        if let windowSubView = APP_DELEGATE.keyWindow?.subviews {
            for subView in (windowSubView) { // To clear old notification from queue
                if subView is CustomView {
                    subView.removeFromSuperview()
                }
            }
        }
        notificationBar = CustomView(frame: CGRect(x: 0, y: -BAR_HEIGHT, width: frameWidth, height: BAR_HEIGHT))
        notificationBar.translatesAutoresizingMaskIntoConstraints = false

        switch notificationStyle {
        case .detailedBanner:
            notificationBar.notificationStyleIndicator.isHidden = false
            showNotificationInDetail = true
            break
        default:
            notificationBar.notificationStyleIndicator.isHidden = true
            showNotificationInDetail = false
            break
        }

        if header.characters.count == 0 {
            notificationBar.body.text = body
        } else {
            let attributeString = NSMutableAttributedString(string: String("\(header)\n\(body)"))
            attributeString.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)], range: NSRange(location: 0, length: header.characters.count))
            notificationBar.body.attributedText = attributeString
        }

        var infoDic: Dictionary = Bundle.main.infoDictionary!
        appName = infoDic["CFBundleName"] as? String
        notificationBar.header.text = appName

        if infoDic["CFBundleIcons"] != nil {
            infoDic = infoDic["CFBundleIcons"] as! Dictionary
            infoDic = infoDic["CFBundlePrimaryIcon"] as! Dictionary
            appIconName = (infoDic["CFBundleIconFiles"]! as AnyObject).object(at: 0) as! String
            notificationBar.appIcon.image = UIImage(named: appIconName)

        } else {
            notificationBar.appIcon.layer.borderColor = UIColor.gray.cgColor
            notificationBar.appIcon.layer.borderWidth = 1.0

            appIconName = ""
            print("Oops... no app icon found")
        }

        notificationBar.appIcon.layer.cornerRadius = 5.0
        notificationBar.appIcon.clipsToBounds = true

        notificationBar.visualEffectView.layer.cornerRadius = 14.0
        notificationBar.visualEffectView.clipsToBounds = true

        let didSelectMessage = UITapGestureRecognizer(target: self, action: #selector(CustomView.didSelectmessage(_:)))
        notificationBar.addGestureRecognizer(didSelectMessage)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            let frame = CGRect(x: 0, y: 0, width: frameWidth, height: BAR_HEIGHT)
            notificationBar.frame = frame
        }, completion: nil)

        APP_DELEGATE.keyWindow?.windowLevel = (UIWindowLevelStatusBar + 1)
        APP_DELEGATE.keyWindow?.addSubview(notificationBar)

        var constraints = [NSLayoutConstraint]()

        let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": notificationBar])
        constraints += horizontal

        let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view(100)]", options: [], metrics: nil, views: ["view": notificationBar])
        constraints += vertical

        NSLayoutConstraint.activate(constraints)
    }
}

/**
 A GLNotifyAction object represents an action that can be taken when tapping a button in an `GLNotificationBar`. You use this class to configure information about a single action, including the title to display in the button, any styling information, and a handler to execute when the user taps the button. After creating an notificatio action object, add it to a `GLNotificationBar` object before displaying the corresponding notification to the user.
 */

open class GLNotifyAction: NSObject {
    @objc open var actionTitle: String?
    @objc open var textResponse: String?
    @objc open var actionStyle: GLNotificationActionType = .default
    var didSelectAction: ((GLNotifyAction) -> Void)?

    @objc public override init() {
        super.init()
    }

    /**
     Init a notification action and add it as action to `GLNotificationBar`.

     - Parameter title:   Title to be displayed in the button.

     - Parameter style:   Helps to set different style such as `(.Default, .Destructive,  .Cancel, .TextInput, .OnlyTextInput)` to button depending upon the need

     - Parameter handler:   A block to execute when the user selects the action. This block has no return value and takes the selected action object as its only parameter.

     - Returns: No return value.
     */

    @objc public init(title: String, style: GLNotificationActionType, handler: ((GLNotifyAction) -> Void)?) {
        actionTitle = title
        actionStyle = style
        didSelectAction = handler
    }
}

class CustomView: UIView {
    // MARK: Outlets:
    @IBOutlet fileprivate var view: UIView?
    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var body: UILabel!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var appIcon: UIImageView!
    @IBOutlet weak var notificationStyleIndicator: UIView!

    // MARK: Variables:
    var dismissLabelAlpha: CGFloat = 0.0
    var dismissLimitReached = false

    var toolBarBottomConstraint: NSLayoutConstraint?

    // MARK: Constants:
    let myScrollView = UIScrollView()
    let notificationActionView = UIVisualEffectView()
    let mainView = UIView()
    let dismissLabel = UILabel()
    let backgroudView = UIVisualEffectView()
    let textField = UITextField()
    let toolBar = UIToolbar()
    let notificationMessage = UITextView()

    // MARK: Init nib file:
    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        // self.commonInit()
    }

    fileprivate func commonInit() {
        Bundle(for: CustomView.self)
            .loadNibNamed("GLNotificationBar", owner: self, options: nil)
        //        NSBundle.mainBundle().loadNibNamed("GLNotificationBar", owner: self, options: nil)
        guard let content = view else { return }
        content.frame = self.bounds
        content.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.addSubview(content)

        NotificationCenter.default.addObserver(self, selector: #selector(CustomView.keyboardWillShown(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CustomView.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    // MARK: Open in detail:
    func setUpDetailedNotificationBar(_ header: String!, body: String!, action: [GLNotifyAction]!) {
        notificationStyleIndicator.layer.cornerRadius = 3.0
        notificationStyleIndicator.alpha = 0.5

        // Blurry Back ground
        let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(CustomView.didSelectmessage(_:)))
        backgroudView.addGestureRecognizer(tapGesture)
        backgroudView.effect = UIBlurEffect(style: .dark)
        backgroudView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // support for device rotation
        backgroudView.translatesAutoresizingMaskIntoConstraints = false

        let tapToClose = UITapGestureRecognizer(target: self, action: #selector(CustomView.tapToClose(_:)))
        tapToClose.delegate = self
        backgroudView.addGestureRecognizer(tapToClose)
        // Main_View containing message banner and buttonAction.

        mainView.backgroundColor = UIColor.clear
        mainView.translatesAutoresizingMaskIntoConstraints = false

        // Notification Banner
        let detailedbanner = UIView()
        detailedbanner.translatesAutoresizingMaskIntoConstraints = false
        detailedbanner.backgroundColor = UIColor.white
        detailedbanner.layer.cornerRadius = 14.0
        detailedbanner.clipsToBounds = true

        let didSelectMessage = UITapGestureRecognizer(target: self, action: #selector(CustomView.didSelectmessage(_:)))
        detailedbanner.addGestureRecognizer(didSelectMessage)

        mainView.addSubview(detailedbanner)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(CustomView.handleDetailedPanGesture(_:)))
        detailedbanner.addGestureRecognizer(pan)

        backgroudView.addSubview(mainView)

        dismissLabel.translatesAutoresizingMaskIntoConstraints = false
        dismissLabel.text = "DISMISS"
        dismissLabel.textAlignment = NSTextAlignment.center
        dismissLabel.textColor = UIColor.white
        dismissLabel.font = UIFont.systemFont(ofSize: 14)
        dismissLabel.alpha = 0.0
        mainView.addSubview(dismissLabel)

        // Message Title
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = appName
        title.backgroundColor = UIColor.clear
        title.textColor = UIColor.gray
        title.font = UIFont.systemFont(ofSize: 14)
        detailedbanner.addSubview(title)

        // Message body
        let tempContainer = body.components(separatedBy: "\n")
        let rangeStr = tempContainer[0]
        let attributeString = NSMutableAttributedString(string: body)
        if body.contains("\n") {
            attributeString.addAttributes([NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)], range: NSRange(location: 0, length: rangeStr.characters.count))
            attributeString.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 15)], range: NSRange(location: rangeStr.characters.count, length: tempContainer[1].characters.count))
        } else {
            attributeString.addAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 15)], range: NSRange(location: 0, length: body.characters.count))
        }

        notificationMessage.translatesAutoresizingMaskIntoConstraints = false
        notificationMessage.font = UIFont.systemFont(ofSize: 25)
        notificationMessage.backgroundColor = UIColor.clear
        notificationMessage.textColor = UIColor.black
        notificationMessage.showsHorizontalScrollIndicator = false
        notificationMessage.isScrollEnabled = false
        notificationMessage.isEditable = false
        notificationMessage.attributedText = attributeString

        detailedbanner.addSubview(notificationMessage)

        // Separator Line
        let seprator = UIView()
        seprator.backgroundColor = UIColor.lightGray
        seprator.translatesAutoresizingMaskIntoConstraints = false
        detailedbanner.addSubview(seprator)

        // AppIcon
        let appIcon = UIImageView()
        if appIconName.characters.count != 0 {
            appIcon.image = UIImage(named: appIconName)
        } else {
            appIcon.layer.borderColor = UIColor.gray.cgColor
            appIcon.layer.borderWidth = 1.0
        }

        appIcon.layer.cornerRadius = 5.0
        appIcon.clipsToBounds = true
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        detailedbanner.addSubview(appIcon)

        // Close Button
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "Close.png"), for: UIControlState())
        closeButton.addTarget(self, action: #selector(CustomView.closeMessage(_:)), for: UIControlEvents.touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        detailedbanner.addSubview(closeButton)

        UIApplication.shared.keyWindow!.addSubview(backgroudView)

        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.isHidden = true
        backgroudView.addSubview(toolBar)

        // Adding autolayout

        addAutoLayout(["visualEffectView": backgroudView, "Main_view": mainView, "host_View": detailedbanner, "Button_actionView": createNotificationActionView(), "container_Label": notificationMessage, "header_Label": title, "separator": seprator, "app_Icon": appIcon, "close_Button": closeButton, "Dismiss": dismissLabel, "Tool_Bar": toolBar])

        self.mainView.transform = CGAffineTransform.identity.scaledBy(x: 0.0, y: 0.0)
        UIView.animate(withDuration: 0.3 / 1.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.mainView.transform = CGAffineTransform.identity.scaledBy(x: 1.1, y: 1.1)
        }) { (bool) in
            UIView.animate(withDuration: 0.3 / 2, delay: 0.0, options: .curveEaseIn, animations: {
                self.mainView.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }

    func createNotificationActionView() -> UIVisualEffectView {
        sortActionArray() // sort button action on condition

        notificationActionView.translatesAutoresizingMaskIntoConstraints = false
        notificationActionView.effect = UIBlurEffect(style: .extraLight)
        notificationActionView.layer.cornerRadius = 14.0
        notificationActionView.clipsToBounds = true
        mainView.addSubview(notificationActionView)

        let tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        notificationActionView.addSubview(tableView)

        var height = "0"
        let tempLabel = UILabel()
        tempLabel.text = notificationMessage.text!
        let test = CGFloat(actionArray.count * 50) + tempLabel.heightToFit(notificationMessage.text!, width: (APP_DELEGATE.keyWindow?.frame.size.width)!)
        if test > APP_DELEGATE.keyWindow!.frame.size.height - 50 {
            tableView.isScrollEnabled = actionArray.count > 4 ? true : false
            notificationMessage.isScrollEnabled = true
            height = actionArray.count > 4 ? "200" : String(actionArray.count * 50)
        } else {
            tableView.isScrollEnabled = false
            height = String(actionArray.count * 50)
        }

        var constraints = [NSLayoutConstraint]()
        let scrollHorizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|[table]|", options: [], metrics: nil, views: ["table": tableView])
        constraints += scrollHorizontalConstraint

        let scrollVerticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|[table(h)]|", options: [], metrics: ["h": height], views: ["table": tableView])
        constraints += scrollVerticalConstraint

        NSLayoutConstraint.activate(constraints)

        return notificationActionView
    }

    func addSeprator(_ toObject: AnyObject) -> UIView {
        let frame = toObject.frame
        let seprator = UIView(frame: CGRect(x: 0, y: (frame?.height)! + 3, width: (APP_DELEGATE.keyWindow?.frame.size.width)! - 20, height: 0.5))
        seprator.backgroundColor = UIColor.gray
        seprator.alpha = 0.6
        return seprator
    }

    // MARK: AutoLayout Constraints
    func addAutoLayout(_ viewDic: [String: AnyObject]) {

        var allConstraints = [NSLayoutConstraint]()

        // Object Horizontal layout
        let visualEffectHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[visualEffectView]|", options: [], metrics: nil, views: viewDic)
        allConstraints += visualEffectHorizontal

        let mainHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[Main_view]|", options: [], metrics: nil, views: viewDic)
        allConstraints += mainHorizontalConstraints

        let hostHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[host_View]-|", options: [], metrics: nil, views: viewDic)
        allConstraints += hostHorizontalConstraints

        let actionHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[Button_actionView]-|", options: [], metrics: nil, views: viewDic)
        allConstraints += actionHorizontalConstraints

        let dismissHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[Dismiss]-15-|", options: [], metrics: nil, views: viewDic)
        allConstraints += dismissHorizontalConstraints

        let headerHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[app_Icon(20)]-10-[header_Label]-10-[close_Button(30)]-10-|", options: [], metrics: nil, views: viewDic)
        allConstraints += headerHorizontalConstraints

        let separatorHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[separator]-|", options: [], metrics: nil, views: viewDic)
        allConstraints += separatorHorizontalConstraints

        let labelHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[container_Label]-15-|", options: [], metrics: nil, views: viewDic)
        allConstraints += labelHorizontalConstraints

        let textInputHorizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|[Tool_Bar]|", options: [], metrics: nil, views: viewDic)
        allConstraints += textInputHorizontalConstraint

        // Object Vertical layout

        let visualEffectVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[visualEffectView]|", options: [], metrics: nil, views: viewDic)
        allConstraints += visualEffectVertical

        let main1VerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[Main_view]-(>=10)-|", options: [], metrics: nil, views: viewDic)
        allConstraints += main1VerticalConstraints

        let mainVerticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[Main_view(200@250)]-(>=5)-[Tool_Bar]-(0@250)-|", options: [], metrics: nil, views: viewDic)
        allConstraints += mainVerticalConstraints

        let hostVerticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|[Dismiss]-[host_View(>=20)]-10-[Button_actionView(>=0)]-(>=10)-|", options: [], metrics: nil, views: viewDic)
        allConstraints += hostVerticalConstraint

        let hostSecondVerticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:[host_View]-(>=30)-|", options: [], metrics: nil, views: viewDic)
        allConstraints += hostSecondVerticalConstraint

        let tempLabel = UILabel()
        tempLabel.text = notificationMessage.text!
        let expectedContentheight = CGFloat(actionArray.count * 50) + tempLabel.heightToFit(tempLabel.text!, width: (APP_DELEGATE.keyWindow?.frame.size.width)!)
        var messageHeight = ""
        if expectedContentheight > APP_DELEGATE.keyWindow!.frame.size.height - 50 {
            messageHeight = String(describing: APP_DELEGATE.keyWindow!.frame.size.height - CGFloat(actionArray.count < 4 ? actionArray.count * 50 : 200))
        }
        if messageHeight.characters.count > 0 {
            let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[header_Label(20)]-[separator(1)]-[container_Label(h@750)]-(>=5)-|", options: [], metrics: ["h": messageHeight], views: viewDic)
            allConstraints += verticalConstraint
        } else {
            let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[header_Label(20)]-[separator(1)]-[container_Label(30@250)]-(>=5)-|", options: [], metrics: nil, views: viewDic)
            allConstraints += verticalConstraint
        }

        /* let verticalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-15-[header_Label(20)]-[separator(1)]-[container_Label(30@250)]-(>=5)-|", options: [], metrics: nil, views: viewDic)
         allConstraints += verticalConstraint */

        let appIconVerticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[app_Icon(20)]", options: [], metrics: nil, views: viewDic)
        allConstraints += appIconVerticalConstraint

        let closeVerticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-15-[close_Button(20)]", options: [], metrics: nil, views: viewDic)
        allConstraints += closeVerticalConstraint

        NSLayoutConstraint.activate(allConstraints)
    }

    // MARK: GestureRecognizer:
    @IBAction func didSelectmessage(_ tapgesture: UITapGestureRecognizer) {
        if notificationBar != nil {
            UIView.animate(withDuration: 0.5, animations: {
                notificationBar.frame.origin = CGPoint(x: 0, y: -BAR_HEIGHT)
            }, completion: { (yes) in
                notificationBar.removeFromSuperview()
            })
        }
        closeMessage(nil)
        messageDidSelect?(true)
    }

    @IBAction func tapToClose(_ tapgesture: UITapGestureRecognizer) {
        closeMessage(nil)
    }

    @IBAction func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let velocity = gestureRecognizer.velocity(in: self)
        let translation = gestureRecognizer.translation(in: self)

        switch gestureRecognizer.state {
        case .began, .changed:
            let directionValue = velocity.y < 1.0 ? -1 : 1

            switch directionValue {
            case PanDirection.up.rawValue: // Swipe up
                gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x, y: gestureRecognizer.view!.center.y + translation.y)
                break
            case PanDirection.down.rawValue: // Swipe Down
                if showNotificationInDetail {
                    gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x, y: gestureRecognizer.view!.center.y + translation.y)
                }
                break
            default:
                break
            }

            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)

            if gestureRecognizer.view?.frame.origin.y > (gestureRecognizer.view?.frame.size.height)! {
                self.removeFromSuperview()
                setUpDetailedNotificationBar(header.text, body: body.text, action: [])
                return
            }

            break
        case .ended:

            if gestureRecognizer.view?.frame.origin.y < -(self.visualEffectView.frame.origin.y) {
                APP_DELEGATE.keyWindow?.windowLevel = 0.0
                actionArray = [GLNotifyAction]() // Clear cached action before leaving
                self.removeFromSuperview()
                return
            }

            UIView.animate(withDuration: 0.5, animations: {
                gestureRecognizer.view?.frame.origin = CGPoint(x: gestureRecognizer.view!.frame.origin.x, y: 10)
            })

            break
        default:
            break
        }
    }

    func handleDetailedPanGesture(_ panGesture: UIPanGestureRecognizer) {

        var isLandScape = false
        let translation = panGesture.translation(in: self)
        let velocity = panGesture.velocity(in: self)
        var panVelocity: CGFloat!

        panGesture.setTranslation(CGPoint(x: 0, y: 0), in: self)

        switch panGesture.state {
        case .changed, .began:
            let orientation = APP_DELEGATE.statusBarOrientation

            switch orientation {
            case .portrait:
                mainView.center = CGPoint(x: mainView.center.x, y: mainView.center.y + (translation.y / 5))
                panVelocity = velocity.y
                break
            case .landscapeLeft:
                mainView.center = CGPoint(x: mainView.center.x, y: mainView.center.y + (translation.x / 5))
                panVelocity = velocity.x
                isLandScape = true
                break
            case .landscapeRight:
                mainView.center = CGPoint(x: mainView.center.x, y: mainView.center.y + (-translation.x / 5))
                panVelocity = -velocity.x
                isLandScape = true
                break
            default:
                break
            }

            let directionValue = panVelocity < 1.0 ? -1 : 1

            switch directionValue {
            case PanDirection.up.rawValue: // Swipe up
                if dismissLabel.alpha > 0.0 {
                    dismissLabelAlpha -= isLandScape ? 0.05 : 0.02
                } else if dismissLabel.alpha <= 1.0 && dismissLimitReached {
                    dismissLimitReached = false
                }
                if panVelocity > -1500 {
                    dismissLimitReached = false
                    dismissLabel.alpha = 0.0
                }
                break
            case PanDirection.down.rawValue: // Swipe down
                if dismissLabel.alpha<1.0 {
                    dismissLabelAlpha += isLandScape ? 0.05 : 0.02
                } else if dismissLabel.alpha >= 1.0 && !dismissLimitReached {
                    dismissLimitReached = true
                    dismissLabel.transform = CGAffineTransform.identity.scaledBy(x: 0.0, y: 0.0)
                    UIView.animate(withDuration: 0.3 / 1.5, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                        self.dismissLabel.transform = CGAffineTransform.identity.scaledBy(x: 1.3, y: 1.3)
                    }) { (bool) in
                        UIView.animate(withDuration: 0.3 / 2, delay: 0.0, options: .curveEaseIn, animations: {
                            self.dismissLabel.transform = CGAffineTransform.identity
                        }, completion: nil)
                    }
                }
                if panVelocity > 2000 {
                    dismissLimitReached = true
                    dismissLabelAlpha = 1.0
                }
                break
            default:
                break
            }
            dismissLabel.alpha = dismissLabelAlpha

            break

        case .ended:

            if dismissLimitReached {
                closeMessage(nil)
                return
            }

            UIView.animate(withDuration: 0.5, animations: {
                self.mainView.frame.origin = CGPoint(x: 0, y: 0)
            })

            dismissLimitReached = false
            dismissLabel.alpha = 0.0
            dismissLabelAlpha = 0.0

            break
        default:
            break
        }
    }

    // MARK: Support:
    func sortActionArray() {
        var tempContainer = [GLNotifyAction]()
        var index = 0
        var isCancelTypeFound = false
        for action in actionArray {

            let style: GLNotificationActionType = action.actionStyle
            switch style {
            case .cancel:
                actionArray.remove(at: index)
                index = index - 1
                if !isCancelTypeFound {
                    isCancelTypeFound = true
                    tempContainer.append(action)
                }
                break
            case .onlyTextInput:
                setUpTextField(action, senderTag: index)
                continue
            default:
                break
            }
            index = index + 1
        }
        if tempContainer.count != 0 {
            actionArray.append(tempContainer[0])
            //            print("\n\n#WARNING: Only one .Cancel type can be added to GLNotifyAction.Others will be not taken into account \n")
        }
    }

    func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }

    func setUpTextField(_ action: GLNotifyAction, senderTag: Int) {

        UIView.animate(withDuration: 1.0, animations: {
            self.notificationActionView.isHidden = true
        }, completion: { (bool) in
            self.notificationActionView.removeFromSuperview()
        })

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = action.actionTitle
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.borderStyle = UITextBorderStyle.roundedRect

        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send", for: UIControlState())
        button.tag = senderTag
        button.setTitleColor(UIColor.init(netHex: 0x095FFE), for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(CustomView.sendButtonPressed(_:)), for: .touchUpInside)

        let barButtonItemOne = UIBarButtonItem(customView: textField)
        let barButtonItemtwo = UIBarButtonItem(customView: button)

        toolBar.isHidden = false
        toolBar.items = [barButtonItemOne, barButtonItemtwo]

        var constraints = [NSLayoutConstraint]()
        let dic = ["textField": textField, "button": button, "Main": toolBar]

        let horizontalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField][button(60)]|", options: [], metrics: nil, views: dic)
        constraints += horizontalConstraint

        let verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[textField(30)]-|", options: [], metrics: nil, views: dic)
        constraints += verticalConstraint

        let verticalConstraint1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[button]-|", options: [], metrics: nil, views: dic)
        constraints += verticalConstraint1

        //        let toolBarTopConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[toolBar]-20-[MainView]", options: [], metrics: nil, views: ["toolBar":toolBar,"MainView":mainView])
        //        constraints += toolBarTopConstraint

        NSLayoutConstraint.activate(constraints)

        toolBarBottomConstraint = NSLayoutConstraint(item: toolBar, attribute: .bottom, relatedBy: .equal, toItem: backgroudView, attribute: .bottom, multiplier: 1, constant: 0)
        backgroudView.addConstraint(toolBarBottomConstraint!)

        let leading = NSLayoutConstraint(item: toolBar, attribute: .leading, relatedBy: .equal, toItem: backgroudView, attribute: .leading, multiplier: 1, constant: 0)
        backgroudView.addConstraint(leading)

        let trailing = NSLayoutConstraint(item: toolBar, attribute: .trailing, relatedBy: .equal, toItem: backgroudView, attribute: .trailing, multiplier: 1, constant: 0)
        backgroudView.addConstraint(trailing)

        let time = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.textField.becomeFirstResponder()
        }
    }

    @IBAction func sendButtonPressed(_ sender: UIButton) {
        let action: GLNotifyAction = actionArray[sender.tag]
        guard let didselectHandler = action.didSelectAction else {
            closeMessage(sender)
            return
        }
        action.textResponse = textField.text
        didselectHandler(action)
        closeMessage(sender)
    }

    @IBAction func closeMessage(_ sender: UIButton?) {
        actionArray = [GLNotifyAction]() // Clear cached action before leaving
        textField.resignFirstResponder()
        APP_DELEGATE.keyWindow?.windowLevel = 0.0

        UIView.animate(withDuration: 0.5, animations: {
            self.mainView.frame.origin = CGPoint(x: 0, y: (APP_DELEGATE.keyWindow?.frame.size.height)!)
        }, completion: { (ok) in
            UIView.animate(withDuration: 2.0, delay: 0.5, options: [], animations: {
                self.backgroudView.removeFromSuperview()
            }, completion: nil)
        })
    }

    // MARK: Notification center:
    func keyboardWillShown(_ notification: Notification) {
        let info = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            if self.toolBarBottomConstraint != nil {
                self.toolBarBottomConstraint!.constant = -(keyboardFrame.size.height)
                self.backgroudView.layoutIfNeeded()
            }

        })
    }

    func keyboardWillHide(_ notification: Notification) {
        let info = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            if self.toolBarBottomConstraint != nil {
                self.toolBarBottomConstraint!.constant = keyboardFrame.size.height
                self.backgroudView.layoutIfNeeded()
            }

        })
    }
}

// MARK: Extensions:
extension CustomView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view!.isDescendant(of: notificationActionView) {
            return false
        }
        return true
    }
}

extension CustomView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "GL")
        cell.backgroundColor = UIColor.clear
        cell.drawSeparatorLine()
        let action = actionArray[(indexPath as NSIndexPath).row]
        let style: GLNotificationActionType = action.actionStyle
        switch style {
        case .cancel:
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            break
        case .destructive:
            cell.textLabel?.textColor = UIColor.red
            break
        default:
            break
        }
        cell.textLabel?.text = actionArray[(indexPath as NSIndexPath).row].actionTitle
        cell.textLabel?.textAlignment = NSTextAlignment.center
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actionArray[(indexPath as NSIndexPath).row]
        let style: GLNotificationActionType = action.actionStyle
        switch style {
        case .cancel, .destructive, .default:
            let action: GLNotifyAction = actionArray[(indexPath as NSIndexPath).row]
            guard let didselectHandler = action.didSelectAction else {
                closeMessage(nil)
                return
            }
            didselectHandler(action)
            closeMessage(nil)
            break
        case .textInput:
            self.setUpTextField(action, senderTag: (indexPath as NSIndexPath).row)
            break
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension UITableViewCell {
    func drawSeparatorLine() {
        let border = CALayer()
        border.borderColor = UIColor.gray.cgColor
        border.frame = CGRect(x: 0, y: 49,
                              width: 0, height: 2)
        border.frame.size.width = (APP_DELEGATE.keyWindow?.frame.size.height > APP_DELEGATE.keyWindow?.frame.size.width ? APP_DELEGATE.keyWindow? .frame.size.height : APP_DELEGATE.keyWindow?.frame.size.width)!

        border.borderWidth = 0.75
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }
}

extension UILabel {
    func heightToFit(_ string: String, width: CGFloat) -> CGFloat {
        let attributes = [NSFontAttributeName: font]
        numberOfLines = 0
        lineBreakMode = NSLineBreakMode.byWordWrapping
        let rect = string.boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)
        return rect.height
        //        self.frame.size.height = rect.height
    }

    func resizeHeightToFit() {
        let attributes = [NSFontAttributeName: font]
        numberOfLines = 0
        lineBreakMode = NSLineBreakMode.byWordWrapping
        let rect = text!.boundingRect(with: CGSize(width: frame.size.width, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: attributes, context: nil)
        self.frame.size.height = rect.height
    }
}
