## loading icon button [![Pub Version (including pre-releases)](https://img.shields.io/pub/v/loading_icon_button?include_prereleases)](https://pub.dev/packages/loading_icon_button) [![GitHub issues](https://img.shields.io/github/issues-raw/rvndsngwn/loading_icon_button)](https://github.com/rvndsngwn/loading_icon_button/issues) [![GitHub contributors](https://img.shields.io/github/contributors/rvndsngwn/loading_icon_button)](https://github.com/rvndsngwn/loading_icon_button/graphs/contributors)
<table>
  <tr>
     <td>LoadingButton</td>
     <td>LoadingButton</td>
     <td>ArgonButton</td>
  </tr>
  <tr>
<td><img src="https://raw.githubusercontent.com/mohesu/loading_icon_button/master/screenshots/gif1.gif" width=250 height=480 alt=""></td>
<td><img src="https://raw.githubusercontent.com/mohesu/loading_icon_button/master/screenshots/gif2.gif" width=250 height=480 alt=""></td>
<td><img src="https://raw.githubusercontent.com/mohesu/loading_icon_button/master/screenshots/gif3.gif" width=250 height=480 alt=""></td>
</tr>
</table>

## Installation

   Add this to your pubspec.yaml:

    dependencies:
        loading_icon_button: ^0.0.5
## Usage
### Import
    import 'package:loading_icon_button/loading_icon_button.dart';

### Implementation of LoadingButton
```dart
 final LoadingButtonController _btnController = LoadingButtonController();

  void buttonPressed() async {
    Future.delayed(const Duration(seconds: 1), () {
      _btnController.success();
      Future.delayed(const Duration(seconds: 1), () {
        _btnController.reset();
      });
    });
  }

  LoadingButton(
    child: const Text('Login with Apple'),
    iconData: PhosphorIcons.appleLogo,
    onPressed: () => buttonPressed(),
    controller: _btnController,
  );
```
### Implementation of ArgonButton
```dart 
ArgonButton(
  height: 50,
  width: 350,
  borderRadius: 5.0,
  color: Color(0xFF7866FE),
  child: Text(
    "Continue",
    style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700
	),
  ),
  loader: Container(
    padding: EdgeInsets.all(10),
    child: SpinKitRotatingCircle(
      color: Colors.white,
      // size: loaderWidth ,
    ),
  ),
  onTap: (startLoading, stopLoading, btnState) {
  },
),


ArgonButton(
[...]
onTap:(startLoading, stopLoading, btnState){
  if(btnState == ButtonState.Idle){
    startLoading();
    await doNetworkRequest();
    stopLoading();
  }
 }
),
```

Properties of IconLoadingButton:

* `duration` - The duration of the button animation
* `loaderSize` - The size of the CircularProgressIndicator
* `animateOnTap` -  Whether to trigger the loading animation on the tap event
* `resetAfterDuration` - Reset the animation after specified duration, defaults to 15 seconds
* `errorColor` - The color of the button when it is in the error state
* `successColor` - The color of the button when it is in the success state
* `successIcon` - The icon for the success state
* `failedIcon` - The icon for the failed state
* `iconColor` - The icon color for the button
* `showBox` - The visibility of the box(Card)


## Contributions
All contributions are welcome! 
Contributions are what make the open source community such an amazing place to be learned, inspire, and create. Any contributions you make are greatly appreciated.

## Thanks to

RoundedLoadingButton  ```rounded_loading_button``` 
https://pub.dev/packages/rounded_loading_button

IconLoadingButton  ```icon_loading_button``` 
https://pub.dev/packages/icon_loading_button

ArgonButton ```argon_buttons_flutter```
https://pub.dev/packages/argon_buttons_flutter
