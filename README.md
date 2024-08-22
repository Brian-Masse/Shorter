# Shorter

v1.2.0

Capture and send daily moments directly to your friends home / lock screne to stay in touch over long distances
> [iOS App, Swift + SwiftUI, MongoDB + Realm DeviceSync]

## **Package Dependencies**

[**UIUniversals**](https://github.com/Brian-Masse/UIUniversals)

- UIUniversals is a collection of custom swift & swiftUI views, viewModifiers, and extensions. They are designed to be functional and styled views out of the box, however they boast high customization and flexibility to fit into a variety of apps and projects.
- It contains many of the buttons and styles used throughout the app, mostly to ensure the app presentation is consistent

[**RealmSwift**](https://github.com/realm/realm-swift)

- Realm is a mobile database that runs directly inside phones, tablets or wearables. This repository holds the source code for the iOS, macOS, tvOS & watchOS versions of Realm Swift & Realm Objective-C.
- Realm is the primary database manager in Recall. It connects to a MongoDB backend when online, and stores user data locally when offline


## **Change Log**

### **v1.1.2**

- Fixed a bug that prevents users from submittng posts

### **v1.1.1**

NEW FEATURES
- Added a Scroll Gesture to access long Shorter Post Notes

CHANGES
- Fixed a bug that prevented update notifcations from sending to physical devices
- Made Post previews larger
- Improved the Primary Post Carousel
- Removed the Additional Status Section on Posts

### **v1.1.0**

NEW FEATURES
- Added a pull down to refresh on the home page post list
- Added notifications for when your friends post


CAHNGES
- Decreased the launch time of the app
- Updated the app icon
- Removed the rotation animation during app launch
