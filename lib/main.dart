import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var count = 0;
  var current = WordPair.random();

  void getNext() {
    count++;
    current = WordPair.random();
    notifyListeners();
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
    var appState = context.watch<MyAppState>();
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePageBody(appState: appState);
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

class HomePageBody extends StatelessWidget {
  const HomePageBody({
    super.key,
    required this.appState,
  });

  final MyAppState appState;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('A random AWESOME idea:'),
          Text(appState.current.asLowerCase),
          Text(appState.count.toString()),
          ElevatedButton(
            onPressed: () {
              appState.getNext();
            },
            child: Text('Next'),
          )
        ],
      ),
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

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key, required this.pageName});

  final String pageName;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(pageName));
  }
}
