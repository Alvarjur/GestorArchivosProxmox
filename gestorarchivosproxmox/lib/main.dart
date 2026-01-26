import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/widget_previews.dart';
import 'dart:convert'; 
import 'package:flutter/services.dart';

SSHManager sshManager = SSHManager();
bool isConnected = false;
List<ServerInfo> servers = [];

List<FileItem> currentFiles = [];

class FileItem {
  final String name;
  final bool isDirectory;
  final bool isImage;
  FileItem({
    required this.name,
    required this.isDirectory,
    required this.isImage,
  });
}

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

Future<void> getServers() async {
  // 1. Cargar el archivo como String
  final String response = await rootBundle.loadString('assets/json/servers.json');
  List<ServerInfo> _servers = [];
  
  // 2. Decodificar a un Map o List
  final data = jsonDecode(response);
  
  // 3. Convertir a una lista de ServerInfo
  for (var serverJson in data["servers"]) {
    ServerInfo server = ServerInfo.fromJson(serverJson);
    logger.i("Server Name: ${server.name}, IP: ${server.ip}");
    _servers.add(server);
  }
  servers = _servers;
}

class ServerInfo {
  final String name;
  final String ip;
  final int port;
  final String username;
  final String key;

  ServerInfo({
    required this.name,
    required this.ip,
    required this.port,
    required this.username,
    required this.key,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      name: json['name'],
      ip: json['host'],
      port: json['port'],
      username: json['username'],
      key: json['key'],
    );
  }
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

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'File Manager'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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
    _loadServers();
  }

  void _loadServers() async {
    await getServers();
    setState(() {});
  }

  void _getCurrentFiles(String route) async {
    await sshManager.listFiles(route);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String currentUsername = "aarmasjurado";
    String currentIP = "ieticloudpro.ieti.cat";
    String currentKey = "id_rsa";
    int currentPort = 20127;
    Color connectedColor = Colors.lightGreen;
    Color disconnectedColor = Colors.redAccent;
    Color connectionColor = disconnectedColor;

    
    
    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        
      ),
      body: Center(
        child: Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    //  Visualización
    Expanded(
      flex: 1, 
      child: Container(
        color: Colors.blueGrey[900],
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Expanded(
                child: ListView.builder(
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  return ListTile(
                    title: Text(server.name, style: const TextStyle(color: Colors.white),),
                    subtitle: Text(server.ip, style: const TextStyle(color: Colors.white70),),
                    onTap: () {
                      setState(() {
                        _userController.text = server.username;
                        _hostController.text = server.ip;
                        _portController.text = server.port.toString();
                        _keyController.text = server.key;
                      });
                      },
                  );
                },
              ),
              )
              
              
              
            ],
          ),
        ),
      ),
    ),

    // Configuración
    Expanded(
      flex: 1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configuración SSH",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onChanged: (value) => currentUsername = value,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Host',
                prefixIcon: Icon(Icons.language),
              ),
              onChanged: (value) => currentIP = value,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Port',
                prefixIcon: Icon(Icons.numbers),
              ),
              onChanged: (value) => currentPort = int.tryParse(value) ?? 22,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _keyController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Key',
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              
              child: ElevatedButton.icon(
                  
                icon: const Icon(Icons.link),
                label: const Text('Connect'),
                onPressed: () async {
                    bool success = await sshManager.connect(
                      _userController.text, 
                      _hostController.text, 
                      int.tryParse(_portController.text) ?? 22, 
                      _keyController.text
                    );
                    

                    if (success && mounted) {
                      await sshManager.listFiles("/");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FileExplorerPage(manager: sshManager),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Error al conectar")),
                      );
                    }
                  },
              ),
            ),
          ],
        ),
      ),
    ),
  ],
)
      ),
    );
  }
}

class SSHManager {
  SSHClient? _client;
  bool _shouldReconnect = true;

  Future<bool> connect(String username, String ip, int port, String key) async {
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
    isConnected = true;
    return true; // Éxito en la conexión inicial
  } catch (e) {
    logger.e("Connection error: $e");
    return false; // Fallo
  }
}

  Future<void> listFiles(String path) async {
  if (_client == null) return;

  try {
    // 1. Iniciar el cliente SFTP
    final sftp = await _client!.sftp();
    
    // 2. Listar el directorio
    final items = await sftp.listdir(path);
    currentFiles.clear();
    for (final item in items) {
      
      logger.i("Nombre: ${item.filename} | Es directorio: ${item.attr.isDirectory}");
      currentFiles.add(FileItem(
        name: item.filename,
        isDirectory: item.attr.isDirectory,
        isImage: (item.filename.endsWith('.png') || item.filename.endsWith('.jpg') || item.filename.endsWith('.jpeg') || item.filename.endsWith('.gif'))
      ));
    }
  } catch (e) {
    logger.e("Error listando archivos: $e");
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

class FileExplorerPage extends StatefulWidget {
  final SSHManager manager;
  const FileExplorerPage({super.key, required this.manager});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  void _navigateTo(String path) async {
    await widget.manager.listFiles(path);
    setState(() {}); // Refrescando vista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Para que se vea el texto blanco
      appBar: AppBar(title: const Text("Servidor Remoto")),
      body: ListView.builder(
        itemCount: currentFiles.length,
        itemBuilder: (context, index) {
          final file = currentFiles[index];
          return ListTile(
            leading: Icon(
              file.isDirectory ? Icons.folder : Icons.insert_drive_file,
              color: file.isDirectory ? Colors.amber : Colors.blueAccent,
            ),
            title: Text(file.name, style: const TextStyle(color: Colors.white)),
            onTap: () {
              if (file.isDirectory) {
                logger.i("Entrando en: ${file.name}");
              }
            },
          );
        },
      ),
    );
  }
}