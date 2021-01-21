class Message{
  String msg;
  String sendBy;
  String senderName;
  String dp;
  String roomId;
  int sendTime;
  var sendDate;
  bool hasImage;
  List readBy;
  List images;
  bool isFirstMsg,isMe;
  bool isReply;
  String replyTo,msgId;
  String replyMsg,currentUserUid,currenUserDp;
  Message({
    this.replyTo,
    this.replyMsg,
    this.isReply,
    this.isFirstMsg,
    this.isMe,
    this.msg,
    this.msgId,
    this.sendBy,
    this.roomId,
    this.senderName,
    this.dp,
    this.sendDate,
    this.sendTime,
    this.readBy,
    this.hasImage,
    this.images,
    this.currentUserUid,
    this.currenUserDp
});

  factory Message.fromJson(Map<String,dynamic> json){
    return Message(
      msg: json['msg'],
      sendBy: json['sendBy'],
      roomId: json['roomId'],
      sendDate: json['sendDate'],
      sendTime: json['sendTime'],
      readBy: json['readBy'],
      hasImage: json['hasImage'],
      images:json['images'],
      dp:json['dp'],
      senderName: json['senderName'],
      isFirstMsg: json['firstMsg'],
      isMe: json['sendBy'] == json['uid'] ? true : false,
      isReply: json['isReply'],
      replyMsg: json['replyMsg'],
      replyTo: json['replyTo'],
      currentUserUid:json['uid'],
        currenUserDp:json['userDp'],
      msgId: json['msgId']

    );
  }
}