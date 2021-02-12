import 'package:fchat_app/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async{
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
          home: FutureBuilder(
        // Initialize FlutterFire
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Center(child: Text('Error'));
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return Login();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(),),);
        },
      ),
    );
  }
}

