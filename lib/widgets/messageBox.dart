import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/models/message.dart';
import 'package:canopy/models/room.dart';
import 'package:canopy/models/time.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emojis/emojis.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';


class MessageBox extends StatefulWidget {

  Message msg;
  Room room;
  String uid;
  String userName;
  String email;
  String dp;
  String userDp;
  bool isInContinuation;

  MessageBox({
    this.msg,
    this.room,
    this.userName,
    this.uid,
    this.email,
    this.dp,
    this.userDp,
    this.isInContinuation
  });

  @override
  _MessageBoxState createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> {


  TextEditingController _replyMsgController = new TextEditingController();

  _showImagePreview(BuildContext context){
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:(BuildContext context){
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 1/1,
                  child: Container(
                    color: Colors.transparent,
                    child: InteractiveViewer(

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
                                image: CachedNetworkImageProvider(widget.msg.images[0])
                            )
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          );
        }

    );
  }

  _postReply(BuildContext context) async{

    if(_replyMsgController.text.trim().length !=0){
      var uuid = Uuid();
      String msgId = uuid.v1();
      if(_replyMsgController.text.trim().length == 0)
        _replyMsgController.text = "";

      DateTime msgDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) ;
      int msgTimestamp = DateTime.now().millisecondsSinceEpoch;
      CollectionReference _msgRef =  FirebaseFirestore.instance.collection('messages');
      QuerySnapshot thisDayMsg = await _msgRef.
      where('roomId',isEqualTo: widget.msg.roomId).
      where('sendDate',isEqualTo: msgDate).get();

      bool firstMsg = false;

      if(thisDayMsg.docs.length == 0)
        firstMsg = true;
      else firstMsg = false;

      // Future
      Map<String,dynamic> _msgData = {
        'msg':_replyMsgController.text,
        'msgId': msgId,
        'sendBy': widget.uid,
        'roomId':widget.msg.roomId,
        'sendDate': msgDate,
        'sendTime': DateTime.now().millisecondsSinceEpoch,
        'readBy': [widget.uid],
        'hasImage': false,
        'images':[],
        'firstMsg':firstMsg,
        'dp':widget.userDp,
        'senderName': widget.userName,
        'isReply': true,
        'replyTo':widget.msg.senderName,
        'replyMsg':widget.msg.msg
      };

      _msgRef.add(_msgData);

      CollectionReference roomRef = FirebaseFirestore.instance.collection('rooms');
      QuerySnapshot rooms = await roomRef.where('roomId',isEqualTo: widget.room.roomId).get();

      print(msgId);
      List _peopleUnred = widget.room.members;



      FirebaseFirestore.instance.collection('rooms').doc(rooms.docs[0].id).set(
          {
            'lastMessage':_replyMsgController.text,
            'lastMessageFrom':widget.userName,
            'lastMessageId':msgId,
            'lastMessageDate':msgDate,
            'lastMessageTimestamp':msgTimestamp,
            'peopleUnread': _peopleUnred
          },
          SetOptions(merge : true));
      Navigator.pop(context);
     String _msg = _replyMsgController.text;
      _replyMsgController.clear();
      String heading = Emojis.highVoltage+' '+widget.room.roomName+' '+Emojis.highVoltage;
      _msg = Emojis.person +' '+widget.userName+' '+Emojis.wavyDash+' '+ _msg;
      var json = {
        "app_id":"7e10d394-e980-4e0f-824f-8255cfe44a18",
        "headings":{"en":heading},
        "contents":{"en":_msg},
        "include_player_ids":widget.room.tokens
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

  _buildReplyBox(BuildContext context){
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:(BuildContext context){
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(),
            child: Column(
              children: [
               Container(
                 // height: MediaQuery.of(context).size.height * 0.1,
                 width: MediaQuery.of(context).size.width,
                 margin: EdgeInsets.only(left:20,right:20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.only(
                       topLeft:Radius.circular(20),
                        topRight:Radius.circular(20)
                   )
                 ),

                 child: Container(
                   // color: Colors.red,
                   padding: EdgeInsets.all(12.0),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                          Text(
                              'replying to @'+widget.msg.senderName,
                              style: GoogleFonts.getFont('Roboto',
                              fontSize: 12,
                                color: Colors.grey[500]
                              ),
                          ),

                       Container(
                         // color: Colors.red,
                         width: MediaQuery.of(context).size.width,
                         margin: EdgeInsets.only(top:10),
                         child: Text(
                             widget.msg.msg,
                            style: GoogleFonts.getFont('Roboto',
                            fontSize: 15,
                              color: Colors.grey[700]
                            ),
                           overflow: TextOverflow.ellipsis,
                         ),
                       )
                     ],
                   ),
                 ),
               ),
                Container(
                    margin: EdgeInsets.only(bottom:20,left:20,right:20),
                    child: TextFormField(
                      controller: _replyMsgController,
                      autofocus: true,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFebe9f2),
                          hintText: 'say something...',
                          suffixIcon: GestureDetector(
                              onTap: ()=>_postReply(context),
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
        }

    );
  }


  _buildDateMarker(){
      return Container(
        margin: EdgeInsets.only(top:8),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7075bf),
              blurRadius: 5.0,
            ),],

          color: Color(0xFF7075bf),
          borderRadius: BorderRadius.all(Radius.circular(20),

          ),

            
        )
        ,
        child: Text(
            getDateFromTimestamp(widget.msg.sendTime),
          style: GoogleFonts.getFont('Open Sans',
          fontSize: 13.5,
            color: Colors.white
          ),
        ),
      );
    }
  _buildRoomNotification(){
    return Container(
      margin: EdgeInsets.only(top:8),
      padding: EdgeInsets.only(top:4,bottom: 4,left: 10,right: 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7075bf),
            blurRadius: 5.0,
          ),],

        color: Color(0xFF7075bf),
        borderRadius: BorderRadius.all(Radius.circular(20),

        ),


      )
      ,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(widget.msg.msgId!='0')
          Text(
            'Room settings changed',
            style: GoogleFonts.getFont('Open Sans',
                fontSize: 13.5,
                color: Colors.white
            ),
          ),
          Text(
            widget.msg.msg,
            style: GoogleFonts.getFont('Open Sans',
                fontSize: 13.5,
                color: Colors.white
            ),
          ),
        ],
      ),
    );
  }

  _buildMsgBox(BuildContext context){

      return Container(
        // color: Colors.red,
        padding: widget.msg.isMe ? EdgeInsets.only(
            left: 100,
            right: 20
        ):
        EdgeInsets.only(
            right: 100,
            left: 20
        ),
        child: Container(
          // color: Colors.red,
          margin: EdgeInsets.only(top:10),

          child: Row(
            children: [
              if(widget.msg.isMe)
                Container(
                  child: Text(
                    getTimeFromTimestamp(widget.msg.sendTime),
                    style: GoogleFonts.getFont('Roboto',
                    fontSize: 10,
                      color: Colors.grey[600]
                    ),
                  ),
                ),

              if(!widget.msg.isMe && !widget.isInContinuation)
              Column(
                children: [
                  Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(

                        image: CachedNetworkImageProvider(widget.msg.dp),
                        fit:BoxFit.cover

                      )
                    ),
                  ),
                  // Text(widget.msg.senderName,style: TextStyle(fontSize: 10),)
                ],
              ),
              if(!widget.msg.isMe && widget.isInContinuation)
                Expanded(
                  child: SizedBox(width:1,),
                ),
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                margin: EdgeInsets.only(left: 10),
                padding: EdgeInsets.only(top:20,left:20,right:20,bottom: 20),
                decoration: BoxDecoration(
                  color: widget.msg.isMe ? Color(0xFFedeef7) : Color(0xFFf5f5f6),
                  borderRadius: widget.msg.isMe ?
                      BorderRadius.only(
                        topLeft:Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30)
                      ):BorderRadius.only(
                      topLeft:Radius.circular(30),
                      topRight: Radius.circular(30),
                      bottomRight: Radius.circular(30)
                  )
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                   widget.msg.isMe ?  Text(
                        'You',
                     style: GoogleFonts.getFont('Roboto',
                     fontSize: 12,
                       color: Colors.grey[500]
                     ),
                    ):
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.msg.senderName,
                          style: GoogleFonts.getFont('Roboto',
                              fontSize: 12,
                              color: Colors.grey[500]
                          ),),
                        widget.msg.msg ==''? Text(''):
                        GestureDetector(
                          onTap:  widget.room.onlyAdminSends ? null : ()=>_buildReplyBox(context),
                            child: Icon(Icons.reply ,size: 12,
                            color: Colors.grey,
                            ))
                      ],
                    )
                    ,

                    if(widget.msg.isReply )
                      Container(
                          padding: EdgeInsets.only(top:4),
                          child:Container(
                            padding: EdgeInsets.all(8),

                            decoration: BoxDecoration(
                              color:  widget.msg.isMe ? Color(0xFFf7f7f8):Color(0xFFf0eef7),

                              borderRadius: BorderRadius.all(Radius.circular(10))
                            ),
                              margin: EdgeInsets.only(top:3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@'+widget.msg.replyTo,
                                      style: GoogleFonts.getFont('Roboto',
                                      fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                          color: Colors.grey[800]
                                      ),
                                  ),
                                  Text(
                                    widget.msg.replyMsg,
                                    style: GoogleFonts.getFont('Roboto',
                                    color: Colors.grey[800],
                                      fontSize: 15
                                    ),
                                  ),
                                ],
                              ))
                ),

                    if(widget.msg.hasImage)
                      Container(
                        height: 150,
                        margin: EdgeInsets.only(top:5),
                        // height: MediaQuery.of(context).size.height * 0.3,
                        // width: MediaQuery.of(context).size.width * 0.3,
                        decoration: BoxDecoration(
                          // color: Colors.red,
                      ),
                        child: GestureDetector(
                          onTap: ()=>_showImagePreview(context),
                          child: AspectRatio(
                            aspectRatio:1/1,
                            child: Image(
                              image:CachedNetworkImageProvider(
                                widget.msg.images[0]
                              ),
                              fit: BoxFit.fill, // use this
                            ),
                          ),
                        )),
                    Container(
                        padding: EdgeInsets.only(top:4),
                        child: Text(
                            widget.msg.msg,
                            style: GoogleFonts.getFont('Roboto',
                                fontSize: 15,
                                color: Colors.grey[800]
                            )
                        )),
                  ],
                ),
              ),

              if(!widget.msg.isMe)
                Expanded(

                  child: Container(
                    // color: Colors.blue,
                    padding: EdgeInsets.only(left:6),
                    child: Text(
                      getTimeFromTimestamp(widget.msg.sendTime),
                      style: GoogleFonts.getFont('Roboto',
                          fontSize: 10,
                          color: Colors.grey[600]
                      ),
                    ),
                  ),
                ),

            ],
          ),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          if(widget.msg.isFirstMsg)
            _buildDateMarker(),
          if(widget.msg.senderName=='canopy')
            _buildRoomNotification()
          else
          _buildMsgBox(context)

        ],
      ),
    );
  }
}


