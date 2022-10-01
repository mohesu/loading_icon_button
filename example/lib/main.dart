import 'package:flutter/material.dart';
import 'package:loading_icon_button/loading_icon_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final LoadingButtonController _btnController1 = LoadingButtonController();

  final LoadingButtonController _btnController2 = LoadingButtonController();

  final LoadingButtonController _btnController3 = LoadingButtonController();

  late AnimationController animationController;

  final bool show = true;

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    super.initState();
  }

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
          body: ListView(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                height: 240, //define in multiple of 8
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Text  Only"),
                    Center(
                      child: LoadingButton(
                        showBox: show,
                        child: Text(
                          'Login with Google', // add other options
                          style: GoogleFonts.openSans().copyWith(
                            fontWeight: FontWeight.w500,
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
                height: 240,
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
                    const Text("Icon Button"),
                    Center(
                      child: LoadingButton(
                        showBox: show,
                        child: const Text('Login with Ios'),
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
                margin: const EdgeInsets.all(8),
                height: 240,
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
                    const Text("Argon Button"),
                    Center(
                      child: ArgonButton(
                        height: 50,
                        roundLoadingShape: true,
                        width: 200,
                        onTap: (startLoading, stopLoading, btnState) {
                          startLoading();
                          Future.delayed(const Duration(seconds: 3), () {
                            stopLoading();
                          });
                        },
                        loader: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        child: const Text(
                          "SignUp",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        borderRadius: 5.0,
                        color: const Color(0xFFfb4747),
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
                    const Text("Argon Timer Button"),
                    Center(
                      child: ArgonTimerButton(
                        initialTimer: 10, // Optional
                        height: 50,
                        width: 200,
                        minWidth: 130,
                        color: const Color(0xFF7866FE),
                        borderRadius: 5.0,
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        loader: (timeLeft) {
                          return Text(
                            "Wait | $timeLeft",
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700),
                          );
                        },
                        onTap: (startTimer, btnState) {
                          if (btnState == ArgonButtonState.idle) {
                            startTimer(3);
                          }
                        },
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
                    const Text("Argon Timer Button"),
                    Center(
                      child: ArgonButton(
                        height: 50,
                        roundLoadingShape: false,
                        width: 200,
                        minWidth: 130,
                        onTap: (startLoading, stopLoading, btnState) {
                          startLoading();
                          Future.delayed(const Duration(seconds: 3), () {
                            stopLoading();
                          });
                        },
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        loader: const Text(
                          "Loading...",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        borderRadius: 5.0,
                        color: Colors.cyan,
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
