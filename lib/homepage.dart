import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mechanicalradio/info.dart';
import 'text_form.dart';
import 'dart:async';
import 'web.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var news;
  var newsLoaded = false;
  int _selectedIndex = 0;
  bool _disconnected = false;

  @override
  void initState() {
    // audioplay
    //Future.delayed(Duration.zero, () async {
    //  ByteData bytes =
    //      await rootBundle.load(audioasset); //load audio from assets
    //  audiobytes =
    //      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    //  setState(() {});
    //});

    super.initState();
    createNews();
    //timing

    //periodicInfo();
  }

  void createNews() async {
    bool connected = await checkConnection();
    if (connected) {
      news = await fetchAllNews();
      print('fetched all news');
      setState(() {
        newsLoaded = true;
      });
    } else {
      setState(() {
        _disconnected = false;
      });
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

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
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          body: loadingBody);
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: IndexedStack(
        children: [Radio(newsFromHome: news), const InfoPage()],
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
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class Radio extends StatefulWidget {
  const Radio({Key? key, required this.newsFromHome}) : super(key: key);

  final Map newsFromHome;

  @override
  State<Radio> createState() => _RadioState();
}

class _RadioState extends State<Radio> {
  late Map news;
  Image mesh = Image.network(
    'https://st3.depositphotos.com/5970082/14924/i/600/depositphotos_149248824-stock-photo-black-metal-speaker-mesh.jpg',
  );

  String radioText = '';
  var timer;
  FlutterTts flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool _audioPlayed = false;
  AudioPlayer player = AudioPlayer();
  var topicText;
  var cityText;
  var itemForm;
  var cityForm;
  var totalForm;

  @override
  initState() {
    news = widget.newsFromHome;
    super.initState();
    createForms();
    flutterTts.awaitSpeakCompletion(true);
    flutterTts.speak('');
  }

  reduceLocal() {
    localIndex += 1;
    if (localIndex > news['local'].length - 1) {
      //reduce
      localIndex = localIndex % news['local'].length;
    }
  }

  reduceWorld() {
    worldIndex += 1;
    if (worldIndex > news['world'].length - 1) {
      //reduce
      worldIndex = worldIndex % news['world'].length;
    }
  }

  void createForms() {
    final formKey = GlobalKey<FormState>();
    itemForm = MyTextFormField(
        hintText: 'Enter a topic...',
        onSaved: (String? value) {
          updateTopic(value);
          topicText = value;
        });
    cityForm = MyTextFormField(
        hintText: 'Enter a city',
        onSaved: (String? value) {
          updateCity(value);
          cityText = value;
        });

    ElevatedButton button = ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.grey,
          onPrimary: Colors.black,
          shadowColor: Colors.white,
        ),
        onPressed: () {
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
          }
        },
        child: const Text('Save All'));

    totalForm = Form(
        key: formKey,
        child: Column(
          children: [itemForm, cityForm, button],
        ));
  }

  void updateTopic(query) async {
    news['topic'] = await wikipedia(query);
  }

  void updateCity(query) async {
    news['currweather'] = await getCurrentWeather(query);
    news['dayweather'] = await getDayWeather(query);
  }
  //String cityFormText = cityForm.getCont;

  num localIndex = 0;
  num worldIndex = 0;
  var newsLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: mesh,
            ),
            width: 350,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            totalForm,
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey,
                  onPrimary: Colors.black,
                  shadowColor: Colors.white,
                  elevation: 5,
                  shape: const CircleBorder(),
                  minimumSize: const Size(70, 70), //////// HERE
                ),
                onPressed: _togglePlaying,
                child: (_isPlaying
                    ? const Icon(Icons.pause, size: 40)
                    : const Icon(Icons.play_arrow, size: 40))),
          ]),
        ],
      ),
    ));
  }

  void disposeTimer() {
    if (timer != null) {
      timer.cancel();
      flutterTts.stop();
      player.pause();
    }
  }

  play(text) async {
    final completer = Completer<void>();
    await flutterTts.speak(text);
    flutterTts.setCompletionHandler(() {
      completer.complete();
    });
    return completer.future;
  }

  // webget
  void periodicInfo() async {
    radioText = webGet(0);
    int count = 0;
    bool readingCompleted = true;

    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
      //localIndex += 1;
      if (readingCompleted) {
        print(radioText);
        if (_isPlaying) {
          readingCompleted = false;
          player.resume();
          await flutterTts.speak(radioText);
          readingCompleted = true;
          //not working, crashes
        }

        count += 1;
        if (count > 4) {
          //reduce
          count = count % 5;
        }
        print(worldIndex);
        radioText = webGet(count);
      }
    });
  }

  //String getNews(item, index) {}

  String webGet(item) {
    String information = 'There was an error';
    switch (item) {
      case 0:
        player.setSourceAsset("audio/localforecast.mp3");
        information = news['currweather'];
        break;
      case 1:
        if (news['local'].isNotEmpty) {
          player.setSourceAsset("audio/smoothlovin.mp3");
          information = news['local'][localIndex];
          reduceLocal();
        } else {
          player.setSourceAsset("audio/stay_the_course.mp3");
          information = news['world'][worldIndex];
          reduceWorld();
        }

        break;
      case 2:
        player.setSourceAsset("audio/stay_the_course.mp3");
        information = news['world'][worldIndex];
        reduceWorld();
        break;
      case 3:
        player.setSourceAsset("audio/springish.mp3");
        information = news['dayweather'];
        break;
      case 4:
        if (news['topic'] != null) {
          player.setSourceAsset("audio/springish.mp3");
          information = news['topic'];
        } else {
          // if no topic give more world news
          player.setSourceAsset("audio/stay_the_course.mp3");
          information = news['world'][worldIndex];
          reduceWorld();
        }
        break;
    }

    return information;
  }

  // player
  void _togglePlaying() async {
    if (_isPlaying && _audioPlayed) {
      disposeTimer();
      setState(() {
        _isPlaying = false;
      });
    } else if (!_isPlaying && !_audioPlayed) {
      periodicInfo();
      setState(() {
        _isPlaying = true;
        _audioPlayed = true;
      });
    } else {
      periodicInfo();
      setState(() {
        _isPlaying = true;
      });
    }
  }
}
