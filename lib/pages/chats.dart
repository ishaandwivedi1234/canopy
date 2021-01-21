import 'dart:convert';
import 'dart:io';
import 'package:emojis/emojis.dart'; // to use Emoji collection
import 'package:emojis/emoji.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http ;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/models/message.dart';
import 'package:canopy/models/room.dart';
import 'package:canopy/widgets/messageBox.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:uuid/uuid.dart';

class Chats extends StatefulWidget {
  Room room;
  String userName;
  String uid;
  String email;
  String dp;
  String userDp;

  Chats({
    this.room,
    this.dp,
    this.uid,
    this.email,
    this.userName,
    this.userDp
});


  @override
  _ChatsState createState() => _ChatsState(
    room:room
  );
}

class _ChatsState extends State<Chats> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new  GlobalKey<ScaffoldState>();

  Room room;
  String _userDp ;
 _ChatsState({this.room});

  TextEditingController _msgController = TextEditingController();
  TextEditingController _captionController = TextEditingController();

  PickedFile _pickedFile ;



  markAllAsRead() async{
    QuerySnapshot _room =  await FirebaseFirestore.instance.collection('rooms').where('roomId',isEqualTo: room.roomId).get();
    List peopleUnread = _room.docs[0]['peopleUnread'];
    List peopleUnreadUpdated = [];

    peopleUnread.removeWhere((element) => element==widget.uid);

    print('Before list is');
    print(peopleUnread);

    print('updated list is');
    print(peopleUnreadUpdated);

    FirebaseFirestore.instance.collection('rooms').doc(_room.docs[0].id).set(
        {'peopleUnread':peopleUnread},
        SetOptions(merge : true));
  }
  File file ;
  bool isUploadingImage = false;

  _showModalSheet(BuildContext context){
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
                        aspectRatio: 16/9,
                        child: Container(
                          color: Colors.transparent,
                          child: !isUploadingImage ? Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 200,
                            margin: EdgeInsets.only(top:20,left:20,right:20),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(topRight:Radius.circular(20),topLeft:Radius.circular(20)),
                                color: Color(0xFFedeef7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor,
                                    blurRadius: 25.0, // soften the shadow
                                    spreadRadius: 5.0, //extend the shadow
                                    // offset: Offset(
                                    //   15.0, // Move to right 10  horizontally
                                    //   20.0, // Move to bottom 10 Vertically
                                    // ),
                                  )
                                ],
                                image: DecorationImage(
                                    image: FileImage(file)
                                )
                            ),
                          ):
                          Container(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 200,
                            margin: EdgeInsets.only(top:20,left:20,right:20),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(topRight:Radius.circular(20),topLeft:Radius.circular(20)),
                                color: Color(0xFFedeef7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor,
                                    blurRadius: 25.0, // soften the shadow
                                    spreadRadius: 5.0, //extend the shadow
                                    // offset: Offset(
                                    //   15.0, // Move to right 10  horizontally
                                    //   20.0, // Move to bottom 10 Vertically
                                    // ),
                                  )
                                ],
                                image: DecorationImage(
                                    image:CachedNetworkImageProvider('https://cdn.dribbble.com/users/1299339/screenshots/10879984/media/91b1d397bbcfc663d6cfec01798f4d5d.gif')
                                )
                            ),
                          )
                          ,
                        ),
                      ),
                      Container(
                          margin: EdgeInsets.only(bottom:20,left:20,right:20),
                          child: TextFormField(
                            controller: _captionController,
                            autofocus: true,
                            decoration: InputDecoration(
                                filled: true,
                                fillColor: Color(0xFFebe9f2),
                                hintText: 'Image Caption ..',
                                suffixIcon: GestureDetector(
                                    onTap: isUploadingImage ? null : (){
                                      setState(() {
                                        isUploadingImage = true;
                                      });
                                      postImageMessage();
                                    },
                                    child: Icon(Icons.double_arrow_outlined)),
                                border:new OutlineInputBorder(
                                  borderSide: BorderSide(
                                    width: 0,
                                    style: BorderStyle.none,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20.0),
                                      bottomRight: Radius.circular(20)
                                  ),
                                ),
                                contentPadding: EdgeInsets.only(
                                    top: 5,
                                    bottom: 5,
                                    left: 10,
                                    right: 10
                                )
                            ),
                          )
                      )

                    ],
                  ),
                );
              });
        }

    );
  }
  pickImage(BuildContext context)async{
    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.gallery );

    setState(() {
      file = File(_file.path);
    });
    if(file!=null)
      _showModalSheet(context);
  }
  pickCamera(BuildContext context)async{

    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.camera);

    setState(() {
      file = File(_file.path);
    });
    if(file!=null)
      _showModalSheet(context);

  }

  @override
  initState(){
    print('chat room dp'+widget.userDp);
    markAllAsRead();
    setState(() {
      _userDp = widget.userDp;
    });

    super.initState();


  }
  postImageMessage()async{

    if(file!=null ){

      setState(() {
        isUploadingImage = true;
      });

      var uuid = Uuid();
      String msgId = uuid.v1();

      String path = DateTime.now().millisecondsSinceEpoch.toString() + widget.uid;

      final _storage = FirebaseStorage.instance;
      var snapshot =  await _storage.ref().child(path).putFile(file);
      String _url = await snapshot.ref.getDownloadURL();


      if(_captionController.text.trim().length == 0)
        _captionController.text = "";
      
      DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) ;
      int msgTimestamp = DateTime.now().millisecondsSinceEpoch;
      CollectionReference _msgRef =  FirebaseFirestore.instance.collection('messages');
      QuerySnapshot thisDayMsg = await _msgRef.
      where('roomId',isEqualTo: room.roomId).
      where('sendDate',isEqualTo: msgDate).get();

      bool firstMsg = false;

      if(thisDayMsg.docs.length == 0)
        firstMsg = true;
      else firstMsg = false;

      // Future
      Map<String,dynamic> _msgData = {
        'msg':_captionController.text,
        'msgId': msgId,
        'sendBy': widget.uid,
        'roomId': room.roomId,
        'sendDate': msgDate,
        'sendTime': DateTime.now().millisecondsSinceEpoch,
        'readBy': [widget.uid],
        'hasImage': true,
        'images':[_url],
        'firstMsg':firstMsg,
        'dp':widget.userDp,
        'senderName': widget.userName,
        'isReply': false,
        'replyTo':'',
        'replyMsg':''
      };

      _msgRef.add(_msgData);

      CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');
      QuerySnapshot rooms = await roomRef.where('roomId',isEqualTo: room.roomId).get();

      print(msgId);
      List _peopleUnred = room.members;

      FirebaseFirestore.instance.collection('rooms').doc(rooms.docs[0].id).set(
          {
            'lastMessage':_msgController.text,
            'lastMessageFrom':widget.userName,
            'lastMessageId':msgId,
            'lastMessageDate':msgDate,
            'lastMessageTimestamp':msgTimestamp,
            'peopleUnread': _peopleUnred
          },
          SetOptions(merge : true));
     String _msg =  _captionController.text;
     _captionController.clear();
      setState(() {
        isUploadingImage = false;
      });
      Navigator.pop(context);


      String heading = Emojis.highVoltage+' '+room.roomName+' '+Emojis.highVoltage;
      _msg = Emojis.person +' '+widget.userName+' '+Emojis.camera+' '+ _msg;
      var json = {
        "app_id":"7e10d394-e980-4e0f-824f-8255cfe44a18",
        "headings":{"en":heading},
        "contents":{"en":_msg},
        "include_player_ids":room.tokens
      };
      var _data = jsonEncode(json);
      var _headers ={
        "Content-Type":"application/json",
        "Authorization": "Basic KEY Njg0MjA3ODgtMzI1OC00ZGFkLWFjODYtOWVkYjg0Y2Q3MGM1"
      };
      http.Response response = await http.post('https://onesignal.com/api/v1/notifications',body: _data,headers: _headers);
      print(response.body);
    }
  }
  postMessage() async{
    if(_msgController.text.length!=0 ){
      var uuid = Uuid();
      String msgId = uuid.v1();
      if(_msgController.text.trim().length == 0)
        _msgController.text = "";

      DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) ;
      int msgTimestamp = DateTime.now().millisecondsSinceEpoch;
      CollectionReference _msgRef =  FirebaseFirestore.instance.collection('messages');
      QuerySnapshot thisDayMsg = await _msgRef.
      where('roomId',isEqualTo: room.roomId).
      where('sendDate',isEqualTo: msgDate).get();

      QuerySnapshot _users = await FirebaseFirestore.instance.collection('user').where('uid',isEqualTo: widget.uid).get();


      bool firstMsg = false;

      if(thisDayMsg.docs.length == 0)
        firstMsg = true;
      else firstMsg = false;

      // Future
      Map<String,dynamic> _msgData = {
        'msg':_msgController.text,
        'msgId': msgId,
        'sendBy': widget.uid,
        'roomId': room.roomId,
        'sendDate': msgDate,
        'sendTime': DateTime.now().millisecondsSinceEpoch,
        'readBy': [widget.uid],
        'hasImage': false,
        'images':[],
        'firstMsg':firstMsg,
        'dp':_users.docs[0]['photoUrl'],
        'senderName': _users.docs[0]['userName'],
        'isReply': false,
        'replyTo':'',
        'replyMsg':''
      };

      _msgRef.add(_msgData);

      CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');
      QuerySnapshot rooms = await roomRef.where('roomId',isEqualTo: room.roomId).get();

      print(msgId);
      List _peopleUnred = room.members;



      FirebaseFirestore.instance.collection('rooms').doc(rooms.docs[0].id).set(
          {
            'lastMessage':_msgController.text,
            'lastMessageFrom':widget.userName,
            'lastMessageId':msgId,
            'lastMessageDate':msgDate,
            'lastMessageTimestamp':msgTimestamp,
            'peopleUnread': _peopleUnred
          },
          SetOptions(merge : true));
      String _msg = _msgController.text;
      _msgController.clear();
      String heading = Emojis.highVoltage+' '+room.roomName+' '+Emojis.highVoltage;
      _msg = Emojis.person +' '+widget.userName+' '+Emojis.wavyDash+' '+ _msg;
      var json = {
        "app_id":"7e10d394-e980-4e0f-824f-8255cfe44a18",
        "headings":{"en":heading},
        "contents":{"en":_msg},
        "include_player_ids":room.tokens
      };
      var _data = jsonEncode(json);
      var _headers ={
        "Content-Type":"application/json",
        "Authorization": "Basic KEY Njg0MjA3ODgtMzI1OC00ZGFkLWFjODYtOWVkYjg0Y2Q3MGM1"
      };
      http.Response response = await http.post('https://onesignal.com/api/v1/notifications',body: _data,headers: _headers);
      print(response.body);
    }
  }
  StreamBuilder showChats(BuildContext context){

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('messages').where('roomId',isEqualTo: room.roomId).orderBy('sendTime',descending: true).snapshots(),
      builder: (context,AsyncSnapshot snapshot){

        if(snapshot.data == null || snapshot == null){
          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
            ),
            child: Center(
              child: Text('Loading...'),
            ),
          );
        }
        if(snapshot.data.docs.length == 0){
          return Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CachedNetworkImage(imageUrl:'https://www.pharmalookup.com/images/noresult.gif' ,
                  height: MediaQuery.of(context).size.height*0.3,
                    width: MediaQuery.of(context).size.width*0.6,

                  ),
                  Text('No chats yet !')
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          // shrinkWrap: true,
          reverse: true,
          physics: BouncingScrollPhysics(),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context,index){

            Map<String,dynamic> data = {
              'msg': snapshot.data.docs[index]['msg'],
              'sendBy':snapshot.data.docs[index]['sendBy'],
              'roomId': snapshot.data.docs[index]['roomId'],
              'sendDate': snapshot.data.docs[index]['sendDate'],
              'sendTime': snapshot.data.docs[index]['sendTime'],
              'readBy': snapshot.data.docs[index]['readBy'],
              'hasImage': snapshot.data.docs[index]['hasImage'],
              'images':snapshot.data.docs[index]['images'],
              'dp':snapshot.data.docs[index]['dp'],
              'firstMsg':snapshot.data.docs[index]['firstMsg'],
              'senderName': snapshot.data.docs[index]['senderName'],
              'uid':widget.uid,
              'msgId':snapshot.data.docs[index]['msgId'],
              'isReply':snapshot.data.docs[index]['isReply'],
              'replyMsg':snapshot.data.docs[index]['replyMsg'],
              'replyTo':snapshot.data.docs[index]['replyTo'],
              'userDp':widget.userDp,

            };
            Message _newMsg = Message.fromJson(data);
            bool isInContinuation = false;
            if(index<snapshot.data.docs.length-1){
              if(snapshot.data.docs[index]['sendBy'] == snapshot.data.docs[index+1]['sendBy'])
                isInContinuation = true;
            }
            if(index == 0){
              return Column(
                children: [
                MessageBox(
                  msg: _newMsg,
                  room:room,
                  uid:widget.uid,
                  userName:widget.userName,
                  email:widget.email,
                  dp:widget.dp,
                  userDp:widget.userDp,
                  isInContinuation:isInContinuation


              ),
                  Container(height: 80, color: Colors.white,)
                ],
              );
            }
            return MessageBox(
                msg: _newMsg,
                room:room,
                uid:widget.uid,
                userName:widget.userName,
                email:widget.email,
                dp:widget.dp,
                userDp:widget.userDp,
                isInContinuation:isInContinuation
            );
          },
        );
      },
    );
  }
  _buildMsgBox(){
    String _hintText = 'Say something ...';
    bool canEdit =true;
    if(widget.uid !=widget.room.admin && widget.room.onlyAdminSends)
      canEdit =false;
    if(!canEdit){
      _hintText ='Only admin can send messages..';

    }

    return DraggableScrollableSheet(
      initialChildSize: 0.08,
      minChildSize: 0.0,
      maxChildSize: 1,
      builder: (BuildContext context, myscrollController) {
        return Container(
          // padding: EdgeInsets.symmetric(horizontal: 15),
          margin: EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20))
          ),
          child:TextFormField(
              
            minLines: 1,
            // textAlignVertical: TextAlignVertical.center,
            controller: _msgController,
            readOnly: (widget.room.onlyAdminSends && widget.room.admin!=widget.uid )? true : false,
            decoration: InputDecoration(
              filled: true,
              fillColor:Colors.grey[200],
              hintText: _hintText,
              prefixIcon: Container(
                width: MediaQuery.of(context).size.width *0.15,
                // color: Colors.red,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                        onTap: canEdit ?  ()=>pickCamera(context) : null,
                        child: Icon(Icons.camera)
                    ),

                    GestureDetector(
                        onTap: canEdit ? ()=>pickImage(context) : null,
                        child: Icon(Icons.image))
                  ],
                ),
              ),
              suffixIcon: GestureDetector(
                  onTap: canEdit ? postMessage : null,
                  child: Icon(Icons.double_arrow_outlined)),
              border:new OutlineInputBorder(
                borderSide: BorderSide(
                  width: 0,
                  style: BorderStyle.none,
                ),
            borderRadius: const BorderRadius.all(
                const Radius.circular(10.0),
           ),
          ),
              contentPadding: EdgeInsets.only(
                top: 5,
                bottom: 5,
                left: 10,
                right: 10
              )
            ),
          )
        );
      },
    );
  }
  _buildSeeDetails(context){
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:(BuildContext context){
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState /*You can rename this!*/) {
                String _description = widget.room.description;

                _changeRoomRules(String setting) async{
                  DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                  CollectionReference _msgRef =  FirebaseFirestore.instance.collection('messages');
                  QuerySnapshot thisDayMsg = await _msgRef.
                  where('roomId',isEqualTo: room.roomId).
                  where('sendDate',isEqualTo: msgDate).get();

                  bool firstMsg = false;

                  if(thisDayMsg.docs.length == 0)
                    firstMsg = true;
                  else firstMsg = false;

                  Map<String,dynamic> _msgData = {
                    'msg':setting,
                    'msgId': '1', // msg id 1 for admin can send msg or not send message
                    'sendBy': 'canopy',
                    'roomId': widget.room.roomId,
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
                _changeRoomStatus(int statusNo) async{

                  QuerySnapshot _snapshot = await  FirebaseFirestore.instance.collection('rooms')
                      .where('roomId', isEqualTo: widget.room.roomId)
                      .get();

                  if(statusNo == 1){
                    setState((){
                      widget.room.onlyAdminSends = !widget.room.onlyAdminSends;
                    });
                    String rule  = widget.room.onlyAdminSends ? "Only admin can send messages" : "Anyone can send messages";

                    FirebaseFirestore.instance.collection('rooms').doc(_snapshot.docs[0].id).set({
                     'onlyAdminSends':widget.room.onlyAdminSends
                   },SetOptions(merge: true));

                    _changeRoomRules(rule);

                  }else if(statusNo==2){
                    setState((){
                      widget.room.hasMemberLimit = !widget.room.hasMemberLimit;
                    });
                    String rule  = widget.room.hasMemberLimit ? "Member limit 100 " : "Member limit removed";

                    FirebaseFirestore.instance.collection('rooms').doc(_snapshot.docs[0].id).set({
                      'hasMemberLimit':widget.room.hasMemberLimit
                    },SetOptions(merge: true));

                    _changeRoomRules(rule);
                  }else if(statusNo==3){
                    setState((){
                      widget.room.mediaShareAllowed = !widget.room.mediaShareAllowed;
                    });
                    String rule  = widget.room.mediaShareAllowed ? "Media share is allowed" : "Media share is restricted";

                    FirebaseFirestore.instance.collection('rooms').doc(_snapshot.docs[0].id).set({
                      'mediaShareAllowed':widget.room.mediaShareAllowed
                    },SetOptions(merge: true));

                    _changeRoomRules(rule);

                  }else{
                    setState((){
                      widget.room.secretChatAllowed = !widget.room.secretChatAllowed;
                    });
                    String rule  = widget.room.secretChatAllowed ? "Members can chat secretly" : "Secret chats are restricted";

                    FirebaseFirestore.instance.collection('rooms').doc(_snapshot.docs[0].id).set({
                      'secretChatAllowed':widget.room.secretChatAllowed
                    },SetOptions(merge: true));

                    _changeRoomRules(rule);
                  }
                }
                _saveChanges() async{
                    if(_description.trim().length!=0){
                      print(_description);
                      QuerySnapshot _room = await FirebaseFirestore.instance
                          .collection('rooms')
                          .where('roomId',isEqualTo: widget.room.roomId)
                          .get();
                      FirebaseFirestore.instance.collection('rooms').doc(_room.docs[0].id).set(
                          {"description":_description},
                          SetOptions(merge: true)
                      );
                    }
                    Navigator.pop(context);
                }
                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  padding: EdgeInsets.only(top:10,left:15,right:15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(30))
                  ),
                  child: ListView(
                    physics: BouncingScrollPhysics(),
                    children: [
                      Container(
                        padding:EdgeInsets.all(8),
                        child: Text(
                            'Room  Description',
                          style: GoogleFonts.getFont('Roboto',fontSize: 12,color: Colors.grey[700]),
                        ),
                      ),
                      TextFormField(
                        initialValue: _description,
                        readOnly: widget.room.admin != widget.uid,
                        minLines: 1,
                        maxLines: 3,
                        textAlign: TextAlign.start,
                        style: GoogleFonts.getFont('Roboto',fontSize: 16),
                        onSaved: (val){
                          setState((){
                            _description = val;
                          });
                          },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          // hintText: widget.room.description,
                          border:new OutlineInputBorder(
                            borderSide: BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                            borderRadius: const BorderRadius.all(
                              const Radius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left:10,top:10,bottom:10),
                        child: Text(
                          'Room settings',
                          style: GoogleFonts.getFont('Roboto',fontSize: 16,color: Colors.grey[700]),
                        ),
                      ),

                      ListTile(
                        leading: Icon(Icons.lock_open_rounded),
                        title: Text('Only admin can send messages'),
                        trailing: Checkbox(
                          value: widget.room.onlyAdminSends,
                          tristate: true,
                          onChanged: (val){
                            if(widget.uid == widget.room.admin)
                              _changeRoomStatus(1);

                          },
                          checkColor: Theme.of(context).accentColor,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.event_seat_outlined),
                        title: Text('Limit members to 100'),
                        trailing: Checkbox(
                          value: widget.room.hasMemberLimit,
                          checkColor: Theme.of(context).accentColor,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val){
                            if(widget.uid == widget.room.admin)
                              _changeRoomStatus(2);
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.image),
                        title: Text('Media share allowed'),
                        trailing: Checkbox(
                          value: widget.room.mediaShareAllowed,
                          checkColor: Theme.of(context).accentColor,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val){
                            if(widget.uid == widget.room.admin)
                              _changeRoomStatus(3);
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.security_rounded),
                        title: Text('Secret chat allowed'),
                        trailing: Checkbox(
                          value: widget.room.secretChatAllowed,
                          checkColor: Theme.of(context).accentColor,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val){
                            if(widget.uid == widget.room.admin)
                              _changeRoomStatus(4);
                          },
                        ),
                      ),

                      Container(
                        margin: EdgeInsets.only(left:10,top:10),
                        child: Text(
                          'Memebers',
                          style: GoogleFonts.getFont('Roboto',fontSize: 16,color: Colors.grey[700]),
                        ),
                      ),

                      StreamBuilder(
                        stream: FirebaseFirestore.instance.collection('user').snapshots(),
                        builder: (context,AsyncSnapshot snapshot){
                          if(!snapshot.hasData)
                            return Center(
                              child: CircularProgressIndicator(),
                            );

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.room.members.length,
                            itemBuilder: (context,index){
                              if(!widget.room.members.contains(snapshot.data.docs[index]['uid']))
                                return Text('');
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal:8.0,vertical:2),
                                child: ListTile(
                                  tileColor: Colors.grey[200],
                                  leading: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                            image: CachedNetworkImageProvider(
                                                snapshot.data.docs[index]['photoUrl']
                                            )
                                        )
                                    ),
                                  ),
                                  title: Text(
                                    snapshot.data.docs[index]['userName'],
                                    style: GoogleFonts.getFont(
                                      'Roboto',
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(

                                    snapshot.data.docs[index]['email'],
                                    style: GoogleFonts.getFont(
                                      'Roboto',
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Container(
                                      child: GestureDetector(
                                          onTap: (){},
                                          child: Icon(Icons.cancel_presentation_sharp,size: 14,))
                                  ),

                                ),
                              );
                            },
                          );
                        },
                      ),

                    ],
                  ),
                );
              });
        }

    );
  }
  _buidRoomInfo(BuildContext context){
    return SafeArea(
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                // color: Colors.purple
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top:9,left:10),

                        width: MediaQuery.of(context).size.width*0.1,
                        height: MediaQuery.of(context).size.width*0.1,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: CachedNetworkImageProvider(widget.room.dp))
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.only(left:12,right:12,top:12),
                            margin: EdgeInsets.only(top:0,left: 8),
                            child: Text(
                                widget.room.roomName,
                                style: GoogleFonts.getFont( 'Source Sans Pro', fontSize: 18,color: Colors.grey[100],fontWeight: FontWeight.w400 ),
                            ),
                          ),

                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            GestureDetector(
              onTap: ()=>_buildSeeDetails(context),
              child: Container(
                margin: EdgeInsets.only(top:7,left: 9,right: 10),
                child: IconButton(
                  icon: Icon(Icons.more_horiz,color: Colors.grey[200],),
                  onPressed: ()=>_buildSeeDetails(context),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Color(0xFF5960b5),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                // height: MediaQuery.of(context).size.height*0.14,
                decoration: BoxDecoration(

                ),
                child: _buidRoomInfo(context),
              ),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                // padding: EdgeInsets.only(bottom: 100),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
                ),
                child: showChats(context),
              ),
            ),
            ],
          ),
          _buildMsgBox()
        ],
      ),
    );
  }
}
