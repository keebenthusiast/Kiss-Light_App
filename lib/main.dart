// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

//Socket sock;

/*
void main() async {
  final socket = await Socket.connect('192.168.3.175', 1155);
  sock = socket;
  print("Connected to server ${socket.remoteAddress.address}:${socket.remotePort}");

  //listen to responses from server
  socket.listen(

    // Handler
    (Uint8List data) {
      print( "In Data Handler Now" );
      print(new String.fromCharCodes(data));
    },

    // handle errors
    onError: (error, StackTrace trace) {
      print(error);
    },

    // handle server ending connection
    onDone: () {
      print( "Exiting from Server, goodbye!" );
      socket.destroy();
    },
  );

  await sendMessage(socket, 'LIST KL/0.3\n');

  runApp(Klapp());

  //This is how to exit server
  //await sendMessage(socket, 'Q\n');
}*/

/* handle sending requests */
Future<void> sendMessage(Socket socket, String message) async {
  print("client sending request: $message");
  socket.write(message);
  await Future.delayed(Duration(seconds: 2));
}

/* Main function */
void main() => runApp(Klapp());

class Klapp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisslight server info',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      //home: RandomWords(),
      home: SetupPage(storage: Storage()),
    );
  }
}

/* class for writing to file */
class Storage {
  /* Provide a way to get current information
  * with the specific file.
  */
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    print('FLEEEEEEEF ' + directory.path);

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;

    return File('$path/kisslight.txt');
  }

  /* read from file */
  Future<String> readFile() async {
    try {
      final file = await _localFile;

      String contents = await file.readAsString();

      return contents;
    } catch (e) {
      // return a period
      return '.';
    }
  }

  /* Write to file */
  Future<File> writeFile(String data) async {
    final file = await _localFile;

    return file.writeAsString(data);
  }
}

/* Setup State page */
class SetupPage extends StatefulWidget {
  final Storage storage;

  SetupPage({Key key, @required this.storage}) : super(key: key);

  @override
  _SetupPageState createState() => _SetupPageState();
}

/* the state for the setup page */
class _SetupPageState extends State<SetupPage> {
  var ip = null;
  var port = 1155;
  List<String> ipAndPort = [null, null];

  /* Initialize by retreiving previously saved values (if applicable) */
  @override
  void initState() {
    super.initState();
    widget.storage.readFile().then((String contents) {
      setState(() {
        if (contents != '.') {
          print("BINGO " + contents);
          ipAndPort = contents.split(':');
          ip = ipAndPort[0];
          port = int.parse(ipAndPort[1]);
        } else {
          print("PERIOD FOUND " + contents);
        }
      });
    });
  }

/* Provide way to update file if needed */
  Future<File> _updateValues( String i, String p ) {
    // Write the variable as a string to the file.
    return widget.storage.writeFile(i + ':' + p);
  }

  Future<void> _showSaveDialog( String i, String p ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Save Kiss-Light IP'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text('Would you like to save these settings?'),
                Text(i + ':' + p),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                // write to file
                _updateValues( i, p );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logo = Padding(
      padding: EdgeInsets.all(20),
      child: Hero(
          tag: 'kiss-light',
          child: CircleAvatar(
            radius: 56.0,
            child: Image.asset('assets/kl-logo.png'),
          )),
    );

    TextEditingController ipCtrl = new TextEditingController();
    final inputIP = Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ipCtrl,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
            hintText: (ipAndPort[0] == null) ? 'IP address' : ipAndPort[0],
            contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50.0),
            )),
      ),
    );

    TextEditingController portCtrl = new TextEditingController();
    final inputPort = Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: portCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            hintText: (ipAndPort[1] == null) ? 'kiss-light port' : ipAndPort[1],
            contentPadding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(50.0))),
      ),
    );

    final buttonConnect = Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: ButtonTheme(
        height: 56,
        child: RaisedButton(
          child: Text('Connect',
              style: TextStyle(color: Colors.white, fontSize: 20)),
          color: Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          onPressed: () {
            if (ip == null || (ipCtrl.text != '' && portCtrl.text != '')) {
              print("prompt if want to save");
              _showSaveDialog(ipCtrl.text, portCtrl.text);
            }
            /* now to connect and move to the new screen */
          },
        ),
      ),
    );

    return SafeArea(
        child: Scaffold(
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 20),
          children: <Widget>[logo, inputIP, inputPort, buttonConnect],
        ),
      ),
    ));
  }
}
