
# Flutter Exam - Calendar application

A simple and functional calendar mobile app using Flutter and Dart, with basic authentication and event management. Users can log in, create/edit/delete events, and view their schedule in various formats.



## Deployment

To deploy this project:

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
A[Calendar] --> B(My Profile)
A --> C(My Events)
B --> D(Login)
B --> E(Register)
A --> F(My Events)
A --> G(Add/Edit Events)
G ..-> I{Create events}
G ..-> H{Edit events}
F ..-> H
F ..-> L{Delete events}
B ..-> K{Edit profile name}
B ..-> M{Log Out}
B ..-> N{Log In user}
B ..-> O{Register user}
```
