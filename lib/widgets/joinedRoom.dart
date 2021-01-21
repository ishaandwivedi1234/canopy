import 'package:cached_network_image/cached_network_image.dart';
import 'package:canopy/models/room.dart';
import 'package:canopy/models/time.dart';
import 'package:canopy/pages/chats.dart';
import 'package:canopy/widgets/roomChats.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinedRooms extends StatefulWidget {
  String uid ;
  String email;
  String userDp;
  String userName;

  JoinedRooms({this.uid,this.email,this.userName,this.userDp});
  @override
  _JoinedRoomsState createState() => _JoinedRoomsState();
}

class _JoinedRoomsState extends State<JoinedRooms> {

  @override
  void initState() {
    // TODO: implement initState
    print('JoinRoom photo : '+ widget.userDp);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20),topRight: Radius.circular(20))
      ),

      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rooms')
            .where('members',arrayContains: widget.uid, )
            .orderBy('lastMessageTimestamp',descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot>snapshot) {
          if(snapshot.data == null || snapshot == null) {
            return Text('');
          }else
          return ListView.builder(
            itemCount: snapshot.data.docs.length,
            itemBuilder: (context,index){
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

              if( members.contains(widget.uid))
              return RoomsChat(
                  dp: dp,
                  roomName: roomName,
                  lastMessageFrom: lastMsgFrom,
                  lastMessage: lastMsg,
                  room:_room,
                  uid: widget.uid,
                  userName: widget.userName,
                  userDp: widget.userDp,
                  email: widget.email,
                  lastMsgId:lastMsgId,
                  hasUnread:hasUnread
              );
              else return Text('');
            },
          );
        }
      )
    );
  }
}


class RoomsChat extends StatefulWidget {
  String dp;
  String roomName;
  String lastMessage;
  String lastMessageFrom;
  String uid;
  String email;
  String userDp;
  String userName;
  String lastMsgId;
  bool hasUnread;


  Room room ;

  RoomsChat({
    this.dp,
    this.roomName,
    this.lastMessage,
    this.lastMessageFrom,
    this.room,
    this.uid,
    this.userName,
    this.userDp,
    this.email,
    this.lastMsgId,
    this.hasUnread
  });

  @override
  _RoomsChatState createState() => _RoomsChatState();
}

class _RoomsChatState extends State<RoomsChat> {


  showRoomChats(Room room){
    Navigator.push(context, MaterialPageRoute(
        builder: (context)=>
            Chats(
              room: room,
              userName: widget.userName,
              uid: widget.uid,
              email: widget.email,
              dp: widget.dp,
              userDp: widget.userDp,
            )));
  }

  @override
  void initState() {
    // TODO: implement initState
    print('Room chat dp '+widget.userDp);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    
    @override
    initState(){
      super.initState();
    }


    
    return GestureDetector(
      onTap: ()=>showRoomChats(widget.room),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: widget.hasUnread  ? Color(0xFFf0eef7) : Colors.grey[50]
        ),

        child:Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(

            children: [
              Row(
                crossAxisAlignment:CrossAxisAlignment.start,
                children: [

                  GestureDetector(
                    onTap:()=> _showImagePreview(context,widget.room.dp),
                    child: Stack(
                      children: [
                        Container(

                          margin: EdgeInsets.only(top:8),
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(

                              shape: BoxShape.circle,

                              boxShadow: [
                                BoxShadow(
                                color: Colors.grey[500],
                                blurRadius: 5.0,
                              ),],
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: CachedNetworkImageProvider(widget.dp)
                            )
                          ),
                        ),
                        if(widget.hasUnread)
                          Container(
                          padding: EdgeInsets.only(top:0,right: 40,bottom: 20),
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,

                          ),
                          child: Icon(Icons.circle,color: Colors.green, size: 10,),
                        ),
                      ],
                    )
                  ),
                  Stack(
                    children: [
                      Container(
                        // color: Colors.red,
                        width: MediaQuery.of(context).size.width *0.7 ,
                        // color: Colors.red,
                          margin: EdgeInsets.only(top:5,left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                      widget.roomName?? 'roomname null',
                                    style: GoogleFonts.getFont('Concert One',fontSize: 17,color: Color(0xFF685d80) , fontWeight: FontWeight.w100)
                                  ),
                                ],
                              ),
                              Container(
                                // color: Colors.blueGrey,
                                child:Row(
                                  children: [
                                    Text(

                                      widget.lastMessageFrom ?? 'last msg from null',
                                      style: GoogleFonts.getFont('Concert One',fontSize: 15,fontWeight: FontWeight.w200,color: Colors.grey[600])
                                      ,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(width: 5,),
                                    Expanded(
                                      child: Container(
                                        // color: Colors.green,
                                        width: MediaQuery.of(context).size.width *0.4,
                                        margin: EdgeInsets.only(top:5),
                                        child: SizedBox(
                                          width: MediaQuery.of(context).size.width*0.5,

                                          child:
                                          widget.lastMessage == '' ?
                                              Row(
                                                children: [
                                                  Icon(Icons.image,
                                                  size: 18,
                                                  color: Colors.purple[200],
                                                  ),
                                                  Text('shared image')
                                                ],
                                              ):
                                          Text(
                                            widget.lastMessage,
                                            style:GoogleFonts.getFont('Assistant',fontSize: 14,fontWeight: FontWeight.w600,color: Colors.grey[700]),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),


                            ],
                          )
                      ),
                      Container(
                        // color: Colors.red,
                        margin: EdgeInsets.only(left: 250,top:10),
                          child: Text(
                            getTimeFromTimestamp(widget.room.lastMessageTimestamp).trimRight(),
                          overflow: TextOverflow.fade,

                            style: TextStyle(fontSize: 10,color: Colors.grey[600]),
                          ),
                        )
                    ],
                  )
                ],
              ),



            ],
          ),
        ) ,
      ),
    );
  }
}

_showImagePreview(BuildContext context,String imageUrl){
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
                            image: CachedNetworkImageProvider(imageUrl)
                        )
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