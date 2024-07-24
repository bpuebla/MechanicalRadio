# mechanicalradio

## Objective

The objective of the project is to develop a working radio that produces endless audio stream consisting on general news, specific news about an inputted keyword and music that fits the theme.

-	Elaborate the mobile app structure with Flutter
-	Implement techniques on web scraping to extract data from news sites, Wikipedia (from keyword) and weather
-	Parsing through the data to obtain readable text.
-	Automatic deduction of a music genre from keyword and from text.
-	Obtainment of a clip from an open music library with the genre
-	Transformation of text to a clip of speech
-	Joining of both clips and presentation on the app



---
## Documentation
### App (main.dart)

Stateless widget that builds the Mechanical Radio App as a Material App.
##### Methods
- build(context) : overrides the main build and returns a Material App. On theme it is specified the use of the Roboto font, along with dark background and clear text. Incorporates for everything else (such as app bar) a custom palette with greyblue tones.

### MyHomepage (homepage.dart)

Stateful widget that builds the template for the pages.
#### Variables
- news : Contains the news Map from local, world and weather sources, and topic information.
- newsLoaded : Indicates whether news have finished loading.
- _selectedIndex : Indicates the selected tab on the navigation bar.
- _disconnected : Indicates whether there is internet connection or not.
- loadingBody : Body widget for the loading screen.

#### Methods
- build(context) : Returns a Scaffold with the AppBar on top displaying the title (Mechanical Radio), the page on index from IndexedStack, and the BottomNavigationBar with two items: Radio and Info.
- initState() : Executes createNews() on app start.
- createNews() : Runs checkConnection and gets news if true.
- checkConnection() : Tests a site lookup to confirm internet connection
- _onWillPop() : Avoids quitting when back button is pressed.


### Radio (radio_widget.dart)

Stateful widget that builds the body of the radio, provided the news. Allows for the user to select a topic and city, and get news with it in audio form.

#### Variables 
- news : Map of the news read on the radio.
- mesh : Decoration image
- radioText : String read by the TTS
- timer : Periodic timer for execution of radio
- flutterTts : Text to speech object.
- _isPlaying : Indicates if radio is playing
- player : Audioplayer for background music
- topicText : Text stored from forms
- cityText
- itemForm, cityForm, totalForm : Stored form widgets, see createForms()
- topicPlayed, weatherPlayed: Boolean indicating if played in the last 5 minutes.
- _updatingCity, _updatingTopic : Boolean indicating update state of news.
- localIndex, worldIndex : Indexes for news articles
- count : Index for news options

#### Methods
- build(context) : Builds a ListView (to avoid keyboard overflow) containing the mesh, the forms and the play button.
- initState() : Writes the news from the args to its variable, creates forms and initializes the text to speech.
- buttonChild(context) : Builds the Button Widget with its styling, or the Progress Indicator if it is updating.
- weatherTimer(): Creates a weather 5 minute timer
- topicTimer() : Creates a topic 5 minute timer
- switchWeather() : Callback for weatherTimer, makes weather readable again
- switchTopic() : Callback for topicTimer, makes topic readable again
- reduceLocal() : Adds to localIndex and reduces to 0 if the value is over its length.
- reduceWorld() : Adds to worldIndex and reduces to 0 if the value is over its length.
- createForms() : Creates the topic and weather forms, along with a Save button that store their data in its corresponding variables.
- updateTopic(query) : Retrieves topic news given the query and switches _updatingTopic
- updateTopic(query) : Retrieves weather news given the query and switches _updatingCity
- disposeTimer() : Cancels Timer and its callback, and pauses audio player.
- periodicInfo() : Creates the Timer that periodically reads the next news only if the previous news reading has been finished. Runs TTS on what is returned by webGet(), and runs the player. 
- webGet() : Returns the corresponding string for information for the current count (which can only be five cases): Local news, World news, topic news, current weather or day weather. Checks constraints for each.
- _togglePlaying(): Starts periodicInfo() if the button has been pressed on play or disposeTimer() if it is paused. Switches _isPlaying with setState, switching the icon of the button.


### MyTextFormField (text_form.dart)

Stateless Widget used for creating custom TextFormField. Must be provided with an onSave function and a hintText. Incorporates a validator that checks for empty input.
##### Methods
- build(context) : Incorporates a validator that checks for empty input. Sets onSave and hintText.


### InfoPage (info.dart)
Stateful widget that builds the body of the information display.
##### Methods
- build(context) : Display information text about creators and Github repository button
- openGit(context) : Opens URL of repository internally (originally wanted to be an external browser but did not know how)

### Web Scraping (web.dart)

Functions dedicated to parsing relevant data from some websites.

- fetchAllNews() : Creates a map with all news. Fetches local, world and weather news. If specified, fetches topic
- fetchDocument() : Fetches html document given a String URL
- bbcNews() : Returns world news articles as a list of strings. Information is retrieved from bbc.com/news/world
- bbcNewsArticle(articles, number) : Parses the title and first four paragraphs of an article.
- weather(city, current) : Returns either the current weather or the day weather for the city, depending on the current boolean. Information is retrieved from accuweather.com
- getCurrentWeather(city) : Returns information about current weather status.
- getDayWeather(city) : Returns information about day weather status.
- googleNews() : Retrieves local news titles and returns them as a list. Information retrieved form Google News.
- wikipedia(spacedQuery) : Parses the first paragraph of the first result for a query. Information is retrieved from wikipedia.org
- wikipediaNews() : Parses the top news items for a given day.

### Palette (palette.dart)

MaterialColor swatch for green/blue desaturated tones, from 0 to 100%.

---
## Credits
"Stay the Course" Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/

"Local Forecast - Slower" Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/

"Smooth Lovin" Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/

"Sincerely" Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
http://creativecommons.org/licenses/by/4.0/

"Springish" Gillicuddy (https://freemusicarchive.org/music/gillicuddy/)
Licensed under CC BY-NC 3.0 License
https://creativecommons.org/licenses/by-nc/3.0/
