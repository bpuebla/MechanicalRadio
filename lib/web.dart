import 'dart:math';

import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

export 'web.dart';

/// Creates a map with all news.
///
/// Fetches local, world and weather news. If specified, fetches topic

Future<Map> fetchAllNews({query, city = 'vienna'}) async {
  var news = new Map();
  print('fetching 1');
  news['local'] = await googleNews();
  print('fetching 2');
  var wikiNews = await wikipediaNews();
  news['world'] = await bbcNews();
  news['world'].addAll(wikiNews);
  print('fetching 3');
  news['currweather'] = await getCurrentWeather(city);
  print('fetching 4');
  news['dayweather'] = await getDayWeather(city);
  if (query != null) {
    news['topic'] = wikipedia(query);
  }
  return news;
}

/// Fetches html document given a String URL
Future<Document> fetchDocument(link) async {
  var response = await http.Client().get(Uri.parse(link));
  if (response.statusCode == 200) {
    // OK
    var document = await parse(response.body);
    return document;
  } else {
    throw Exception('URL $link not found');
  }
}

/// World news parsing.
///
/// Returns world news articles as a list of strings.
/// Information is retrieved from bbc.com/news/world
Future<List> bbcNews() async {
  var document = await fetchDocument("https://www.bbc.com/news/world");
  if (document.getElementsByClassName('no-mpu').isNotEmpty) {
    document.getElementsByClassName('no-mpu')[0].remove();
  }
  var articles = document.getElementsByTagName("h3"); // Search for h3
  articles.removeAt(0); // first one is duplicated
  var articleList = [];
  for (var i = 0; i < articles.length; i++) {
    var item = await bbcNewsArticle(articles, i); // gets text for article i
    if (item != '') {
      articleList.add(item);
    }
  }
  return articleList;
}

/// Parses the title and first four paragraphs of an article.
Future<String> bbcNewsArticle(articles, number) async {
  String? linkEnd = articles[number].parent.attributes['href'];

  var information = '';
  if (linkEnd != null &&
      linkEnd.startsWith('/news/') &&
      !linkEnd.startsWith('/news/live')) {
    print(linkEnd);
    // only if its a world news article, not live event
    var articleLink = "https://www.bbc.com" + linkEnd;
    final document = await fetchDocument(articleLink);
    final title = document.getElementsByTagName('h1'); // title
    final paragraphs = document.getElementsByTagName('p'); // parahraphs
    paragraphs.insert(0, title[0]);
    for (var i = 0; i <= min(paragraphs.length - 1, 4); i++) {
      // first 4 paragraphs
      information += paragraphs[i].text + ' ';
    }
  }
  return information;
}

/// Weather parsing.
///
///Taking as argument a String city and a Bool current, returns either the current
///weather for the city (if current is true) or the day weather for the city.
///Information is retrieved from accuweather.com

Future<String> weather(city, current) async {
  String? cityResult; // search result
  String forecastNowAddr; // address for forecastNow

  if (city == null) {
    return 'No weather info about city';
  }
  var document = await fetchDocument(
      "https://www.accuweather.com/en/search-locations?query=" +
          city); // searches for this city
  var results =
      document.getElementsByClassName("locations-list content-module");
  cityResult =
      results[0].children[0].attributes['href']; // gets link of first result

  if (cityResult == null) {
    // If city not found, throw error
    return ('No weather info about ' + city);
  }

  document = await fetchDocument(
      "https://www.accuweather.com" + cityResult); // fetch city weather city
  var weatherLink;
  weatherLink = document.getElementsByClassName(
      "cur-con-weather-card card-module non-ad content-module lbar-panel");
  if (weatherLink.length == 0) {
    weatherLink = document.getElementsByClassName(
        "cur-con-weather-card card-module non-ad no-shadow lbar-panel"); // get possible weather info elements
  }
  if (weatherLink.length == 0) {
    return ('Error finding weather info about ' + city);
  }
  weatherLink = weatherLink[0].attributes["href"];

  forecastNowAddr =
      "https://www.accuweather.com" + weatherLink!; // open current info link

  print(forecastNowAddr);

  document = await fetchDocument(forecastNowAddr);
  if (current == true) {
    // current weather
    var currStatus = document
        .getElementsByClassName("phrase")[0]
        .text
        .trim()
        .toLowerCase(); // get status and clean
    var currTemp = document
        .getElementsByClassName("temp")[0]
        .text
        .trim()
        .toLowerCase(); // get temperature and clean
    currTemp = currTemp.substring(0, 2);

    return ("The current weather status in $city is $currStatus, with a temperature of $currTemp degrees");
  } else {
    // day weather
    var dayStatus = document
        .getElementsByClassName("phrase")[1]
        .text
        .toLowerCase(); // get status and clean
    var dayTemp = document
        .getElementsByClassName("temperature")[0] // get temps and clean
        .text
        .trim()
        .toLowerCase();
    dayTemp = dayTemp.substring(0, 2);

    return ("The prediction for today's weather in $city is $dayStatus, with a temperature of $dayTemp degrees");
  }
}

