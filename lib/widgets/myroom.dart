import 'dart:convert';
import 'dart:io';
import 'package:canopy/models/room.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emojis/emojis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class MyRoom extends StatefulWidget {
  Users currentUser;
  String uid,email,userName,photoUrl;

  MyRoom({this.currentUser,this.uid,this.email,this.userName,this.photoUrl});
  @override
  _MyRoomState createState() => _MyRoomState(currentUser: currentUser);
}

class _MyRoomState extends State<MyRoom> {

  Users currentUser;
  _MyRoomState({this.currentUser});



@override
  Widget build(BuildContext context) {
    MediaQueryData queryData;
    queryData = MediaQuery.of(context);
    double width = queryData.size.width;
    double height = queryData.size.height;
    return Column(
      children: [
      Container(
        padding: EdgeInsets.only(left:15,right:10),
      height: height*.08,
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor
      ),
      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(
          'My Rooms',
          style:GoogleFonts.getFont('Fredoka One',fontSize: 14,color: Colors.white,)

        ),
        ],),
      ),
        Container(
          height: height*.18,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor
          ),
          child:
              StreamBuilder (
                stream: FirebaseFirestore.instance.collection('rooms').where('admin',isEqualTo: widget.uid).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if(snapshot.data == null || snapshot == null)
                    return Text('');
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data.docs.length,
                      itemBuilder: (context,index){
                        if(snapshot.data.docs[index]['admin']==widget.uid) {

                          int lastMsgTimestamp = snapshot.data.docs[index]['lastMessageTimestamp'];
                          String dp = snapshot.data.docs[index]['dp'];
                          String roomName = snapshot.data.docs[index]['roomName'];
                          String lastMsg = snapshot.data.docs[index]['lastMessage'];
                          String description = snapshot.data.docs[index]['description'];
                          String lastMsgFrom = snapshot.data.docs[index]['lastMessageFrom'];
                          String lastMsgId = snapshot.data.docs[index]['lastMessageId'];
                          List members = snapshot.data.docs[index]['members'];
                          String admin = snapshot.data.docs[index]['admin'];
                          String roomId = snapshot.data.docs[index]['roomId'];
                          List peopleUnread = snapshot.data.docs[index]['peopleUnread'];
                          bool hasUnread = peopleUnread.contains(widget.uid) ;
                          bool onlyAdminSends = snapshot.data.docs[index]['onlyAdminSends'];
                          bool mediaShareAllowed = snapshot.data.docs[index]['hasMemberLimit'];
                          bool hasMemberLimit = snapshot.data.docs[index]['onlyAdminSends'];
                          bool secretChatAllowed = snapshot.data.docs[index]['secretChatAllowed'];

                          List tokens = snapshot.data.docs[index]['tokens'];
                          Map<String,dynamic> _thisRoom = {
                            'dp': dp,
                            'roomName':roomName,
                            'lastMessage':lastMsg,
                            'lastMessageFrom':lastMsgFrom,
                            'admin':admin,
                            'members':members,
                            'roomId':roomId,
                            'tokens':tokens,
                            'lastMessageTimestamp': lastMsgTimestamp,
                            'onlyAdminSends':onlyAdminSends,
                            'mediaShareAllowed':mediaShareAllowed,
                            'secretChatAllowed': secretChatAllowed,
                            'hasMemberLimit': hasMemberLimit,
                            'description':description
                          };

                          Room _room = Room.fromJson(_thisRoom);

                          return RoomWidget(
                            mainContext: context, dp: snapshot.data
                              .docs[index]['dp'], roomName: snapshot.data
                              .docs[index]['roomName'],
                            room:_room
                          );
                        }
                        else return Text('');
                      },
                    ),
                  );
                }
              )

        ),
      ],
    );
  }
}

class RoomWidget extends StatefulWidget {

  String dp;
  String roomName;
  BuildContext mainContext;
  Room room;

  RoomWidget({this.dp,this.roomName,this.mainContext,this.room});

  @override
  _RoomWidgetState createState() => _RoomWidgetState();
}

class _RoomWidgetState extends State<RoomWidget> {

