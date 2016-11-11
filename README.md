# GLNotificationBar

[![CI Status](http://img.shields.io/travis/gokul/GLNotificationBar.svg?style=flat)](https://travis-ci.org/gokul/GLNotificationBar)
[![Version](https://img.shields.io/cocoapods/v/GLNotificationBar.svg?style=flat)](http://cocoapods.org/pods/GLNotificationBar)
[![License](https://img.shields.io/cocoapods/l/GLNotificationBar.svg?style=flat)](http://cocoapods.org/pods/GLNotificationBar)
[![Platform](https://img.shields.io/cocoapods/p/GLNotificationBar.svg?style=flat)](http://cocoapods.org/pods/GLNotificationBar)

## Note

 `GLNotificationBar` is a library that allows you to easily create banner notifications that appear on top of screen, used to handle push notification in active state.

## Example

 To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
 `GLNotificationBar` uses ARC and requires iOS 8.0+.

## Installation

### CocoaPods

GLNotificationBar is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

`pod 'GLNotificationBar'`

### Manual
Copy the file `GLNotificationBar.swift` & `GLNotificationBar.xib` to your project.

- `GLNotificationBar` is simple to use,implementation is similar to `UIAlertController`.

   ```
      let notificationBar = GLNotificationBar(title: "hallowean", message: "😎Hi there! We've missed you. Enjoy the new hallowean sticker,borders,bgs on your app.😈🎅🏻", preferredStyle: .DetailedBanner, handler: nil)

   ```

   This simply presents GLNotificationBar with given title and message,handler can be used to catch tap gesture on notification bar. The default behavior of notification bar is, dismissed automatically when tapped on it.

There are two types of `GLNotificationBar` style and Five type of `GLNotifyAction` types.

1. .DetailedBanner
   * *.DetailedBanner* style is similar to ios10 style notification bar, swiping down this type of notification open's in detail, which may include `GLNotifyAction's`
   `GLNotifyAction` can be added to `GLNotificationBar` as follows
   
     ```
        let cancelButton = GLNotifyAction(title: "Cancel", style: .Cancel) { (result) in
           print(result.actionTitle)
        }
        notificationBar.addAction(cancelButton)
      ```

      **OR**
      ```
        notificationBar.addAction(GLNotifyAction(title: "Cancel", style: .Cancel) { (result) in
          print(result.actionTitle)
      })
     ```
   * *GLNotifyAction* also has four different types each performs their respective action.
     ```
        public enum GLNotificationActionType {
            case Default  // Apply the default style to the action’s button.
            case Destructive  //Apply a style that indicates the action might change or delete data.
            case TextInput  //Apply a style that indicates the action opens an textinput field helps to respond notification as string.
            case OnlyTextInput  //Apply a style which removes all other action added and simply adds text field as input to respond notification.
            case Cancel  //Apply a style that indicates the action cancels the operation and leaves things unchanged.
       }
    
   ![DetailedBanner](ScreenShots/DetailedBanner.gif)

2. .SimpleBanner
   * *.SimpleBanner* is similar to *.DetailedBanner* in appearance, but it's options are restricted. It can't be swiped down to open in detail form.
   * `GLNotifyAction` added to this type of notification bar will not be taken into account.
   
   ![SimpleBanner](ScreenShots/SimpleBanner.gif)

3. `GLNotifyAction`'s *.OnlyTextInput*
   ``` 
      notificationBar.addAction(GLNotifyAction(title: "Reply", style: .OnlyTextInput) { (result) in
         print(result.textResponse)
      })
   ```
      * *.OnlyTextInput* is some what different from other action types.
      * Adding this action removes all other action added and stight away presents textfield as option for user input without any user interaction. 
      * This helps user to repond to a notification with text.

   ![TextInput_ActionType](ScreenShots/TextInput_ActionType.gif)


## Author

gokul, gokulece26@gmail.com

## License

GLNotificationBar is available under the MIT license. See the LICENSE file for more info.
