import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Socket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late IO.Socket socket;
  final StreamController<String> _streamController = StreamController<String>();
  Stream<String> get messagesStream => _streamController.stream;

  TextEditingController controller = TextEditingController();
  var usrName='';
  var receivedData='';

  //This will give platofrm specific url for ios and android emulator
  String socketUrl() {
    if (Platform.isAndroid) {
      return "http://192.168.0.107:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    // Connect to the Socket.IO server
    socket = IO.io(socketUrl(), <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to server');
    });

    // Listen for messages from the server
    socket.on('newmsg', (data) {
      print(data['user']);
      print(data['message']);
      setState(() {
          controller.text='';
          receivedData+="\n${data['user']}: ${data['message']}";

      });
    });

    // Listen for response from the server
    socket.on('userExists', (data) {
      print('$data');
      Fluttertoast.showToast(
          msg: "$data",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
      setState(() {
        controller.text='';
        usrName='';
      });
    });

    socket.on('userSet', (data){
      print(data['username']);
      setState(() {
        controller.text='';
        usrName=data['username'];
      });
    });
  }

  @override
  void dispose() {
    // Disconnect from the Socket.IO server when the app is disposed
    socket.disconnect();

    //close stream
    _streamController.close();
    super.dispose();
  }

  void sendMessage(String message) {
    // Send a message to the server
    socket.emit('msg', {'message': message, 'user': usrName});
  }

  void setUserName(String usrName) {
    // Send a username to the server
    socket.emit('setUsername', usrName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socket.IO Flutter and ExpressJS'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(hintText: usrName==''?"Enter your new username":"Enter Message"),
              ),
            ),
            TextButton(onPressed: () {
              if (socket.connected) {
                usrName==''?setUserName(controller.text):sendMessage(controller.text);
              }
            },child: Text(usrName==''?'Let me chat':'send'),),
            const SizedBox(height: 40),
            Text('$receivedData')
          ],
        ),
      ),
    );
  }
}
