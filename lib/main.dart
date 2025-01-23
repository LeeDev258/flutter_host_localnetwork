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
    // downloadFile('1nojFYmlAhTYHbeY2UJpQSHYU0PRLnZwi');
    await downloadAndUnzip('1nojFYmlAhTYHbeY2UJpQSHYU0PRLnZwi');
    // if (await Permission.manageExternalStorage.request().isGranted) {
    //   print("Permission granted");
    // } else {
    //   print("Permission denied");
    // }
    // await createDirectory();
    // await runLacalServer();
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
    // โฟลเดอร์ที่เก็บไฟล์ Flutter Web
    final directory = await getDownloadsDirectory();
    final webDir = directory; // เส้นทางไปยังโฟลเดอร์ build/web

    // ใช้ shelf_static ให้บริการไฟล์จากโฟลเดอร์
    var handler = createStaticHandler('${webDir!.path}/web', defaultDocument: 'index.html');

    // รันเซิร์ฟเวอร์เพื่อให้บริการไฟล์
    await shelf_io.serve(handler, '0.0.0.0', 2324);
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '5555 test local network',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> downloadAndUnzip(String fileId) async {
  // final downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
  final downloadUrl = 'https://www.dropbox.com/scl/fi/tpx6vem3iojmnlx1o74zs/test_host_localnetwork.zip?rlkey=k7kj7mzmtqmox0twg3wq1p1d9&st=lnsqyj35&dl=1';
  final tempDir = await getDownloadsDirectory(); // โฟลเดอร์ชั่วคราว
  final zipFilePath = '${tempDir!.path}/downloaded_file.zip';
  final outputDirPath = '${tempDir.path}/unzipped_files';

  try {
    // 1. ดาวน์โหลดไฟล์ .zip
    print('Downloading file...');
    var response = await Dio().download(downloadUrl, zipFilePath, onReceiveProgress: (received, total) {
      if (total != -1) {
        print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
      }
    });
    print('Download complete: $zipFilePath');

    // 2. แตกไฟล์ .zip
    print('Unzipping file...');
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
  } catch (e) {
    print('Error: $e');
  } finally {
    // คุณสามารถลบไฟล์ zip หลังเสร็จงานถ้าต้องการ
    final zipFile = File(zipFilePath);
    if (await zipFile.exists()) {
      await zipFile.delete();
      print('Temporary zip file deleted.');
    }
  }
}
