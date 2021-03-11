import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

final _devs = <String>[];
final _devTypes = <String>[];
final _klversion = 0.3;

/* Main function */
void main() => runApp(Klapp());

Future<void> _sendRequest(String ip, int port, String message) async {
  var socket = await Socket.connect(ip, port);
  print("Connected to server ${socket.remoteAddress.address}" +
      ":${socket.remotePort}");

  //listen to responses from server
  socket.listen(
    // Handler
    (Uint8List data) {
      String resp = String.fromCharCodes(data);
      List<String> msg = resp.split(' ');
      print('Full message: ' + String.fromCharCodes(data));
      print('Response: ' + msg[1]);
      int response = int.parse(msg[1]);

      switch (response) {
        case 200:
        case 201:
        case 202:
        case 203:
          print('retreived a ' + response.toString());
          break;

        case 204:
          print('retreived a ' + response.toString());
          // this is a stickup, reset _devs;
          _devs.clear();
          _devTypes.clear();

          List<String> ls = String.fromCharCodes(data).split('\n');

          for (int i = 1; i < ls.length - 2; i++) {
            List<String> tmp = ls[i].split(' ');
            print('dev name: ' + tmp[0]);
            print('dev type: ' + tmp[4]);
            _devs.add(tmp[0]);
            _devTypes.add(tmp[4]);
          }
          break;

        case 205:
        case 206:
        case 207:
        case 208:
        case 209:
        case 210:
          print('retreived a ' + response.toString());
          break;

        default:
          print('Some error occurred, server returned ' + response.toString());
          break;
      }
    },

    // handle errors
    onError: (error, StackTrace trace) {
      print(error);
    },

    // handle server ending connection
    onDone: () {
      print("Exiting from Server, goodbye!");
      socket.destroy();
    },
  );

  print("client sending request: $message");
  socket.write(message);
  await Future.delayed(Duration(milliseconds: 50));
  socket.write('Q\n');
}

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
  var ip = '';
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
  Future<File> _updateValues(String i, String p) {
    // Write the variable as a string to the file.
    return widget.storage.writeFile(i + ':' + p);
  }

  /* get list of devices */
  Future<void> getDevices() async {
    await _sendRequest(ip, port, 'LIST KL/0.3\n');
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> _showSaveDialog(String i, String p) async {
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
                _updateValues(i, p);
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
        child: ElevatedButton(
          onPressed: () async {
            /* now to connect and move to the new screen */
            if (ip == '' || (ipCtrl.text != '' && portCtrl.text != '')) {
              print("prompt if want to save");
              _showSaveDialog(ipCtrl.text, portCtrl.text);
              await getDevices();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EstablishedPage(
                    ip: ipCtrl.text,
                    port: int.parse(portCtrl.text),
                  ),
                ),
              );
            } else if (ip != null &&
                (ipCtrl.text == '' && portCtrl.text == '')) {
              await getDevices();
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EstablishedPage(
                            ip: ip,
                            port: port,
                          )));
            }
          },
          child: Text('Connect',
              style: TextStyle(color: Colors.white, fontSize: 32)),
          style: ElevatedButton.styleFrom(
            onPrimary: Colors.white,
            primary: Colors.black87,
            minimumSize: Size(250, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
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

/* Established State page */
class EstablishedPage extends StatefulWidget {
  final String ip;
  final int port;

  EstablishedPage({Key key, @required this.ip, @required this.port})
      : super(key: key);

  @override
  _EstablishedPageState createState() => _EstablishedPageState();
}

/* the state for the established page */
class _EstablishedPageState extends State<EstablishedPage> {
  /* Initialize by retreiving previously saved values (if applicable) */
  @override
  void initState() {
    super.initState();
    // may not need this.
  }

/* For exiting, I think at least */
  @override
  void dispose() {
    //may not need this.
    super.dispose();
  }

  Widget _buildList() {
    print("In _buildList() function");
    return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _devs.length,
        itemBuilder: (context, i) {
          print("devs: " + _devs[i] + " types: " + _devTypes[i]);
          return _buildRow(_devs[i], _devTypes[i]);
        });
  }

  Widget _buildRow(String dev, String devType) {
    print("In _buildRow() function");
    return ListTile(
        title: Text(
          dev + ' -- ' + devType,
          style: TextStyle(fontSize: 20.0),
        ),
        onTap: () {
          _showDev(dev, devType);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiss-Light App'),
      ),
      body: _buildList(),
    );
  }

  void _showDev(String devName, String devType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DevPage(
          devName: devName,
          devType: devType,
          ip: widget.ip,
          port: widget.port,
        ),
      ),
    );
  }
}

/* Device State Change page */
class DevPage extends StatefulWidget {
  final String devName;
  final String devType;
  final String ip;
  final int port;

  DevPage(
      {Key key,
      @required this.devName,
      @required this.devType,
      @required this.ip,
      @required this.port})
      : super(key: key);

  @override
  _DevPageState createState() => _DevPageState();
}

/* the state for the setup page */
class _DevPageState extends State<DevPage> {
  @override
  Widget build(BuildContext context) {
    final toggleOutletButton = ButtonTheme(
      //height: 60,
      child: ElevatedButton(
        onPressed: () async {
          String msg = 'TOGGLE ' +
              widget.devName +
              ' KL/' +
              _klversion.toString() +
              '\n';

          /* send request */
          _sendRequest(widget.ip, widget.port, msg);
        },
        child:
            Text('toggle', style: TextStyle(color: Colors.white, fontSize: 32)),
        style: ElevatedButton.styleFrom(
          onPrimary: Colors.white,
          primary: Colors.purple,
          minimumSize: Size(250, 250),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.devName),
      ),
      body: Center(
        child: toggleOutletButton,
      ),
    );
  }
}

