import 'package:flutter/material.dart';
import 'palette.dart';
import 'info.dart';
import 'homepage.dart';

const pages = [MyHomePage(title: 'Mechanical Radio'), InfoPage()];
void main() {
  runApp(const App());
}

/// Builds the Mechanical Radio App as a Material App.
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // Root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mechanical Radio',
      /* Uses Roboto Regular font, with black background and white text */
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Color.fromARGB(255, 24, 24, 24),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color.fromARGB(255, 202, 218, 222),
              //displayColor: const Color.fromARGB(255, 202, 218, 222),
            ),
        primarySwatch: Palette.greenTone,
      ),
      initialRoute: '/home',
      routes: {
        // Named routes. Not used in the end (see IndexedStack).
        '/home': (context) => pages[0],
      },
    );
  }
}
