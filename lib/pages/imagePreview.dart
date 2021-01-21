import 'package:flutter/material.dart';
class PreviewAndSend extends StatefulWidget {

  @override
  _PreviewAndSendState createState() => _PreviewAndSendState();
}

class _PreviewAndSendState extends State<PreviewAndSend> {

  _buildImagePreviewAndSend(){
    return Container(
      // color: Colors.red,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(
              color:Theme.of(context).primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(10))
            ),
            margin: EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 16/9,
            child: Card(
              color: Color(0xFFedeef7),
                elevation: 10,
                child: Image.network('https://phillipbrande.files.wordpress.com/2013/10/random-pic-14.jpg'))),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20))
            ),
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildImagePreviewAndSend(),
          )
        ],
      ),
    );
  }
}
