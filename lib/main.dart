import 'package:canopy/auth/auth.dart';
import 'package:canopy/pages/imagePreview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:canopy/pages/home.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(Canopy());
}



class Canopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Auth(),
      title: "Canopy",
      theme: ThemeData(
        primaryColor: Color(0xFF595fb6),
        accentColor: Colors.white
      ),
    );
  }
}



