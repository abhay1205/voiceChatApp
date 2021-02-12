import 'dart:io';
import 'package:http/http.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  final docs;
  ChatPage(this.docs);
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  String groupChatID, userID;
  TextEditingController _tec = TextEditingController();
  ScrollController scrollController = ScrollController();
  String statusText = "";
  bool isComplete = false;


  @override
  void initState() {
    getGroupchatId();
    super.initState();
  }

  getGroupchatId()async{
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    userID = _prefs.getString('id');
    String anotherUserID = widget.docs['id'];

    if(userID.compareTo(anotherUserID)>0){
      groupChatID = '$userID - $anotherUserID';
    }else{
      groupChatID = '$anotherUserID - $userID';
    }
    setState(() {
    });
    
  }

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
      ),
      body: StreamBuilder(
        stream: groupChatID!=null? FirebaseFirestore.instance.collection('messages').doc(groupChatID).collection(groupChatID).orderBy('timestamp', descending: true).snapshots():null,
        builder: (context, snapshot) {
          
          if(snapshot.hasData && snapshot.data!=null){
            print(groupChatID);
            print(snapshot.data.docs.length);
            // return Text('hello');
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                    return buildItem(snapshot.data.docs[index],);
                  },),
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Expanded(
                    //   child: Container(
                        
                    //     color: Colors.grey[200],
                    //     child: TextField(
                    //       controller: _tec,
                          
                    //     ),
                    //   ),
                    // ),
                    IconButton(
                      icon: Icon(Icons.mic, color: statusText=='START'?Colors.red:Colors.black,),
                      onPressed: (){startRecord();
                      _tec.clear();},
                    ),
                    IconButton(
                      icon: Icon(Icons.mic_off),
                      onPressed: (){stopRecord();
                      _tec.clear();},
                    ),
                    IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: (){play();
                      _tec.clear();},
                    ),
                    // IconButton(
                    //   icon: Icon(Icons.send),
                    //   onPressed: (){sendMsg();
                    //   _tec.clear();},
                    // )
                  ],
                )
              ],
            );
          }else{
            return Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),),),);
          }
        },
      ),
      
    );
  }

  sendMsg(){
    String msg = _tec.text.trim();
    print('here');
    if(msg.isNotEmpty){
      var ref = FirebaseFirestore.instance.collection('messages').doc(groupChatID).collection(groupChatID).doc(DateTime.now().millisecondsSinceEpoch.toString());
      FirebaseFirestore.instance.runTransaction((transaction)async{
        await transaction.set(ref, {
          "senderId": userID,
          "anotherUserId": widget.docs['id'],
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "content": msg,
          "type": 'text'
        });
      });
      scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.bounceInOut);
    }else{
      print("Hello");
    }
  }
  sendAudioMsg(String audioMsg){
    if(audioMsg.isNotEmpty){
      var ref = FirebaseFirestore.instance.collection('messages').doc(groupChatID).collection(groupChatID).doc(DateTime.now().millisecondsSinceEpoch.toString());
      FirebaseFirestore.instance.runTransaction((transaction)async{
        await transaction.set(ref, {
          "senderId": userID,
          "anotherUserId": widget.docs['id'],
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "content": audioMsg,
          "type": 'audio'
        });
      });
      scrollController.animateTo(0.0, duration: Duration(milliseconds: 100), curve: Curves.bounceInOut);
    }else{
      print("Hello");
    }
  }
  buildItem(doc){
    print("MSG "+ doc['content']);
    return Padding(
      padding: EdgeInsets.only(top: 8, left: ((doc['senderId']== userID)?64:10), right: ((doc['senderId'] == userID)?10:64) ),
      child: Container(
        width: MediaQuery.of(context).size.width*0.5,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (doc['senderId']== userID)?Colors.blueAccent:Colors.greenAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: GestureDetector(
          onTap: (){_loadFile(doc['content']);},
          child: Row(
            children: [
              Text('Audio', maxLines: 10,),
              Icon(Icons.play_arrow)
            ],
          )),
      ),
    );
  }

  Future _loadFile(String url) async {
    final bytes = await readBytes(url);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (await file.exists()) {
      setState(() {
        recordFilePath = file.path;
      });
      play();
    }
  }

   Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "Recording...";
      recordFilePath = await getFilePath();
      isComplete = false;
      RecordMp3.instance.start(recordFilePath, (type) {
        statusText = "Record error--->$type";
        setState(() {});
      });
    } else {
      statusText = "No microphone permission";
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Recording...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  void stopRecord() async{
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Record complete";
      await uploadAudio();
      isComplete = true;
      setState(() {});
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }

  String recordFilePath;

  void play() {
    if (recordFilePath != null && File(recordFilePath).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(recordFilePath, isLocal: true);
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return sdPath + "/test_${i++}.mp3";
  }

  uploadAudio() {
    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child('profilepics/audio${DateTime.now().millisecondsSinceEpoch.toString()}}.jpg');

    StorageUploadTask task = firebaseStorageRef.putFile(File(recordFilePath));
    task.onComplete.then((value) async {
      print('##############done#########');
      var audioURL = await value.ref.getDownloadURL();
      String strVal = audioURL.toString();
      await sendAudioMsg(strVal);
    }).catchError((e) {
      print(e);
    });
  }
}