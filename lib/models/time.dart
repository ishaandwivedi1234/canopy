
import 'package:intl/intl.dart';

  String getTimeFromTimestamp(int timestamp){
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var formattedDate = date.hour.toString() + ':'+date.minute.toString()+' ';
    if(date.minute > 12)
      formattedDate = formattedDate ;
    else formattedDate = formattedDate ;

    return formattedDate ;// Apr 8, 2020
  }

  String getDateFromTimestamp(int timestamp){
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    var formattedDate =  date.day.toString() + '/'+ date.month.toString() + '/' + date.year.toString();
    return formattedDate;

  }