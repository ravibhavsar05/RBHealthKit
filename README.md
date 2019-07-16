# RBHealthKit
Demo of the health kit how steps count and blood pressure will be synced.

 ## Requirements

- iOS 11.0+
- Xcode 10.1+
- Swift 5

## Usage
- HealthKit is an app that was introduced in iOS 8. It acts as a central repository for all health-related data, for building users- a biological profile and store workouts and health related data.
- In this, you can fetch the following healthkit data by requesting permission of read & write from healthkit app :
   1. Steps Count : Total steps count from the healthkit app
   2. Distance : Here we will count in both walking + running distance
   3. Blood Pressure : In this app, we have considered the systolic blood pressure, but you can have access both systolic and diastolic blood pressure
      - Note : If you are using diastolic blood pressure, don't forget to ask permission of this from healthkit

## Output
![Healthkit - Animated gif demo](DemoHealthKit/DemoHealthkit.gif)
