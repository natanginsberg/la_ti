import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SignIn extends StatefulWidget {
  SignIn();

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController userNameController = TextEditingController();

  bool hovering = false;
  bool addSessionToCurrentSong = false;

  var errorMessage = "";

  // ignore: non_constant_identifier_names
  final String FILL_IN_ALL_FIELDS = "You must fill in all of the fields";

  // ignore: non_constant_identifier_names
  final String PASSWORDS_DO_NOT_MATCH = "The passwords do not match";

  String uid = '';

  String userEmail = '';

  bool emailSent = false;

  late bool isVerified;

  Timer? timer;

  bool canResendEmail = false;

  bool newUser = false;

  bool forgotPasswordEmailSent = false;

  Timer? forgetTimer;

  String DISPLAY_NAME_TAKEN = "This display name is taken.";

  bool changeSignInHovering = false;

  _SignInState();

  TextEditingController passwordController = TextEditingController();

  TextEditingController displayNameController = TextEditingController();

  // Wakelock.toggle(enable: isPlaying);

  void backButton() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null &&
        !FirebaseAuth.instance.currentUser!.isAnonymous) {
      verifyEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: WillPopScope(
      onWillPop: () {
        return Future.value(true);
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Laci"),
            backgroundColor: Colors.black,
          ),
          body: Container(
            // height: MediaQuery.of(context).size.height,
            // width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
                gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [
                Colors.tealAccent,
                Colors.black,
              ],
            )),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 1.75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  width: MediaQuery.of(context).size.width / 4,
                  child: emailSent
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            emailSentMessage(),
                            const SizedBox(
                              height: 24,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(50),
                                      shadowColor: Colors.blue),
                                  onPressed: () =>
                                      canResendEmail ? verifyEmail() : null,
                                  icon: const Icon(
                                    Icons.mail,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Resend Email",
                                    style: TextStyle(fontSize: 24),
                                  )),
                            ),
                            TextButton(
                                style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50)),
                                onPressed: () async {
                                  timer!.cancel();
                                  await FirebaseAuth.instance.signOut();
                                  await FirebaseAuth.instance.signInAnonymously();
                                  canResendEmail = false;
                                  setState(() {
                                    emailSent = false;
                                  });
                                },
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(fontSize: 24),
                                ))
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            userNameBox(),
                            passwordBox(),
                            newUser ? displayName() : forgotPassword(),
                            if (errorMessage.isNotEmpty)
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            newUser ? createAccount() : signInToOldAccount()
                          ],
                        ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 6,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("La-Ci",
                        style: TextStyle(
                            fontSize: 45, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Allowing you to have a worldwide jam",
                    )
                  ],
                )
              ],
            ),
          )),
    ));
  }

  userNameBox() {
    var paddingSize = MediaQuery.of(context).size.width / 4 -
        MediaQuery.of(context).size.width / 5;
    return Column(children: [
      Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(paddingSize, 0, 0, 0),
            child: const Align(
                alignment: Alignment.topLeft, child: Text("Enter you email:")),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 5,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 4,
                  colors: [
                    Colors.black,
                    Colors.redAccent,
                  ],
                )),
            child: Stack(children: [
              Center(
                child: TextField(
                  onSubmitted: (String value) =>
                      newUser ? createNewAccount() : verifyAccount(),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.left,
                  controller: userNameController,
                  decoration: const InputDecoration(
                    hintText: "Email",
                    contentPadding: EdgeInsets.all(7),
                    hintStyle: TextStyle(color: Colors.grey),
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    userNameController.clear();
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    ]);
  }

  passwordBox() {
    var paddingSize = MediaQuery.of(context).size.width / 4 -
        MediaQuery.of(context).size.width / 5;
    return Column(children: [
      Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(paddingSize, 0, 0, 0),
            child: const Align(
                alignment: Alignment.topLeft,
                child: Text("Enter your password:")),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 5,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 4,
                  colors: [
                    Colors.black,
                    Colors.redAccent,
                  ],
                )),
            child: Stack(children: [
              Center(
                child: TextField(
                  onSubmitted: (String value) =>
                      newUser ? createNewAccount() : verifyAccount(),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.left,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(7),
                    hintText: "Password",
                    hintStyle: TextStyle(color: Colors.grey),
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    passwordController.clear();
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    ]);
  }

  displayName() {
    var paddingSize = MediaQuery.of(context).size.width / 4 -
        MediaQuery.of(context).size.width / 5;
    return Column(children: [
      Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(paddingSize, 0, 0, 0),
            child: const Align(
                alignment: Alignment.topLeft,
                child: Text("Please enter a display name")),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 5,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 2),
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 4,
                  colors: [
                    Colors.black,
                    Colors.redAccent,
                  ],
                )),
            child: Stack(children: [
              Center(
                child: TextField(
                  onSubmitted: (String value) =>
                      newUser ? createNewAccount() : verifyAccount(),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.left,
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(7),
                    hintText: "Display Name",
                    hintStyle: TextStyle(color: Colors.grey),
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    displayNameController.clear();
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    ]);
  }

  allFieldsFilled() {
    return passwordController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        (!newUser || displayNameController.text.isNotEmpty);
  }

  Future<User?> createNewUserWithEmailPassword(
      String email, String password) async {
    // Initialize Firebase
    User? user;
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      user = userCredential.user;

      await user!.updateDisplayName(displayNameController.text);

      // if (user != null) {
      //   uid = user.uid;
      //   userEmail = user.email!;
      // }

      await verifyEmail();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email is badly formatted.';
      } else {
        errorMessage = 'We are experiencing an error. Please try again';
      }
      setState(() {});
    }

    return user;
  }

  verifyEmail() async {
    isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    final user = FirebaseAuth.instance.currentUser!;
    if (isVerified) {
      Navigator.pop(context, user);
    } else {
      await user.sendEmailVerification();
      setState(() {
        emailSent = true;
        canResendEmail = false;
      });
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        canResendEmail = true;
      });

      addTimerToVerifyEmail(user);
    }
  }

  addTimerToVerifyEmail(User user) {
    timer = Timer.periodic(
        const Duration(seconds: 4), (_) => checkEmailVerified(user));
  }

  checkEmailVerified(User user) async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      isVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });
    if (isVerified) {
      if (timer != null) {
        timer!.cancel();
      }
      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({'email': user.email, 'uid': user.uid});
      Navigator.pop(context, user);
    }
  }

  void createNewAccount() async {
    setState(() {
      errorMessage = '';
    });
    if (allFieldsFilled()) {
      if (await displayNameNotTaken(displayNameController.text)) {
        createNewUserWithEmailPassword(
            userNameController.text, passwordController.text);
      } else {
        setState(() {
          errorMessage = DISPLAY_NAME_TAKEN;
        });
      }
    } else {
      setState(() {
        errorMessage = FILL_IN_ALL_FIELDS;
      });
    }
  }

  verifyAccount() {
    setState(() {
      errorMessage = '';
    });
    if (allFieldsFilled()) {
      registerWithExistingEmailPassword(
          userNameController.text, passwordController.text);
    } else {
      setState(() {
        errorMessage = FILL_IN_ALL_FIELDS;
      });
    }
  }

  createAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green)),
            onPressed: () {
              createNewAccount();
            },
            child: const Text(
              "Create Account",
              style: TextStyle(color: Colors.white),
            )),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (PointerEvent details) =>
                  setState(() => changeSignInHovering = true),
              onExit: (PointerEvent details) => setState(() {
                changeSignInHovering = false;
              }),
              child: RichText(
                  text: TextSpan(
                      text: "Already have an account? Click here",
                      style: TextStyle(
                        color: changeSignInHovering
                            ? Colors.deepOrange
                            : Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            errorMessage = "";
                            newUser = false;
                          });
                        })),
            ),
          ),
        ),
      ],
    );
  }

  signInToOldAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.green)),
            onPressed: () {
              verifyAccount();
            },
            child: const Text(
              "Sign In",
              style: TextStyle(color: Colors.white),
            )),
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (PointerEvent details) =>
                  setState(() => changeSignInHovering = true),
              onExit: (PointerEvent details) => setState(() {
                changeSignInHovering = false;
              }),
              child: RichText(
                  text: TextSpan(
                      text: "If you do not have an account click here",
                      style: TextStyle(
                        color: changeSignInHovering
                            ? Colors.deepOrange
                            : Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          setState(() {
                            errorMessage = "";
                            newUser = true;
                          });
                        })),
            ),
          ),
        ),
      ],
    );
  }

  Future<User?> registerWithExistingEmailPassword(
      String email, String password) async {
    User? user;
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      user = userCredential.user;

      if (user != null) {
        uid = user.uid;
        userEmail = user.email!;
      }

      await verifyEmail();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          errorMessage = "No user found for that email.";
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = 'Wrong password provided for that user.';
        });
      }
    }

    return user;
  }

  forgotPassword() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 0, 0, 0),
          child: Align(
            alignment: Alignment.topLeft,
            child: TextButton(
                onPressed: () async {
                  if (forgotPasswordEmailSent) {
                    return;
                  }
                  setState(() {
                    errorMessage = "";
                  });
                  try {
                    if (userNameController.text.isNotEmpty) {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: userNameController.text);
                      setState(() {
                        forgotPasswordEmailSent = true;
                      });
                      forgetTimer =
                          Timer.periodic(const Duration(seconds: 5), (_) {
                        forgetTimer!.cancel();
                        setState(() {
                          forgotPasswordEmailSent = false;
                        });
                      });
                    } else {
                      setState(() {
                        errorMessage = "You must enter an email address first";
                      });
                    }
                  } on FirebaseAuthException catch (e) {
                    setState(() {
                      errorMessage = e.toString();
                    });
                  }
                },
                child: const Text(
                  "Forgot your password?",
                  style: TextStyle(
                      color: Colors.brown,
                      decoration: TextDecoration.underline),
                )),
          ),
        ),
        if (forgotPasswordEmailSent) const Text("Email sent")
      ],
    );
  }

  emailSentMessage() {
    String currentEmail = FirebaseAuth.instance.currentUser!.email!;
    return Center(
        child: Text(
      "An email was sent to $currentEmail for verification",
      textAlign: TextAlign.center,
    ));
  }

  Future<bool> displayNameNotTaken(String displayName) async {
    final result = await FirebaseFirestore.instance
        .collection("users")
        .where("displayName", isEqualTo: displayName)
        .get();
    return result.size == 0;
  }
}
