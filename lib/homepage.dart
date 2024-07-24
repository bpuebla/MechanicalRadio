import 'package:flutter/material.dart';
import 'package:mechanicalradio/info.dart';
import 'dart:async';
import 'web.dart';
import 'dart:io';
import 'radio_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// Map of the news read on the radio.
  late Map news;
  bool newsLoaded = false; // whether news have finished loading.
  int _selectedIndex = 0; // selected tab on the navigation bar.
  bool _disconnected =
      false; // Indicates whether there is internet connection or not.

  // Rendering
  Center loadingBody = Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
        Padding(
            padding: EdgeInsets.all(12.0), child: CircularProgressIndicator()),
        Text("Loading"),
      ]));

  @override
  Widget build(BuildContext context) {
    if (_disconnected) {
      // Disconnected page
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                Text("Could not connect to network.",
                    style: Theme.of(context).textTheme.headline6),
              ])));
    }
    if (!newsLoaded) {
      // Loading page
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: loadingBody);
    }
    return WillPopScope(
        // callback when back button is pressed
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: IndexedStack(
            // better than routes for bottomnavigationbar
            children: [
              RadioWidget(newsFromHome: news),
              const InfoPage()
            ], // Pages
            index: _selectedIndex,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.radio),
                label: 'Radio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.info),
                label: 'Info',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (int index) {
              setState(() {
                // Used to switch pages
                _selectedIndex = index;
              });
            },
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    createNews(); // Fetches news using scraping functions
  }

  /// Runs checkConnection and gets news if true.
  void createNews() async {
    bool connected = await checkConnection();
    if (connected) {
      news = await fetchAllNews();
      print('fetched all news');
      setState(() {
        newsLoaded = true; // Switches loading screen
      });
    } else {
      setState(() {
        _disconnected = false;
      });
    }
  }

  /// Tests a site lookup to confirm internet connection
  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // true if connection
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  /// Avoids quitting when back button is pressed.
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0; // switches page to radio
      });
      return false;
    } else {
      // quit if on homepage
      return true;
    }
  }
}
