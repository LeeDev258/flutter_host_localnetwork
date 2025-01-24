import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:archive/archive_io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  String currentStatus = 'Not started';

  HttpServer? _server;
  get server => _server;
  set server(value) => _server = value;

  StreamController<String> stcDetails = StreamController();
  StreamController<String> stcCurrentStatus = StreamController();

  Future<void> downloadFile(String fileId) async {
    final url = 'https://drive.google.com/uc?export=download&id=$fileId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var path = await getDownloadsDirectory();
      final file = File('${path!.path}/file_name.extension');
      await file.writeAsBytes(response.bodyBytes);
      print('Download complete: ${file.path}');
    } else {
      print('Failed to download file. Status: ${response.statusCode}');
    }
  }

  void _incrementCounter() async {
    if (!Platform.isMacOS) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        print("Permission granted");
      } else {
        print("Permission denied");
      }
    }
    // downloadFile('1nojFYmlAhTYHbeY2UJpQSHYU0PRLnZwi');
    await downloadAndUnzip('1nojFYmlAhTYHbeY2UJpQSHYU0PRLnZwi');
    // await createDirectory();
    await runLacalServer();
    // var server = await HttpServer.bind(
    //   InternetAddress.anyIPv4, // เปิดให้เข้าถึงจากเครือข่ายเดียวกัน
    //   8080, // พอร์ตสำหรับเซิร์ฟเวอร์
    // );
    // print('Server running at http://${server.address.address}:${server.port}/');

    // await for (HttpRequest request in server) {
    //   request.response
    //     ..headers.contentType = ContentType.text
    //     ..write('Hello from Flutter!')
    //     ..close();
    // }
  }

  Future<void> createDirectory() async {
    final directory = Directory('/storage/emulated/0/Android/data/com.example.test_host_localnetwork/files/downloads/web');
    if (await directory.exists() == false) {
      await directory.create(recursive: true);
      print('Directory created!');
    }
  }

  Future<void> runLacalServer() async {
    stcCurrentStatus.add('RunServer');
    // โฟลเดอร์ที่เก็บไฟล์ Flutter Web
    final tempDir = await getApplicationDocumentsDirectory(); // โฟลเดอร์ชั่วคราว
    final zipFilePath = '${tempDir.path}/downloaded_file.zip';
    final outputDirPath = '${tempDir.path}/unzipped_files';
    final directory = await getDownloadsDirectory();
    final webDir = '${tempDir.path}/unzipped_files/web'; // เส้นทางไปยังโฟลเดอร์ build/web

    // ใช้ shelf_static ให้บริการไฟล์จากโฟลเดอร์
    var handler = createStaticHandler(webDir, defaultDocument: 'index.html');

    // รันเซิร์ฟเวอร์เพื่อให้บริการไฟล์
    await server?.close();
    server = await shelf_io.serve(handler, '0.0.0.0', 8080);
    stcDetails.add('Server running at http://${server.address.address}:${server.port}/');
  }

  Future<void> stopServer() async {
    stcCurrentStatus.add('StopServer');
    stcDetails.add('StopServer start');
    await server?.close();
    stcDetails.add('StopServer complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StreamBuilder<String>(
                stream: stcCurrentStatus.stream,
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? currentStatus,
                  );
                }),
            StreamBuilder<String>(
                stream: stcDetails.stream,
                builder: (context, snapshot) {
                  return Visibility(
                    visible: snapshot.hasData,
                    child: Text(
                      snapshot.data ?? '',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _incrementCounter,
            child: Container(
              width: 200,
              height: 50,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Icon(Icons.satellite_alt_rounded),
                SizedBox(width: 10),
                Text('Start Server'),
              ]),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: stopServer,
            child: Container(
              width: 200,
              height: 50,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Icon(Icons.stop_rounded),
                SizedBox(width: 10),
                Text('Stop Server'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> downloadAndUnzip(String fileId) async {
    stcCurrentStatus.add('DownloadAndUnzip');
    final downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    // final downloadUrl = 'https://www.dropbox.com/scl/fi/tpx6vem3iojmnlx1o74zs/test_host_localnetwork.zip?rlkey=k7kj7mzmtqmox0twg3wq1p1d9&st=lnsqyj35&dl=1';
    final tempDir = await getApplicationDocumentsDirectory(); // โฟลเดอร์ชั่วคราว
    final zipFilePath = '${tempDir.path}/downloaded_file.zip';
    final outputDirPath = '${tempDir.path}/unzipped_files';

    try {
      // 1. ดาวน์โหลดไฟล์ .zip
      print('Downloading file...');
      stcDetails.add('Downloading file...');
      var response = await Dio().download(downloadUrl, zipFilePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          var percentage = 'Progress: ${(received / total * 100).toStringAsFixed(0)}%';
          print(percentage);
          stcDetails.add(percentage);
        }
      });
      print('Download complete: $zipFilePath');
      stcDetails.add('Download complete: $zipFilePath');

      // 2. แตกไฟล์ .zip
      print('Unzipping file...');
      stcDetails.add('Unzipping file...');
      final zipFile = File(zipFilePath);
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filePath = '$outputDirPath/${file.name}';
        if (file.isFile) {
          final output = File(filePath);
          await output.create(recursive: true);
          await output.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
      print('Unzip complete. Files extracted to: $outputDirPath');
      stcDetails.add('Unzip complete. Files extracted to: $outputDirPath');
    } catch (e) {
      print('Error: $e');
    } finally {
      // คุณสามารถลบไฟล์ zip หลังเสร็จงานถ้าต้องการ
      final zipFile = File(zipFilePath);
      if (await zipFile.exists()) {
        await zipFile.delete();
        print('Temporary zip file deleted.');
        stcDetails.add('Temporary zip file deleted.');
      }
    }
  }
}
