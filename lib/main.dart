import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = BarcodeScannerScreen();
        break;
      case 1:
        page = PlaceholderWidget(pageName: 'Books Page');
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      body: page,
      bottomNavigationBar: HomePageBottomBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              selectedIndex = index;
            });
          }),
    );
  }
}

class HomePageBottomBar extends StatelessWidget {
  const HomePageBottomBar(
      {super.key,
      required this.selectedIndex,
      required this.onDestinationSelected});

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: onDestinationSelected,
      selectedIndex: selectedIndex,
      destinations: [
        NavigationDestination(icon: Icon(Icons.barcode_reader), label: 'read'),
        NavigationDestination(
            icon: Icon(Icons.my_library_books), label: 'books'),
      ],
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final Map<String, String?> _scannedBooks = {};
  final Set<String> _processingBarcodes = {};

  Future<Book> _fetchBook({required String barcode}) async {
    final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$barcode';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Book.fromJson(json);
    } else {
      print('API Error: ${response.statusCode}, Body: ${response.body}');
      throw Exception(
          'Failed to load book data. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: MobileScanner(
                onDetect: (capture) async {
                  final List<Barcode> detectedBarcodes = capture.barcodes;
                  for (final barcode in detectedBarcodes) {
                    final barcodeString = barcode.rawValue;
                    if (barcodeString != null &&
                        !_scannedBooks.containsKey(barcodeString) &&
                        !_processingBarcodes.contains(barcodeString)) {
                      setState(() {
                        _processingBarcodes.add(barcodeString);
                        _scannedBooks[barcodeString] =
                            '$barcodeString (検索中...)';
                      });

                      try {
                        final book = await _fetchBook(barcode: barcodeString);
                        setState(() {
                          _scannedBooks[barcodeString] = book.title;
                          _processingBarcodes.remove(barcodeString);
                        });
                      } catch (e) {
                        print('書籍情報の取得に失敗: $e');
                        setState(() {
                          _scannedBooks[barcodeString] = '取得失敗';
                          _processingBarcodes.remove(barcodeString);
                        });
                      }
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: ListView(
                children: _scannedBooks.entries.map((entry) {
                  final barcodeValue = entry.key;
                  final bookTitle = entry.value;
                  return ListTile(
                    title: Text(bookTitle ?? 'タイトル不明'),
                    subtitle: Text('ISBN: $barcodeValue'),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key, required this.pageName});

  final String pageName;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(pageName));
  }
}

class Book {
  final String title;

  const Book({required this.title});

  factory Book.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>?;

    if (items != null && items.isNotEmpty) {
      final bookInfo = items.first as Map<String, dynamic>?;
      if (bookInfo != null) {
        final volumeInfo = bookInfo['volumeInfo'] as Map<String, dynamic>?;
        if (volumeInfo != null) {
          final title = volumeInfo['title'] as String? ?? 'タイトルなし';
          return Book(title: title);
        }
      }
    }
    return Book(title: 'タイトルなし');
  }
}
