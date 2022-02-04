import 'package:flutter/material.dart';
import 'package:icon_loading_button/icon_loading_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final IconButtonController _btnController1 = IconButtonController();
  final IconButtonController _btnController2 = IconButtonController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: SafeArea(
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(
                child: IconLoadingButton(
                  color: Colors.white,
                  iconColor: const Color(0xff0066ff),
                  valueColor: const Color(0xff0066ff),
                  errorColor: const Color(0xffe0333c),
                  successColor: const Color(0xff58B09C),
                  child: Text(
                    'Login with Google',
                    style: GoogleFonts.openSans().copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xff0066ff),
                    ),
                  ),
                  iconData: PhosphorIcons.googleLogo,
                  onPressed: () {
                    Future.delayed(const Duration(seconds: 1), () {
                      _btnController1.success();
                    });
                  },
                  successIcon: PhosphorIcons.check,
                  controller: _btnController1,
                ),
              ),
              Center(
                child: IconLoadingButton(
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
                    Future.delayed(const Duration(seconds: 1), () {
                      _btnController2.error();
                      Future.delayed(const Duration(seconds: 1), () {
                        _btnController2.reset();
                      });
                    });
                  },
                  successIcon: PhosphorIcons.check,
                  controller: _btnController2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
