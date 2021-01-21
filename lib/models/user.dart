
class Users{

   String userName;
   String email;
   String photoUrl;
   String uid;
   List rooms;

   Users({
      this.uid,
      this.userName,
      this.photoUrl,
      this.email,
      this.rooms
});

   factory Users.fromJson(Map<String,dynamic> json){
      return Users(
         userName: json['userName'],
         uid: json['uid'],
         photoUrl: json['photoUrl'],
         email: json['email'],
         rooms: json['rooms']
      );
   }
}