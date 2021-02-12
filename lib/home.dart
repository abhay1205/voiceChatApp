import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fchat_app/chatpage.dart';
import 'package:fchat_app/login.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
    'https://www.googleapis.com/auth/drive',
  ],
  );
  String userId;
  @override
  void initState() {
    getUserId();
    super.initState();
  }

  getUserId()async{
    final _prefs = await SharedPreferences.getInstance();
    userId = _prefs.getString('id');
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'),
      actions: [
        RaisedButton(
          child: Text('Log Out'),
          onPressed: ()async{
            await googleSignIn.signOut();
            final _prefs = await SharedPreferences.getInstance();
            _prefs.setString('id', '');
            await _prefs.clear().then((value) => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>Login())));
          },
        )
      ],),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasData && snapshot.data!=null){
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
              return buildItem(snapshot.data.docs[index]);
            },);
          }
          else{
            return Container();
          }
        },
      ),
    );
  }

  buildItem(doc){
    return (userId != doc['id'])?GestureDetector(
      onTap: (){
        Navigator.of(context).push( MaterialPageRoute(builder: (context) =>ChatPage(doc) ,));
      },
          child: Card(
        color: Colors.lightBlue,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: Container(
            child: Center(child: Text(doc['name']),),
          ),
        ),
      ),
    ):Container();
  }
}