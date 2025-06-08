
# Flutter Exam - Calendar application

A simple and functional calendar mobile app using Flutter and Dart, with basic authentication and event management. Users can log in, create/edit/delete events, and view their schedule in various formats.



## Deployment

To deploy this project:

**IMPORTANT:** This project is written for Android only, using a Windows development environment.
1. Install Flutter
2. Install Firebase
3. Install VSCode (optional)
4. Install Android SDK

Then, open the root directory of the project and run these commands:
```
  flutter pub get
  flutter run
```


## Flow chart

```mermaid
graph TD
Z[Login] --> A(Calendar)
Z --> B(My Profile)
Z --> C(My Events)
B --> Z
Z --> E(Register)
B --> E
Z --> F(My Events)
A ..-> I{Create events}
A ..-> H{Edit events}
F ..-> H
F ..-> L{Delete events}
B ..-> K{Edit profile name}
B ..-> M{Log Out}
B ..-> N{Log In user}
E ..-> O{Register user}
Z ..-> N
```
