import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/auth/auth.dart';
import 'package:canopy/widgets/joinedRoom.dart';
import 'package:canopy/widgets/myroom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hawk_fab_menu/hawk_fab_menu.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:canopy/models/user.dart';

class Home extends StatefulWidget {
  String uid, email, photoUrl, userName;
  User user;
  Home({this.uid, this.user, this.email, this.photoUrl, this.userName});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  Users currentUser;
  String token;
  signOut() async {
    await googleSignIn.signOut();
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool('isAuth', false);
    await pref.setString('uid', null);

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Auth()));
  }

  Future<Users> getUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String uid = await pref.getString('uid');
    CollectionReference userRef =
        await FirebaseFirestore.instance.collection('user');

    QuerySnapshot user = await userRef.where('uid', isEqualTo: uid).get();

    String userName = user.docs[0].get('userName');
    String Uid = user.docs[0].get('uid');
    String email = user.docs[0].get('email');
    String photoUrl = user.docs[0].get('photoUrl');
    List rooms = user.docs[0].get('rooms');
    Map<String, dynamic> json = {
      'userName': userName,
      'email': email,
      'uid': Uid,
      'photoUrl': photoUrl,
      'rooms': rooms
    };
    Users _currentUser = Users.fromJson(json);
    setState(() {
      currentUser = _currentUser;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getUser();
    super.initState();
  }
  TextEditingController _roomName = TextEditingController();
  TextEditingController _descripton = TextEditingController();
  TextEditingController _invitaionCode  = TextEditingController();


  joinRoom(BuildContext context) async{

    if(_invitaionCode.text.trim().length!=0){
      CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');
      QuerySnapshot room = await roomRef.where('roomId',isEqualTo: _invitaionCode.text).get();

      if(room.docs.isNotEmpty){
        List<dynamic> room_members =
        room.docs[0]['members'];
        if(!room_members.contains(widget.uid)){

          room_members.add(widget.uid);
          print(widget.userName);

          QuerySnapshot _token = await FirebaseFirestore.instance.collection('tokens').where('uid',isEqualTo: widget.uid).get();
          String token = _token.docs[0]['token'].toString();
          List allTokens = room.docs[0]['tokens'];
          if(!allTokens.contains(token))
            allTokens.add(token);

          FirebaseFirestore.instance.collection('rooms').doc(room.docs[0].id).set(
              {
                'members':room_members,'lastMessage':'@'+widget.userName+' Joined the room',
                'lastMessageFrom':'Canopy',
                'tokens': allTokens,
                'peopleUnread': room_members

              },
              SetOptions(merge : true));

          DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          CollectionReference _msgRef =  FirebaseFirestore.instance.collection('messages');
          QuerySnapshot thisDayMsg = await _msgRef.
          where('roomId',isEqualTo: room.docs[0]['roomId']).
          where('sendDate',isEqualTo: msgDate).get();

          bool firstMsg = false;

          if(thisDayMsg.docs.length == 0)
            firstMsg = true;
          else firstMsg = false;

          Map<String,dynamic> _msgData = {
            'msg':'@'+widget.userName+' Joined the room',
            'msgId': '0',
            'sendBy': 'canopy',
            'roomId': room.docs[0]['roomId'],
            'sendDate': msgDate,
            'sendTime': DateTime.now().millisecondsSinceEpoch,
            'readBy': [widget.uid],
            'hasImage': false,
            'images':[],
            'firstMsg':firstMsg,
            'dp':'',
            'senderName': 'canopy',
            'isReply': false,
            'replyTo':'',
            'replyMsg':''
          };

          FirebaseFirestore.instance.collection('messages').add(_msgData);
        }

      }

    }
  }
  createRoom(String roomName,String description,BuildContext context) async{
    print(widget.email);
    print(widget.userName);
    print(widget.photoUrl);
    print(widget.uid);
    if(roomName.length!=0 && description.length!=0){
    print('inside create room');
      String roomId = widget.email+'_'+roomName;
      roomId = roomId.trim();

      CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');

      String img='https://ui-avatars.com/api/?name='+roomName.toLowerCase();
    print(img);

    DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) ;
      int msgTimestamp = DateTime.now().millisecondsSinceEpoch;
      QuerySnapshot _token = await FirebaseFirestore.instance.collection('tokens').where('uid',isEqualTo: widget.uid).get();
      String token = _token.docs[0]['token'].toString();
      print('token::::'+token);

      Map<String,dynamic> room = {
        'roomId':roomId,
        'roomName':roomName,
        'description':description,
        'admin':widget.uid,
        'dp':img,
        'members':[widget.uid],
        'lastMessage':'You joined the room ',
        'lastMessageFrom':'Canopy',
        'lastMessageId':'',
        'peopleUnread':[widget.uid],
        'lastMessageTimestamp':msgTimestamp,
        'lastMessageDate':msgDate,
        'tokens':[token],
        'onlyAdminSends':false,
        'mediaShareAllowed':true,
        'secretChatAllowed': true,
        'hasMemberLimit': false

      };
      roomRef.add(room);
      _roomName.clear();
      _descripton.clear();
      Navigator.pop(context);
    }
  }
  joinRoomDialog(BuildContext context){
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height*0.2,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30))
            ),
            padding: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(left:23,bottom: 10),
                    child: Text('Join Room ',style: GoogleFonts.getFont('Roboto',fontWeight: FontWeight.w700)
                      ,)),
                TextFormField(
                  controller: _invitaionCode,
                  decoration: InputDecoration(
                      hintText: "Room's Invitaion Code",
                      border: InputBorder.none,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.home_outlined)
                  ),
                ),
                SizedBox(height: 20,),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(onPressed:()=> joinRoom(context),child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal:28.0),
                        child: Text('Join',
                            style: GoogleFonts.getFont('Roboto',color: Colors.white)

                        ),
                      ),
                        color: Theme.of(context).primaryColor,
                      ),
                      RaisedButton(
                        onPressed:() {
                        Navigator.pop(context);
                             }
                      ,child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal:28.0),
                        child: Text('Cancel',
                            style: GoogleFonts.getFont('Roboto',color: Colors.white)
                        ),
                        ),
                        color: Colors.red,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
      animationType: DialogTransitionType.size,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
    );
  }
  createRoomDialog(BuildContext context){

    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height*0.3,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(30))
            ),
            padding: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    margin: EdgeInsets.only(left:23,bottom: 10),
                    child: Text('Create New Room ',style: 
                      GoogleFonts.getFont('Roboto',fontWeight: FontWeight.w700)
                      ,)),
                TextFormField(
                  controller: _roomName,
                  decoration: InputDecoration(
                      hintText: "Room's Name",
                      border: InputBorder.none,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.home_outlined)
                  ),
                ),

                TextFormField(
                  controller: _descripton,
                  decoration: InputDecoration(
                      hintText: "Description",
                      border: InputBorder.none,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.description)
                  ),
                ),
                SizedBox(height: 20,),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(onPressed:()=> createRoom(_roomName.text,_descripton.text,context),child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal:28.0),
                        child: Text(
                            'Create',
                          style: GoogleFonts.getFont('Roboto',color: Colors.white),
                        ),
                      ),
                        color: Theme.of(context).primaryColor,

                      ),
                      RaisedButton(onPressed:() {
                        Navigator.pop(context);
                      },child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal:28.0),
                        child: Text('Cancel',
                          style: GoogleFonts.getFont('Roboto',color: Colors.white),
                        ),
                      ),
                        color: Colors.red,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
      animationType: DialogTransitionType.size,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,

      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Text(
                'Canopy',
                style: GoogleFonts.getFont('Rubik', fontSize: 16),
              ),
            ),
          ],
        ),
        elevation:0,
        actions: [ GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserProfile(
                        userName: widget.userName,
                        photoUrl: widget.photoUrl,
                        uid: widget.uid,
                        email: widget.email,
                      )));
            },
            child: Container(
              margin: EdgeInsets.only(right:25),
              child: Icon(Icons.account_circle),
            )),],
      ),
      body: HawkFabMenu(
        icon: AnimatedIcons.menu_close,
        fabColor: Theme.of(context).primaryColor,
        iconColor: Theme.of(context).accentColor,
        items: [
          HawkFabMenuItem(label: 'Create Room', ontap:()=>createRoomDialog(context), icon: Icon(Icons.add_box_outlined,color: Colors.white,)),
          HawkFabMenuItem(label: 'Join Room', ontap:()=>joinRoomDialog(context), icon: Icon(Icons.transit_enterexit_sharp,color: Colors.white))
        ],
        body: Container(
          child: Column(
            children: [
              Stack(
                children: [
                  MyRoom(
                    currentUser: currentUser,
                    uid: widget.uid,
                    email: widget.email,
                    userName: widget.userName,
                    photoUrl: widget.photoUrl,
                  ),
                ],
              ),
              Expanded(
                  child: JoinedRooms(
                uid: widget.uid,
                email: widget.email,
                userDp: widget.photoUrl,
                userName: widget.userName,
              ))
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfile extends StatefulWidget {
  String uid, email, photoUrl, userName;
  User user;
  UserProfile({this.uid, this.user, this.email, this.photoUrl, this.userName});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {

  // deleting user account logic //
  deleteEachRoomAdmin( room,List members,List tokens) async{
    FirebaseFirestore.instance.collection('rooms').doc(room.id).set({
      'admin':'0',
      'members': members,
      'tokens':tokens
    },SetOptions(merge:true));
  }
  signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool('isAuth', false);
    await pref.setString('uid', null);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Auth()));
  }
  deleteAccountDialog(BuildContext context){
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height*0.20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(30))
            ),
            padding: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'Are You Sure ? ',
                      style: GoogleFonts.getFont('Roboto',fontWeight: FontWeight.w800),
                    
                    ),
                  Text('Deleting you account means you would be no longer owning the rooms that you have created'),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RaisedButton(onPressed: _deleteAccount,child: Text('Yes',style: TextStyle(color: Colors.white),), color: Colors.green,),
                        RaisedButton(onPressed: (){
                          Navigator.pop(context);
                        },child: Text('No',style: TextStyle(color: Colors.white)),color: Colors.red,),
                      ],
                    )
                  ],
                ),
            ),

        ])));
      },
      animationType: DialogTransitionType.size,
      curve: Curves.fastOutSlowIn,
      duration: Duration(seconds: 1),
    );
  }
  _deleteAccount() async{
   QuerySnapshot _user = await FirebaseFirestore.instance.collection('user')
        .where('uid',isEqualTo: widget.uid).get();

   QuerySnapshot _room = await FirebaseFirestore.instance.collection('rooms')
       .where('admin',isEqualTo: widget.uid).get();

   for(var room in _room.docs){
    List members =  room['members'];
    List _updatedMembers =[];
    List token = room['tokens'];
    List _updatedTokens = [];

     members.forEach((element) {
     if(element!=widget.uid)
       _updatedMembers.add(element);
    });
     token.forEach((element) {
       if(element!=widget.uid)
         _updatedTokens.add(element);
     });
    deleteEachRoomAdmin(room,_updatedMembers, _updatedTokens);

   }

 await  FirebaseFirestore.instance.collection('user').doc(_user.docs[0].id).delete();
    Navigator.pop(context);
   signOut();
   print('deleted!');


  }
  //changing user image logic

  File file;
  bool isUploading = false;
  _showConfirmImageDialog(File file,BuildContext context){

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:(BuildContext context){
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState /*You can rename this!*/) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1/1,
                        child: Container(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            // height: 300,
                            margin: EdgeInsets.only(top:20,left:20,right:20),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                color: Color(0xFFedeef7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor,
                                    blurRadius: 25.0, // soften the shadow
                                    spreadRadius: 5.0, //extend the shadow
                                  )
                                ],
                                image: DecorationImage(
                                    image: isUploading ? CachedNetworkImageProvider('https://flevix.com/wp-content/uploads/2019/07/Line-Preloader.gif'):FileImage(file)
                                )
                            ),
                          ),
                        ),
                      ),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RaisedButton(
                              onPressed: isUploading ? null : (){
                                setState((){isUploading = true;});
                                changeDp(file,context);
                              },
                              color: Color(0xFF5b61b9),
                              child: Text(
                                "Save",
                                style: GoogleFonts.getFont('Roboto',color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left:8.0),
                              child: RaisedButton(
                                onPressed:isUploading ? null : (){Navigator.pop(context);},
                                color: Color(0xFFedeef7),
                                child: Text(
                                    "Cancel",
                                    style: GoogleFonts.getFont('Roboto',color: Colors.grey[700])
                                ),
                              ),
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                );
              });});


  }
   pickImage(BuildContext context)async{
    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.gallery );

    setState(() {
      file = File(_file.path);
    });
    if(file!=null)
      _showConfirmImageDialog(file, context);

  }
  changeDp(File file,BuildContext context) async{
    setState(() {
      isUploading = true;
    });

    String path = DateTime.now().millisecondsSinceEpoch.toString() +widget.uid;
    final _storage = FirebaseStorage.instance;
    var snapshot =  await _storage.ref().child(path).putFile(file);
    String _url = await snapshot.ref.getDownloadURL();
    saveUserDp(context, _url);

  }
  saveUserDp(BuildContext context,String url)async{
    QuerySnapshot _user = await FirebaseFirestore.instance.collection('user').where('uid',isEqualTo: widget.uid).get();
    FirebaseFirestore.instance.collection('user')
    .doc(_user.docs.first.id).set({
      'photoUrl': url
    },SetOptions(merge: true));
    setState(() {
      isUploading  = false;

    });
    setState(() {
      widget.photoUrl = url;
    });
    SharedPreferences pref = await SharedPreferences.getInstance();

    await pref.setString('photoUrl', url);
    Navigator.pop(context);
    QuerySnapshot _msg = await FirebaseFirestore.instance.collection('messages').where('sendBy',isEqualTo: widget.uid).get();
    _msg.docs.forEach((element) {
      FirebaseFirestore.instance.collection('messages').doc(element.id).set(
        {
          'dp':url
        },
        SetOptions(merge: true)
      );
    });


  }


    bool isEditing  = false;
    bool hasToSave = false;
    String newName;
    _saveName()async{
      if(newName.trim().length!=0){
       QuerySnapshot _user =  await FirebaseFirestore.instance.collection('user').where('uid',isEqualTo: widget.uid).get();
       FirebaseFirestore.instance.collection('user').doc(_user.docs.first.id).set(
           {
             "userName":newName
           },SetOptions(merge:true));
      }
      setState(() {
        isEditing = false;
        hasToSave = false;
      });

      SharedPreferences _pref =  await SharedPreferences.getInstance();
      await _pref.setString('userName', newName);


    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: ()=>pickImage(context),
                    child: StreamBuilder<Object>(
                      stream: FirebaseFirestore.instance.collection('user').where('uid',isEqualTo: widget.uid).snapshots(),
                      builder: (context,AsyncSnapshot snapshot) {
                        return Container(
                          margin: EdgeInsets.only(top: 20),
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.height * 0.1,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              image: DecorationImage(
                                fit: BoxFit.cover,
                                  image: CachedNetworkImageProvider(snapshot.data.docs[0]['photoUrl']))),
                        );
                      }
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  margin: EdgeInsets.only(left:20,top:10),
                  child: Text("User Information",
                  style: GoogleFonts.getFont('Roboto',
                  fontSize: 15,
                    color: Theme.of(context).primaryColor
                  ),
                  ),
                ),
                StreamBuilder<Object>(
                  stream: FirebaseFirestore.instance.collection('user').where('uid',isEqualTo: widget.uid).snapshots(),
                  builder: (context, AsyncSnapshot snapshot) {
                    return Container(
                      padding: EdgeInsets.only(top:10,left:20,right:20),
                        child: TextFormField(
                          readOnly: !isEditing,
                            initialValue: snapshot.data.docs[0]['userName'],
                            textAlign: TextAlign.start,
                            onChanged: (val){
                              setState(() {
                                hasToSave = true;
                                newName = val;
                              });
                            },
                            autofocus: isEditing,
                            decoration: InputDecoration(
                                fillColor: Colors.grey[100],
                                filled: true,

                                 prefixIcon: Icon(Icons.person_outline_rounded),
                                 suffixIcon: hasToSave ? GestureDetector(
                                     onTap: (){
                                       print('pressed');
                                       setState(() {
                                         isEditing =false;
                                         hasToSave = !hasToSave;
                                       });
                                       _saveName();
                                     },
                                     child: Icon(Icons.save)):GestureDetector(
                                     onTap: (){
                                       print('pressed');
                                       setState(() {
                                         isEditing = true;
                                         hasToSave = true;
                                       });
                                     },
                                     child: Icon(Icons.edit_outlined)),
                                 border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20.0)),
                                    borderSide: BorderSide.none,
                                ),

                            )));
                  }
                ),
                Container(
                  padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
                  margin: EdgeInsets.only(top:10,left:20,right: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.all(Radius.circular(20))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left:8.0),
                        child: Icon(Icons.email_outlined,color: Colors.grey,),
                      ),
                     
                      Expanded(

                        child: Container(
                          margin: EdgeInsets.only(left: 10),
                          child: Text(
                              widget.email,
                              style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left:20,top:10),
                  child: Text("Profile Settings",
                    style: GoogleFonts.getFont('Roboto',
                        fontSize: 15,
                        color: Theme.of(context).primaryColor
                    ),
                  ),
                ),

              ],
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.backup,color: Colors.grey,),
                  ),

                  Expanded(

                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'Backup chats',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor: Theme.of(context).primaryColor,
                    value: true,
                    onChanged: (val){print(val);},
                  ),

                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.local_airport,color: Colors.grey,),
                  ),

                  Expanded(

                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'Airplane mode',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor: Theme.of(context).primaryColor,
                    value: true,
                    onChanged: (val){print(val);},
                  ),

                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.assignment_ind,color: Colors.grey,),
                  ),

                  Expanded(

                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'Mention',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor: Theme.of(context).primaryColor,
                    value: true,
                    onChanged: (val){print(val);},
                  ),

                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left:20,top:10),
              child: Text("Appearance",
                style: GoogleFonts.getFont('Roboto',
                    fontSize: 15,
                    color: Theme.of(context).primaryColor
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.nightlight_round,color: Colors.grey,),
                  ),

                  Expanded(

                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Switch(
                    activeColor: Theme.of(context).primaryColor,
                    value: true,
                    onChanged: (val){print(val);},
                  ),

                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(left:20,top:10),
              child: Text("App Info",
                style: GoogleFonts.getFont('Roboto',
                    fontSize: 15,
                    color: Theme.of(context).primaryColor
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.android_outlined,color: Colors.grey,),
                  ),

                  Expanded(

                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'App version v1.0 @ release 2021',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),


                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(top:15,left:8,right: 8,bottom: 15),
              margin: EdgeInsets.only(top:10,left:20,right: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.all(Radius.circular(20))
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Icon(Icons.developer_mode,color: Colors.grey,),
                  ),

                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Text(
                        'Developed by Ishaan Dwivedi',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),


                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left:30.0,right: 30,top:10),
              child: RaisedButton(
                onPressed: (){},
                color: Colors.deepPurpleAccent,
              child: Text('Logout',style: TextStyle(color: Colors.white),),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left:30.0,right: 30,top:10),
              child: RaisedButton(
                onPressed: ()=>deleteAccountDialog(context),
                color: Colors.red,
                child: Text('Delete Account',style: TextStyle(color: Colors.white),),
              ),
            )
          ],
        )
    );
  }
}

