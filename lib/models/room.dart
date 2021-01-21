class Room{
  String roomId,roomName,admin,lastMessage,lastMessageFrom,dp,description;
  List members;
  int lastMessageTimestamp;
  List tokens;
  bool onlyAdminSends;
  bool hasMemberLimit;
  bool mediaShareAllowed;
  bool secretChatAllowed;

  Room({
    this.tokens,
    this.lastMessageTimestamp ,
    this.roomName,
    this.roomId,
    this.members,
    this.admin,
    this.lastMessageFrom,
    this.lastMessage,
    this.dp,
    this.onlyAdminSends,
    this.mediaShareAllowed,
    this.secretChatAllowed,
    this.hasMemberLimit,
    this.description
  });

  factory Room.fromJson(Map<String,dynamic> json){
    return Room(
      roomName:  json['roomName'],
      roomId:  json['roomId'],
      members: json['members'],
      admin: json['admin'],
      lastMessage: json['lastMessage'],
      lastMessageFrom: json['lastMessageFrom'],
      dp:json['dp'],
        lastMessageTimestamp:json['lastMessageTimestamp'],
      tokens:json['tokens'],
      onlyAdminSends: json['onlyAdminSends'],
      mediaShareAllowed: json['mediaShareAllowed'],
      secretChatAllowed: json['secretChatAllowed'],
      hasMemberLimit: json['hasMemberLimit'],
      description: json['description']


    );
  }

}