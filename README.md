## icon loading button

IconLoadingButton is a Flutter package heavily inspired by ```rounded_loading_button``` with design changes and inclusion of icons.

https://pub.dev/packages/rounded_loading_button

Light mode             |  Dark mode
:-------------------------:|:-------------------------:
![](screenshots/light-mode.gif)  |  ![](screenshots/dark-mode.gif)

## Installation

   Add this to your pubspec.yaml:

    dependencies:
        icon_loading_button: ^1.0.0
## Usage
### Import
    import 'package:rounded_loading_button/rounded_loading_button.dart';

### Simple Implementation

        final IconButtonController _btnController1 = IconButtonController();
        final IconButtonController _btnController2 = IconButtonController();

        void buttonPressed() async {
          Future.delayed(const Duration(seconds: 1), () {
                    _btnController2.error();
                    Future.delayed(const Duration(seconds: 1), () {
                      _btnController2.reset();
                    });
                  });
        }

        IconLoadingButton(
                  color: const Color(0xff0066ff),
                  iconColor: Colors.white,
                  valueColor: const Color(0xff0066ff),
                  errorColor: const Color(0xffe0333c),
                  successColor: const Color(0xff58B09C),
                  child: Text(
                    'Login with Google',
                    style: GoogleFonts.openSans().copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  iconData: PhosphorIcons.googleLogo,
                  onPressed: () {
                    buttonPressed();
                  },
                  successIcon: PhosphorIcons.check,
                  controller: _btnController2,
                ),


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


## Contributions
All contributions are welcome!
