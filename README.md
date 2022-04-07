<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

A package which allow developers to develop the shiSock client for the there flutter android app. Using `flutter-shiSock` developers can develop a chat application very easily. It can also be used in app in which we need real time data flow.

## Features

It is easy to settup.

It can be used for different kinds of applications like chat, weather forecast, etc.

shiSock Engine has very low letency while handling millions of concurrent users.

## Getting started

Run these command according to your environment.

With Dart:
```dart
$ dart pub add flutter_shisock
```

With Flutter:

Run this command in temrinal from the root of your project
```dart
$ flutter pub add flutter_shiSock
```

OR:

You can also directly add this line into you project's pubspec.yml file in dependencies section
```dart
    dependencies:
        flutter_shiSock: ^1.0.0
```

## Usage

A example minimilistic chat application.


In this example, in case you shiSock Engine and server is running in localhost then localhost for android emulator would be `10.0.2.2`. Our in case shiSock Engine is running in cloud then you have to provide the public ip of device on which the Engine is running.


```dart
import 'package:flutter/material.dart';
import 'package:shisock_flutter/shisock_flutter.dart';

// main function or the starting point
void main() {
  runApp(MyApp());
}


// The main class for the flutter application and it is the root 
// of you application.
class MyApp extends StatelessWidget {

  // The declaration and initialisation of the shiSockClient object.
  ShiSockClient client = ShiSockClient();

  // If running on Android Emulator, 10.0.2.2 will the localhost
  String address = "10.0.2.2";
  int port = 8080;

  // shiSockListener object which will be used later in the application,
  // that's why it declared using late keyword.
  late ShiSockListener shiSock;

  // The construction of class. It is used to initialise the shiSock variable.
  MyApp({Key? key}) : super(key: key) {

    // Initialisation of shiSock variable using client' connect function.
    // connect function return a shiSockListener object.
    shiSock = client.connect(address, port);
  }

  // Root build function of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(shiSock: shiSock),
    );
  }
}

// A stateful widget class becouse there will the changes in the application UI
// on the fly.
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.shiSock}) : super(key: key);
  final ShiSockListener shiSock;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// A simple UI class.
class _MyHomePageState extends State<MyHomePage> {
  final myController = TextEditingController();
  List<Map<String, String>> msg = [];
  void listener() {
    widget.shiSock.listen("main", (data, sender) {
      setState(() {
        msg.add(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    listener();
    return Scaffold(
      appBar: AppBar(
        title: const Text("shiSock Test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 9,
              child: ListView.builder(
                itemCount: msg.length,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  String data = msg[index]["data"] ?? "";
                  String dt = msg[index]["datetime"] ?? "";
                  String datetime = dt.substring(0, 19);
                  return Container(
                    decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 211, 220, 215),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    margin: const EdgeInsets.only(
                        top: 2.5, bottom: 2.5, left: 5, right: 5),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      title: Text(data),
                      trailing: Text(datetime,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 192, 48, 217))),
                      textColor: const Color.fromARGB(255, 227, 154, 7),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                      flex: 1,
                      child: FloatingActionButton(
                          onPressed: () {
                            // ignore: avoid_print
                            print("Left Button");
                          },
                          child: const Icon(Icons.emoji_emotions_rounded))),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    flex: 8,
                    child: TextField(
                      controller: myController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20.0))),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(
                    flex: 1,
                    child: FloatingActionButton(
                      onPressed: () {
                        widget.shiSock.send("main", myController.text);
                        myController.clear();
                      },
                      tooltip: 'send the content of text field to the server',
                      child: const Icon(Icons.send),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Additional information

If you need more information then take a look at the shiSock website: `https:shisock.live/flutter_shisock`

If someone wants to contribute to this project then you are very welcome.

If you have any issue/bug with this project then file a issue in the official github repo.

And if anybody wants my help then reach out to me on these social plateforms:

<a target="_blank" href="https://www.linkedin.com/in/shikharyadav10/">
  <img align="left" alt="LinkdeIN" width="22px" src="https://cdn.jsdelivr.net/npm/simple-icons@v3/icons/linkedin.svg" />
</a>

<a target="_blank" href="https://www.instagram.com/_shikhar_10_/">
  <img align="left" alt="Instagram" width="22px" src="https://cdn.jsdelivr.net/npm/simple-icons@v3/icons/instagram.svg" />
</a>

</a>
<a target="_blank" href="yshikharfzd10@gmail.com">
  <img align="left" alt="Gmail" width="22px" padding="20" src="https://cdn.jsdelivr.net/npm/simple-icons@v3/icons/gmail.svg" />
</a>

</br>

<p align="center">
    <code><img height="20" src="https://raw.githubusercontent.com/github/explore/80688e429a7d4ef2fca1e82350fe8e3517d3494d/topics/dart/dart.png"></code>
</p>






