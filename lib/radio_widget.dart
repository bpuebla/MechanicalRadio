import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'text_form.dart';
import 'dart:async';
import 'web.dart';

/// Stateless widget that builds the body of the radio, provided the news.
class RadioWidget extends StatefulWidget {
  const RadioWidget({Key? key, required this.newsFromHome}) : super(key: key);

  final Map newsFromHome;

  @override
  State<RadioWidget> createState() => _RadioWidgetState();
}

class _RadioWidgetState extends State<RadioWidget> {
  /// Map of the news read on the radio.
  late Map news;

  /// Decoration image
  Image mesh = Image.network(
    'https://media.istockphoto.com/photos/metal-grille-over-speakers-picture-id182187519?k=20&m=182187519&s=612x612&w=0&h=BjMrjxZk8LdUyKHSNZ1G5bSVbs6lm8zXRKIgl_kcZeY=',
  );

  String radioText = ''; // Read by the TTS
  late Timer timer; // Periodic timer for exec. of radio
  FlutterTts flutterTts = FlutterTts(); // Text To Speech

  bool _isPlaying = false; // Indicates if radio is playing
  bool _audioPlayed = false; // Used for pausing, deprecated.
  AudioPlayer player = AudioPlayer(); // Player for background music
  var topicText; // Stores text on topic form
  var cityText; // Stores text from city form

  // Storing forms, see createForms()
  var itemForm;
  var cityForm;
  var totalForm;

  bool topicPlayed = false;
  bool weatherPlayed =
      false; // Indicates if weather has been played in the last 5 minutes

  // Indicates if weather or topic info is being updated
  bool _updatingCity = false;
  bool _updatingTopic = false;

  // Indexes for news articles
  num localIndex = 0;
  num worldIndex = 0;
  // Index for news option
  int count = 0;

  // Writes the news from the args to its variable, creates forms and initializes the text to speech.
  @override
  initState() {
    news = widget.newsFromHome;
    super.initState();
    createForms();
    flutterTts.setLanguage("en-US");
    flutterTts
        .awaitSpeakCompletion(true); // speak() returns once speech is completed
    flutterTts.speak(''); // initializing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Center(
          child: ListView(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: mesh,
                ),
                width: 350,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                totalForm,
                buttonChild(context),
              ]),
            ],
          ),
        ));
  }

  /// Builds the Button Widget with its styling, or the Progress Indicator if it is updating.
  Widget buttonChild(context) {
    if (_updatingCity || _updatingTopic) {
      return CircularProgressIndicator();
    } else {
      return ElevatedButton(
          style: ElevatedButton.styleFrom(
            side: BorderSide(),
            primary: Colors.grey,
            onPrimary: Colors.black,
            shadowColor: Colors.white,
            elevation: 5,
            shape: const CircleBorder(),
            minimumSize: const Size(70, 70),
          ),
          onPressed: _togglePlaying,
          child: (_isPlaying
              ? const Icon(Icons.pause, size: 40)
              : const Icon(Icons.play_arrow, size: 40)));
    }
  }

  Timer weatherTimer() => //  Creates a weather 5 minute timer
      Timer(const Duration(minutes: 5), () => {switchWeather()});

  Timer topicTimer() => // same but for topic
      Timer(const Duration(minutes: 5), () => {switchTopic()});

  void switchTopic() {
    // Callback for weatherTimer, makes weather readable again
    topicPlayed = false;
  }

  void switchWeather() {
    weatherPlayed = false;
  }

  reduceLocal() {
    // Adds to localIndex and reduces to 0 if the value is over its length.
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

  /// Creates the topic and weather forms, along with a Save button that store their data in its corresponding variables.
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
            // Validates nonEmpty and not null
            formKey.currentState!.save();
          }
        },
        child: const Text('Submit'));

    totalForm = Form(
        // to be appended to body.
        key: formKey,
        child: Column(
          children: [itemForm, cityForm, button],
        ));
  }

  void updateTopic(query) async {
    setState(() {
      _updatingTopic = true;
    });

    news['topic'] = await wikipedia(query); // Retrieves wikipedia topic info
    setState(() {
      _updatingTopic = false;
    });
  }

  void updateCity(query) async {
    // Retrieves all weather info
    setState(() {
      _updatingCity = true;
    });
    news['currweather'] = await getCurrentWeather(query);
    news['dayweather'] = await getDayWeather(query);
    setState(() {
      _updatingCity = false;
    });
  }
  //String cityFormText = cityForm.getCont;

  /// Cancels Timer and its callback, and pauses audio player.
  void disposeTimer() {
    if (timer != null) {
      timer.cancel();
      flutterTts.stop();
      player.pause();
    }
  }

  /// Creates the Timer that periodically reads the next news only if the previous news reading has been finished.
  /// Runs TTS on what is returned by webGet(), and runs the player.
  void periodicInfo() async {
    radioText = webGet(count);
    bool readingCompleted = true;

    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) async {
      //localIndex += 1;
      if (readingCompleted) {
        // Wait until reading is complete
        print(radioText);
        if (_isPlaying) {
          readingCompleted = false;
          player.resume(); // Play selected audio file
          await flutterTts
              .speak(radioText); // Speak text and return when finished
          readingCompleted = true;
        }

        count += 1;
        if (count > 4) {
          //reduce
          count = count % 5;
        }
        radioText = webGet(count); // get next news
      }
    });
  }

  /// Returns the corresponding string for information for the current count (which can only be five cases):
  /// Local news, World news, topic news, current weather or day weather. Checks constraints for each.
  String webGet(item) {
    String information = 'There was an error'; // Default error message
    switch (item) {
      case 0: // Normaly current weather
        if (weatherPlayed) {
          // Weather every 5 min
          player.setSourceAsset(
              "audio/stay_the_course.mp3"); // Sets audio file used
          information = news['world'][worldIndex]; // Retrieve news
          reduceWorld(); // Fix index
        } else {
          player.setSourceAsset("audio/localforecast.mp3");
          information = news['currweather'];
          weatherPlayed = true;
          weatherTimer(); // Starts timer if read
        }
        break;

      case 1: // Normaly local news
        if (news['local'].isNotEmpty) {
          // In some locations, local news are not available
          player.setSourceAsset("audio/smoothlovin.mp3");
          information = news['local'][localIndex];
          reduceLocal();
        } else {
          player.setSourceAsset("audio/stay_the_course.mp3");
          information = news['world'][worldIndex];
          reduceWorld();
        }

        break;
      case 2: // World news
        player.setSourceAsset("audio/stay_the_course.mp3");
        information = news['world'][worldIndex];
        reduceWorld();
        break;
      case 3: // Normally day weather
        if (weatherPlayed) {
          player.setSourceAsset("audio/stay_the_course.mp3");
          information = news['world'][worldIndex];
          reduceWorld();
        } else {
          player.setSourceAsset("audio/springish.mp3");
          information = news['dayweather'];
          weatherPlayed = true;
          weatherTimer();
        }

        break;
      case 4: // Normally topic info
        if (news['topic'] != null && !topicPlayed) {
          player.setSourceAsset("audio/sincerely.mp3");
          information = news['topic'];
          topicPlayed = true;
          topicTimer();
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
      disposeTimer(); // Stops all players
      setState(() {
        // Switch button icon
        _isPlaying = false;
      });
    } else if (!_isPlaying && !_audioPlayed) {
      periodicInfo(); // Start all players
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
