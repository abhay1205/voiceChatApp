import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fchat_app/chatpage.dart';
import 'package:fchat_app/login.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
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

  getUserId() async {
    final _prefs = await SharedPreferences.getInstance();
    userId = _prefs.getString('id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pink,
        title: Text('Flutter Voice Chat App'),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () async {
              await googleSignIn.signOut();
              final _prefs = await SharedPreferences.getInstance();
              _prefs.setString('id', '');
              await _prefs.clear().then((value) => Navigator.of(context)
                  .pushReplacement(
                      MaterialPageRoute(builder: (context) => Login())));
            },
          ),
          // CONTRIBUTION ON THIS IS WELCOMED FOR FLUTTER ENTHUSIATS
          Icon(Icons.more_vert)
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(image: AssetImage('asset/crop.jpeg'))),
        child: Stack(
          children: [
            buildFloatingSearchBar(),
            Positioned(
              top: 70,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return ListView.builder(
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          return buildItem(snapshot.data.docs[index]);
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
            ),
            buildFloatingSearchBar(),
          ],
        ),
      ),
      // CONTRIBUTION ON THIS IS WELCOMED FOR FLUTTER ENTHUSIATS
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: Icon(
          Icons.message,
          color: Colors.white,
        ),
      ),
    );
  }

  buildItem(doc) {
    return (userId != doc['id'])
        ? GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatPage(doc),
              ));
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              color: Colors.pink,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Container(
                    child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(doc['name']
                            .toString()
                            .split(' ')
                            .first
                            .substring(0, 1) +
                        doc['name'].toString().split(' ')[1].substring(0, 1)),
                  ),
                  title: Text(
                    doc['name'],
                    style: TextStyle(color: Colors.white),
                  ),
                )),
              ),
            ),
          )
        : Container();
  }

  // CONTRIBUTION ON THIS IS WELCOMED FOR FLUTTER ENTHUSIATS
  Widget buildFloatingSearchBar() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    List<dynamic> searchResult = [];
    return FloatingSearchBar(
      borderRadius: BorderRadius.circular(30),
      hint: 'Search Chats',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 500),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      maxWidth: isPortrait ? 600 : 500,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) {},
      backdropColor: Colors.pink,
      automaticallyImplyBackButton: false,
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction.back(
          color: Colors.pink,
          showIfClosed: false,
        ),
        FloatingSearchBarAction.searchToClear(
          color: Colors.pink,
          showIfClosed: true,
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          child: Material(
              color: Colors.white,
              elevation: 4.0,
              child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20)),
                height: MediaQuery.of(context).size.height * 0.9,
                child: ListView.builder(
                  itemCount: 0,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 38, vertical: 10),
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(blurRadius: 2, color: Colors.grey)
                            ]),
                        height: 60,
                        width: 300,
                        child: Text(
                          ' ',
                          maxLines: 3,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              )),
        );
      },
    );
  }
}
