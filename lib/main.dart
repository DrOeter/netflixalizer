import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import 'providers.dart' as providers;

void main() {
  runApp(const Netflixalizer());
}

class Netflixalizer extends StatelessWidget {
  const Netflixalizer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflixalizer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ScrollableWidget(),
    );
  }
}

class ScrollableWidget extends StatefulWidget {
  const ScrollableWidget({Key? key}) : super(key: key);

  @override
  ScrollableWidgetState createState() => ScrollableWidgetState();
}

class ScrollableWidgetState extends State<ScrollableWidget> {
  int genre           = 0;
  int genreMovie      = 0;
  int genreTv         = 0;
  String contentType  = 'movie';
  String titleKeyName = 'original_title';
  String timePeriod   = 'week';
  String searchQuery  = '';
  int lastIndex       = 0;
  int pageIndex       = 1;
  int providerLen     = 6;
  int countryLen      = 16;
  bool block          = false;
  List<dynamic> trendingList = [];
  final TextEditingController _searchController = TextEditingController();

  void removeByGenre(){
    List<Map<String, dynamic>> removeList = [];

    for (var trend in trendingList) {
      if(!trend['genre_ids'].contains(genre) && genre != 0){
        removeList.add(trend);
      }
    }

    for (var trend in removeList) {
      trendingList.remove(trend);
      if(lastIndex > 0) lastIndex -= 1;
    }
  }

  void resetView(){
    pageIndex = 1;
    lastIndex = 0;
    trendingList.clear();
  }

  void onTextChanged(String text) {
    if(!block){
      searchQuery = text;
      resetView();
    }
  }

  void fillProviderList(
    List<dynamic> providersList, 
    Map<String, dynamic> providersMap, 
    Map<String, dynamic> provider, 
    String country, 
    String section
  ){
    if(providersMap[country][section] != null) {
      for (var existingProvider in providersMap[country][section]) {
        if(existingProvider['provider_id'] == provider['provider_id']){
          var url = sprintf(globals.requests['image']!, [provider['logo_path'].toString()]);

          if(!providersList.contains(url)){
            providersList.add(url);
          }
        }
        if(providersList.length == providerLen) break;
      }
    }
  }

  Future<void> fetchData(String url, String key, List<dynamic>? dataList, Map<String, dynamic>? dataMap) async {
    final response = await http.get(Uri.parse( url ));

    if (response.statusCode == 200) {
      dynamic responseJson = jsonDecode(response.body);

      setState(() {
        if(dataList != null){
          dataList.addAll(responseJson[key]);
        }
        else if(dataMap != null){
          dataMap.addAll(responseJson);
        }
      }); 
    } 
    else {
      throw Exception('Request Failed ${response.statusCode}');
    }
  }

  Future<void> fetchProviderData() async {
    block = true;
    String url;
    List<Map<String, dynamic>> removeList = [];

    if(searchQuery.isNotEmpty){
      url = sprintf(globals.requests['search']!, [contentType, searchQuery, pageIndex.toString()]);
    }
    else {
      url = sprintf(globals.requests['trending']!, [contentType, timePeriod, pageIndex.toString()]);
    }

    await fetchData(
      url,
      'results',
      trendingList,
      null
    );
    removeByGenre();

    for (var i = lastIndex; i < trendingList.length; i++) {
      Map<String, dynamic> providersMap = {};
      await fetchData(
        sprintf(globals.requests['providers']!, [contentType, trendingList[i]['id'].toString()]),
        'results',
        null,
        providersMap
      );

      if(!providersMap['results'].isEmpty){
        trendingList[i]['providers'] = <String, dynamic>{};
        trendingList[i]['providers'].addAll( providersMap['results'] );
      }
      else {
        removeList.add(trendingList[i]);
      }
      lastIndex = i + 1;
    }

    for (var trend in removeList) {
      trendingList.remove(trend);
      if(lastIndex > 0) lastIndex -= 1;
    }

    block = false;
  }

