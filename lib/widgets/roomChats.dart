
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/models/message.dart';
import 'package:canopy/widgets/messageBox.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:canopy/models/keys.dart';
import 'package:flutter/material.dart';
import 'package:canopy/models/room.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

class RoomChats extends StatefulWidget {

  Room room ;
  String uid;
  String email;
  String dp;
  String userName;

  RoomChats({this.room,this.userName,this.email,this.dp,this.uid});

  @override
  _RoomChatsState createState() => _RoomChatsState(room:room);
}

class _RoomChatsState extends State<RoomChats> {
  Room room;
  _RoomChatsState({this.room});

  TextEditingController _sendMsgController = TextEditingController();
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

  pickImage()async{
    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.gallery );

    setState(() {
      file = File(_file.path);
    });
  }

  pickCamera()async{

    ImagePicker _picker = new ImagePicker();
    PickedFile _file = await _picker.getImage(source: ImageSource.camera);

    setState(() {
      file = File(_file.path);
    });

  }


  initState(){
    super.initState();
    markAllAsRead();

  }
  postMessage() async{
      if(_sendMsgController.text.trim().length!=0 || file!=null){
        var uuid = Uuid();
        String msgId = uuid.v1();
        if(_sendMsgController.text.trim().length == 0)
          _sendMsgController.text = "";

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
          'msg':_sendMsgController.text,
          'msgId': msgId,
          'sendBy': widget.uid,
          'roomId': room.roomId,
          'sendDate': msgDate,
          'sendTime': DateTime.now().millisecondsSinceEpoch,
          'readBy': [widget.uid],
          'hasImage': file==null ? false : true,
          'images':[],
          'firstMsg':firstMsg,
          'dp':widget.dp,
          'senderName': widget.userName
        };

        _msgRef.add(_msgData);

        CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');
        QuerySnapshot rooms = await roomRef.where('roomId',isEqualTo: room.roomId).get();

        print(msgId);
        List _peopleUnred = room.members;



        FirebaseFirestore.instance.collection('rooms').doc(rooms.docs[0].id).set(
            {
              'lastMessage':_sendMsgController.text,
              'lastMessageFrom':widget.userName,
              'lastMessageId':msgId,
              'lastMessageDate':msgDate,
              'lastMessageTimestamp':msgTimestamp,
              'peopleUnread': _peopleUnred
            },
            SetOptions(merge : true));

        _sendMsgController.clear();
        print('added');
      }
  }
  imageSendDialog(BuildContext context){
    showAnimatedDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: 300,
            padding: EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                height: 50,
                child: Image.file(file),  
                ),
                TextFormField(
                  controller: _sendMsgController,
                  decoration: InputDecoration(
                      hintText: "Room's Invitaion Code",
                      border: InputBorder.none,
                      fillColor: Colors.grey[200],
                      prefixIcon: Icon(Icons.home_outlined)
                  ),
                ),
                SizedBox(height: 20,),

                Center(
                  child: RaisedButton(onPressed:(){},child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal:28.0),
                    child: Text('Send'),
                  ),),
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

  StreamBuilder showChats(){

    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('messages').where('roomId',isEqualTo: room.roomId).orderBy('sendTime',descending: true).snapshots(),
      builder: (context,AsyncSnapshot snapshot){

        if(snapshot.data == null || snapshot == null){
          return Text('');
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
              'uid':widget.uid
            };
            Message _newMsg = Message.fromJson(data);

            return MessageBox(
              msg: _newMsg,
            );
          },
        );
      },
    );
  }

  roomInfo(){
    return Container(
      margin: EdgeInsets.only(left:40 , top:50),
      height: MediaQuery.of(context).size.height*0.15,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                    image: DecorationImage(
                    image: CachedNetworkImageProvider(room.dp)
                  )
                ),
              ),
              Container(
                padding: EdgeInsets.only(left:10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        room.roomName,
                      style: GoogleFonts.getFont(
                          'Roboto',
                      fontSize: 20,
                        color: Colors.white
                      )),
                      GestureDetector(
                          onTap: (){print('shoing room info');},
                          child: Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: Icon(Icons.info,size: 15, color: Colors.grey[200],),
                          ))
                    ],
                  ))
            ],
          ),


        ],
      ),
    );

  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(

    backgroundColor: Theme.of(context).primaryColor,
    bottomSheet: SendMsgBar(),
      body: Container(
        child: Column(
            children: [
              roomInfo(),
              Expanded(
                child: Container(
                    color: Colors.white,
                    child: showChats()),
              ),



            ],
          ),
      ),
     

    );
  }
}


class SendMsgBar extends StatefulWidget {
  @override
  _SendMsgBarState createState() => _SendMsgBarState();
}

class _SendMsgBarState extends State<SendMsgBar> {

 static final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Form(
        key: formKey,
        child: TextFormField(


        ),
      ),
    );
  }
}
