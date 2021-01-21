import 'package:canopy/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth extends StatefulWidget {
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  String token;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  String uid ;
  String userName;
  String email;
  String photoUrl;
  bool isAuth = false;
  User user;
  String playerId;

  _saveToken()async{
   QuerySnapshot _userToken = await FirebaseFirestore.instance
        .collection('tokens')
        .where('uid',isEqualTo: uid)
        .get();

    Map<String,dynamic>_data = {
      'token':playerId,
      'uid':uid
    };

    if(_userToken.docs.isNotEmpty){
      FirebaseFirestore.instance.collection('tokens').doc(_userToken.docs[0].id).set(
        _data,
        SetOptions(merge: true)
      );
    }else{
      FirebaseFirestore.instance.collection('tokens').add(_data);
    }
  }
  Future<void> _initOneSignal() async {
    OneSignal.shared.init('7e10d394-e980-4e0f-824f-8255cfe44a18');
    OneSignal.shared.setInFocusDisplayType(OSNotificationDisplayType.none);
    OSPermissionSubscriptionState status = await OneSignal.shared
        .getPermissionSubscriptionState();
    print(status.subscriptionStatus.userId);

    setState(() {
      playerId = status.subscriptionStatus.userId.toString();
    });

    OneSignal.shared.setNotificationReceivedHandler((OSNotification notification) {
      
    });


  }
  @override
  initState(){
    _initOneSignal();
    checkAuthStatus();
    super.initState();

  }
  checkAuthStatus() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    bool _isAuth = await pref.getBool('isAuth');
    String _uid = await pref.getString('uid');
    String _userName = await pref.getString('userName');
    String _email = await pref.getString('email');
    String _photoUrl = await pref.getString('photoUrl');


    if(_isAuth){
      setState((){
        isAuth = true;
        uid = _uid;
        userName = _userName;
        email = _email;
        photoUrl = _photoUrl;
      });
      print("already signed In");
      _saveToken();
    }
    else{
      pref.setBool('isAuth', false);
    }


  }
  Widget authScreen(){
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Welcome to canopy , An stackchat initiative"),
            RaisedButton(onPressed: googleAuth,child:Text("Signin with google"),)

          ],
        ),

      ),
    );
  }
  googleAuth()async{

    //authenticate with google
    //await Firebase.initializeApp();

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken
    );

    final UserCredential authResult = await auth.signInWithCredential(credential);

    final User user = authResult.user;

    if(user!=null){

      SharedPreferences pref = await SharedPreferences.getInstance();

      await pref.setString('uid', user.uid);
      await pref.setBool('isAuth',true);
      await pref.setString('userName', user.displayName);
      await pref.setString('email', user.email);
      await pref.setString('photoUrl', user.photoURL);

      setState(() {

        uid = user.uid;
        userName = user.displayName;
        email = user.email;
        photoUrl = user.photoURL;

      });
      _saveToken();
      CollectionReference userRef = await FirebaseFirestore.instance.collection('user');

      QuerySnapshot existinguser = await userRef
          .where('uid',isEqualTo: user.uid)
          .get();

      if(existinguser.docs.isEmpty){

        Map<String,dynamic> newUser = {
        'userName':user.displayName,
         'email':user.email,
         'photoUrl':user.photoURL,
        'uid': user.uid,
          'rooms':[],
          // 'token':
        };

        _saveToken();
        userRef.add(newUser);
        print('Added new user ');
      }
      setState(()=>isAuth = true);
      print(user);
    }

  }



  @override
  Widget build(BuildContext context) {
    return isAuth ? Home(uid: uid , user:user ,email: email, userName: userName, photoUrl: photoUrl,) : authScreen();
  }
}