  @override
  void initState() {
    super.initState();
    fetchProviderData();
    pageIndex += 1;   
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void filterButtonHandler(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Movie Genre',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton(
                    value: genreMovie,
                    items: globals.movieGenreItems,
                    onChanged: (int? newValue) {
                      if(!block){
                        setState(() {
                          genre = newValue!;
                          genreMovie = genre;

                          if(genre != 0) {
                            removeByGenre();
                          }
                          else if(genre == 0) {
                            pageIndex = 1;
                            lastIndex -= trendingList.length;
                            trendingList.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'TV Genre',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton(
                    value: genreTv,
                    items: globals.tvGenreItems,
                    onChanged: (int? newValue) {
                      if(!block){
                        setState(() {
                          genre = newValue!;
                          genreTv = genre;

                          if(genre != 0) {
                            removeByGenre();
                          }
                          else if(genre == 0) {
                            pageIndex = 1;
                            lastIndex -= trendingList.length;
                            trendingList.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Content Type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton(
                    value: contentType,
                    items: globals.contentTypeItems,
                    onChanged: (String? newValue) {
                      if(!block){
                        setState(() {
                          contentType = newValue!;
                          genre       = 0; 
                          genreMovie  = 0; 
                          genreTv     = 0; 

                          if(contentType == 'movie'){
                            titleKeyName = 'original_title';
                          }
                          else if(contentType == 'tv') {
                            titleKeyName = 'original_name';
                          }
                          resetView();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Time Period',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton(
                    value: timePeriod,
                    items: globals.timePeriodItems,
                    onChanged: (String? newValue) {
                      if(!block){
                        setState(() {
                          timePeriod = newValue!;
                          resetView();
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('Netflixalizer'),
                  TextButton(
                    onPressed: () {
                      filterButtonHandler(context);
                    },
                    child: const Text('Filter'),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 400, 
              child: TextField(
                controller: _searchController,
                onChanged: onTextChanged,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
      body: GridView.builder(
        itemCount: trendingList.length + 1,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (index < trendingList.length) {
            Map<String, dynamic> item           = trendingList[index];
            String title                        = item[titleKeyName];
            String coverUrl                     = sprintf(globals.requests['image']!, [item['poster_path'].toString()]);
            Map<String, dynamic>? providersMap  = item['providers'];
            List<Text> providersCountryList     = [];
            List<String> providersList          = [];
            List<Container> logoList            = [];

            if(providersMap != null){
              List<String> countryList = providersMap.keys.toList();

              for (var country in globals.countryList) {
                for (var providerCountry in countryList) {
                  if(country == providerCountry){
                    providersCountryList.add( Text( country ));
                  }
                  if(providersCountryList.length == countryLen) break;
                }
                if(providersCountryList.length == countryLen) break;
              }

              for (var provider in providers.providerList) {
                for (var country in countryList) {
                  fillProviderList(providersList, providersMap, provider, country, 'flatrate');
                  fillProviderList(providersList, providersMap, provider, country, 'rent');
                  fillProviderList(providersList, providersMap, provider, country, 'buy');
                  if(providersList.length == providerLen) break;
                }
              }

              for (var provider in providersList) {
                logoList.add(
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      image: DecorationImage(
                        image: NetworkImage( provider ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                );
              }
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 7,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [ 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 150,
                          height: 225,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(coverUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, right: 8),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 8),
                                child: Wrap(
                                  spacing: 6,
                                  children: providersCountryList,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Text('', style: TextStyle(
                      fontSize: 10,
                    )),
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        children: logoList,
                      ),
                    ),
                  ]
                ),
              ),
            );
          } else if (index < 100 && block == false) {
            fetchProviderData();
            pageIndex += 1;
          } else {
            return const Center(child: Text('End of List'));
          }
          return null;
        },
      ),
    );
  }
}