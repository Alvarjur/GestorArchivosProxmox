import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

SSHManager sshManager = SSHManager();

var logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,       // Number of method calls to be displayed
    errorMethodCount: 8,  // Number of method calls if stacktrace is provided
    lineLength: 120,      // Width of the output
    colors: true,         // Colorful log messages
    printEmojis: true,    // Print an emoji for each log message
  ),
);

void main() {
  
  runApp(const MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'File Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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
  late TextEditingController _userController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController(text: "aarmasjurado");
    _hostController = TextEditingController(text: "ieticloudpro.ieti.cat");
    _portController = TextEditingController(text: "20127");
    _keyController = TextEditingController(text: "id_rsa");
  }

  @override
  Widget build(BuildContext context) {
    String currentUsername = "aarmasjurado";
    String currentIP = "ieticloudpro.ieti.cat";
    String currentKey = "id_rsa";
    int currentPort = 20127;

    
    
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Column(
              children: [
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                  ),
                  
                  onChanged:(value) => currentUsername = value,
                ),
              
              
                TextField(
                  controller: _hostController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Host',
                  ),
                  
                  onChanged:(value) => currentIP = value,
                ),

                

                TextField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Port',
                  ),
                  onChanged:(value) => currentPort = int.parse(value),
                ),
                

                
                TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Key',
                  ),
                ),
                
                

                ElevatedButton(
                  onPressed: () {
                    // Handle connection logic here
                    logger.i("Trying connection...");
                    sshManager.connect(currentUsername, currentIP, currentPort, currentKey);

                  },
                  child: const Text('Connect'),
                ),


            ],
            
            ),

            
            
          ],
          
        ),
      ),
    );
  }
}

class SSHManager {
  SSHClient? _client;
  bool _shouldReconnect = true;

  Future<void> connect(String username, String ip, int port, String key) async  {
    while (_shouldReconnect) {
      try {

        logger.i("Attempting to connect to $ip:$port");
        final socket = await SSHSocket.connect(ip, port);
        

        _client = SSHClient(
          socket,
          username: username,
          keepAliveInterval: const Duration(seconds: 30),
          identities: [
            ...SSHKeyPair.fromPem(await getPrivateKey(key)),
          ]
        );

        logger.i("Connected to $ip:$port");

        await _client!.done;
        logger.w("Connection to $ip:$port closed. Reconnecting...");


      } catch (e) {
        logger.e("Connection error: $e");
      }
    }
  }

  Future<String> getPrivateKey(String file) async {
    String home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;

    String keyPath = p.join(home, '.ssh', file);

    File keyFile = File(keyPath);

    if (await keyFile.exists()) {
      return await keyFile.readAsString();
    } else {
      throw Exception("Private key file not found: $keyPath");
    }
  }
}