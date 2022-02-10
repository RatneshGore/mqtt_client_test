import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String status = "";
  String status2 = "";
  bool isConnected = false;
  final ipController = TextEditingController();
  final portController = TextEditingController();

  void updateState() {
    setState(() {
      String port = portController.text;
      String ip = ipController.text;
      if (isConnected) {
        if (port.isNotEmpty) {
          client.subscribe(port, MqttQos.atLeastOnce);
          print(' >> Subscribing to topic: $port');
        }
      } else {
        /*if(ip.isEmpty){
          printS(" Please enter URL or IP");
          return;
        }*/
        ip = ipController.text;
        port = portController.text;
        connect(ip, port);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal),
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                        controller: ipController,
                        decoration: InputDecoration(
                            hintText: isConnected
                                ? "Message Publish"
                                : "url or local Ip")),
                  ),
                  if (isConnected)
                    TextButton(
                      onPressed: sendMessage,
                      child: Text("Publish"),
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.black87),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered))
                              return Colors.blue.withOpacity(0.04);
                            if (states.contains(MaterialState.focused) ||
                                states.contains(MaterialState.pressed))
                              return Colors.blue.withOpacity(0.12);
                            return null; // Defer to the widget's default.
                          },
                        ),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green),
                      ),
                    )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: portController,
                      maxLength: isConnected ? 12 : 4,
                      decoration: InputDecoration(
                          hintText: isConnected ? "Topic" : "port"),
                      //keyboardType: TextInputType.number,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: updateState,
                    child: Text(isConnected ? "Subscribe" : "Connect"),
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black87),
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered))
                            return Colors.blue.withOpacity(0.04);
                          if (states.contains(MaterialState.focused) ||
                              states.contains(MaterialState.pressed))
                            return Colors.blue.withOpacity(0.12);
                          return null; // Defer to the widget's default.
                        },
                      ),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                  )
                ],
              ),
              Text(
                ' $status2 ',
                style: Theme.of(context).textTheme.bodyText1,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    'Message Received \n $status ',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  late MqttServerClient client;

  Future<MqttServerClient> connect(String ip, String port) async {
    print("Connection Start");

    client = MqttServerClient.withPort("192.168.0.6", 'exo_client', port.isNotEmpty ? int.parse(port) : 1883);
    //client = MqttServerClient.withPort(ip , 'flutter_client', port.isNotEmpty ? int.parse(port) :1883);
    status2 = "conecting with $ip & $port with client-> exo_client";
    client.logging(on: true);

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.keepAlivePeriod = 180;

    final connMessage = MqttConnectMessage()
        .authenticateAs('username', 'password')
        .withWillTopic('home2')
        .withWillMessage('Will message2')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      print('Exception>>>>: $e');
      client.disconnect();
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      String topic = c[0].topic;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      //_messagesController!.add(PayloadWithTopic(payload: payload, topic: topic));
      setState(() {
        status += 'Received :$payload from topic: ${c[0].topic}>\n';
      });
    });

    return client;
  }

// connection succeeded
  void onConnected() {
    client.subscribe("home", MqttQos.atLeastOnce);
    setState(() {
      isConnected = true;
      portController.text = "";
      ipController.text = "";
    });
  }

// unconnected
  void onDisconnected() {
    printS('Disconnected');
    setState(() {
      isConnected = false;
      ipController.text = "";
      portController.text = "";
    });
  }

// subscribe to topic succeeded
  void onSubscribed(String topic) {
    printS('Subscribed topic: $topic');
  }

// subscribe to topic failed
  void onSubscribeFail(String topic) {
    printS('Failed to subscribe $topic');
  }

// unsubscribe succeeded
  void onUnsubscribed(String? topic) {
    printS('Unsubscribed topic: $topic');
  }

  //auto reconnect
  void onAutoReconnect() {
    printS('Auto Reconnect');
  }

// PING response received
  void pong() {
    printS('Ping response client callback invoked');
  }

  void sendMessage() {
    if (!isConnected) return;
    final pubTopic =
        portController.text.isNotEmpty ? portController.text : 'topic/test';
    final builder = MqttClientPayloadBuilder();
    builder.addString('${ipController.text} TST');
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload!);
    printS("Publishing ${ipController.text} TST $pubTopic");
  }

  void printS(String message) {
    print(message);
    setState(() {
      status2 = message;
    });
  }
}

class ButtonGreen extends TextButton {
  ButtonGreen({required VoidCallback? onPressed, required Widget child}) : super(onPressed: onPressed, child: child);

}

