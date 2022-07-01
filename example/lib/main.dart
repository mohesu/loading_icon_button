import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final LoadingButtonController _btnController1 = LoadingButtonController();
  final LoadingButtonController _btnController2 = LoadingButtonController();
  final LoadingButtonController _btnController3 = LoadingButtonController();

  final bool show = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      home: SafeArea(
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Text Button Only"),
                    Center(
                      child: LoadingButton(
                        showBox: show,
                        primaryColor: Colors.white,
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
                        //  iconData: PhosphorIcons.googleLogo,
                        onPressed: () {
                          Future.delayed(const Duration(seconds: 1), () {
                            _btnController1.success();
                            Future.delayed(const Duration(seconds: 2), () {
                              _btnController1.reset();
                            });
                          });
                        },
                        successIcon: PhosphorIcons.check,
                        controller: _btnController1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Icon Text Button"),
                    Center(
                      child: LoadingButton(
                        showBox: show,
                        child: const Text('Login with Apple'),
                        iconData: PhosphorIcons.appleLogo,
                        onPressed: () {
                          Future.delayed(const Duration(seconds: 1), () {
                            _btnController3.success();
                            Future.delayed(const Duration(seconds: 2), () {
                              _btnController3.reset();
                            });
                          });
                        },
                        successIcon: PhosphorIcons.check,
                        controller: _btnController3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Icon Button Only"),
                    Center(
                      child: LoadingButton(
                        showBox: show,
                        primaryColor: Colors.white,
                        iconColor: Colors.deepPurpleAccent,
                        valueColor: const Color(0xff0066ff),
                        errorColor: const Color(0xffe0333c),
                        successColor: const Color(0xff58B09C),
                        iconData: PhosphorIcons.magnifyingGlass,
                        onPressed: () {
                          Future.delayed(const Duration(seconds: 1), () {
                            _btnController2.error();
                            Future.delayed(const Duration(seconds: 2), () {
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
            ],
          ),
        ),
      ),
    );
  }
}