/// Returns information about current weather status.
Future<String> getCurrentWeather(city) async {
  String currentWeather = await weather(city, true);
  return currentWeather;
}

/// Returns information about day weather status.
Future<String> getDayWeather(city) async {
  String dayWeather = await weather(city, false);
  return dayWeather;
}

/// Retrieves local news elements
Future<List> googleNews() async {
  var document = await fetchDocument(
      'https://news.google.com/topics/CAAqHAgKIhZDQklTQ2pvSWJHOWpZV3hmZGpJb0FBUAE?hl=en'); // local news in english
  var titles = document.getElementsByTagName('h3'); // get titles
  var titleList = [];
  for (var i = 0; i < titles.length; i++) {
    titleList.add(titles[i].text); // add titles to list
  }
  return titleList;
}

/// Parses the first paragraph of the first result for a query
Future<String> wikipedia(String spacedQuery) async {
  var query = spacedQuery.replaceAll(' ', '%20'); // html encoding
  print(query);
  Document document = await fetchDocument(
      'https://en.wikipedia.org/w/index.php?search=' +
          query); // searches for query
  final searchResults =
      document.getElementsByClassName('searchresult'); // result list
  if (searchResults.isNotEmpty) {
    final link = searchResults[0]
        .getElementsByTagName('href')[0]
        .attributes['href']; // get link of first result
    document = await fetchDocument(link); // doc of first result
  } else if (document
      .getElementsByClassName('mw-search-nonefound')
      .isNotEmpty) {
    // no results
    return ('Information about ' + spacedQuery + ' is not available');
  }

  var textParagraphs = document.getElementsByTagName('p'); // find paragraphs
  while (textParagraphs[0].localName != 'p' ||
      textParagraphs[0].className == 'mw-empty-elt') {
    // if non important info
    textParagraphs.removeAt(0); // remove
  }
  var information = textParagraphs[0].text + ' ' + textParagraphs[1].text;
  information = information.replaceAllMapped(
      RegExp(r'\[.*?\]'), (match) => ''); //remove [1] references from the text
  print(information);
  return (information);
}

/// Parses the top news items for a given day, returning a list.
Future<List> wikipediaNews() async {
  var stringList = [];
  Document document = await fetchDocument(
      'https://en.wikipedia.org/wiki/Portal:Current_events'); // fetch current events
  Element divItem = document
      .getElementsByClassName('p-current-events-headlines')[0]
      .getElementsByTagName('ul')[0]; // get only list in headlines
  List<dynamic> list = divItem.getElementsByTagName('li');
  for (int i = 0; i < list.length; i++) {
    stringList.add(list[i].text); // return list elements
  }
  return stringList;
}

void main() async {
  // Testing only
  //var lol = await fetchAllNews();
  //print(lol['world']);
  var localNews = await bbcNews();
  print(localNews);
  //print(getLocalNewsTitle(localNews, 0));
}