  bool isUploading = false;
  _viewRoomOverview(BuildContext context,Room room){
    return  showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:(BuildContext context){
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30),topRight:Radius.circular(30) )
            ),
            child: Container(
              padding: EdgeInsets.all(15),
              child: ListView(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: ()=>pickImage(room,context),
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape:BoxShape.circle,

                                  image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: CachedNetworkImageProvider(room.dp)
                                  )
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left:0,top:8),
                            child: Text(
                              room.roomName,
                              style: GoogleFonts.getFont('Concert One',fontSize: 18),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left:0,top:8),
                            child: Text(
                              '(Secured by canopy)',
                              style: GoogleFonts.getFont('Roboto',fontSize: 14),
                            ),
                          ),



                        ],
                      ),
                      Container(
                        padding: EdgeInsets.only(left:0,top:8),
                        child: Text(
                          'Room settings',
                          style: GoogleFonts.getFont('Roboto',fontSize: 14),
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.only(top:12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(
                                  'Admin',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.account_circle),
                                subtitle: Text(
                                  'Ishaan Dwivedi',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(

                                title: Text(
                                  'Room Invitaion Id',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.house_siding_rounded),
                                subtitle: Text(
                                  room.roomId,
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(

                                title: Text(
                                  'Members Count',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.people),
                                subtitle: Text(
                                  room.members.length.toString(),
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(

                                title: Text(
                                  'Text Message Settings',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.text_fields),
                                subtitle: room.onlyAdminSends ? Text(
                                  "Only admin can send message",
                                  style: GoogleFonts.getFont('Roboto'),
                                ):Text(
                                  "Allowed for all",
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(
                                  'Media share settings',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.image),
                                subtitle: room.mediaShareAllowed ? Text(
                                  "Media share allowed",
                                  style: GoogleFonts.getFont('Roboto'),
                                ):Text(
                                  "Media share not allowed",
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(
                                  'Secret Chats',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.chat),
                                subtitle: room.secretChatAllowed ? Text(
                                  "Members can chat secretly",
                                  style: GoogleFonts.getFont('Roboto'),
                                ):Text(
                                  "Members can't chat secretly",
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(
                                  'Member limited to 100',
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                leading: Icon(Icons.event_seat_outlined),
                                subtitle: room.hasMemberLimit ? Text(
                                  "Enabled",
                                  style: GoogleFonts.getFont('Roboto'),
                                ):Text(
                                  "Disabled",
                                  style: GoogleFonts.getFont('Roboto'),
                                ),
                                tileColor: Color(0xFFedeef7),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RaisedButton(
                                onPressed: (){},
                                color: Colors.redAccent,
                                child: Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cleaning_services,color: Colors.white,),
                                      Text(
                                        'Delete all chats',
                                        style: GoogleFonts.getFont( 'Roboto', color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: RaisedButton(
                                onPressed: (){},
                                color: Colors.pinkAccent,
                                child: Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.delete,color: Colors.white,),
                                      Text(
                                        'Delete Room',
                                        style: GoogleFonts.getFont( 'Roboto', color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: RaisedButton(
                                onPressed: (){},
                                color: Colors.green,
                                child: Container(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.call_missed_outgoing_outlined,color: Colors.white,),
                                      Text(
                                        'Visit room',
                                        style: GoogleFonts.getFont( 'Roboto', color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      )

                    ],
                  ),
                ],
              ),
            ),
          );
        }

    );
  }
  changeDp(Room room,File file,BuildContext context) async{
    setState(() {
      isUploading = true;
    });

    String path = DateTime.now().millisecondsSinceEpoch.toString() + room.roomId;
    final _storage = FirebaseStorage.instance;
    var snapshot =  await _storage.ref().child(path).putFile(file);
    String _url = await snapshot.ref.getDownloadURL();
    QuerySnapshot _snapshot = await FirebaseFirestore.instance.collection('rooms').where('roomId',isEqualTo: room.roomId).get();
    FirebaseFirestore.instance.collection('rooms')
        .doc(_snapshot.docs[0].id)
        .set({'dp':_url},SetOptions(merge: true));
    cancel(context);
    setState(() {
      isUploading  = false;

    });
    Navigator.pop(context);

  }
  cancel(context){
    Navigator.pop(context);
  }
  pickImage(Room room ,BuildContext context)async{
    // Navigator.pop(context);
    File file;
    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.gallery );

    file = File(_file.path);
    _showConfirmImageDialog(file,context,room);
  }
  _showConfirmImageDialog(File file,BuildContext context,room){

    print(file.path);
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
                              changeDp(room,file,context);
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
                              onPressed:isUploading ? null :  ()=>cancel(context),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          GestureDetector(
            onTap: ()=>_viewRoomOverview(widget.mainContext,widget.room),
            child:Container(
              height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            boxShadow: [
            BoxShadow(
            color: Colors.grey[800],
            blurRadius: 5.0,
            ),],
            image: DecorationImage(
            fit: BoxFit.cover,
            image: CachedNetworkImageProvider(widget.dp)
            )
            ),
            )

          ),
          SizedBox(height: 8,),
          Text(widget.roomName,style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500
          ),)
        ],
      ),
    );
  }
}

