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
      debugShowCheckedModeBanner: false,
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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> trendingList = [];
  String contentType  = 'movie';
  String titleKeyName = 'original_title';
  String timePeriod   = 'week';
  String searchQuery  = '';
  int genre           = 0;
  int genreMovie      = 0;
  int genreTv         = 0;
  int lastIndex       = 0;
  int pageIndex       = 1;
  int providerLen     = 5;
  int countryLen      = 24;
  bool block          = false;
  bool totalBlock     = false;

  void removeByGenre(){
    List<Map<String, dynamic>> removeList = [];

    for (var trend in trendingList) {
      if(!trend['genre_ids'].contains(genre)){
        removeList.add(trend);
      }
    }
    block = true;

    for (var trend in removeList) {
      trendingList.remove(trend);
      if(lastIndex > 0) lastIndex -= 1;
    }
    block = false;
  }

  void resetView(){
    pageIndex = 1;
    lastIndex = 0;
    trendingList.clear();
  }

  void onTextChanged(String text) {
    setState(() {
      searchQuery = text;
      if(!totalBlock){
        resetView();
      }
    });
  }

  void fillProviderList(
    List<dynamic> totalList, 
    List<dynamic> providersList
  ){
    for (var provider in providers.providerList) {
      for (var existingProvider in totalList) {
        if(existingProvider['provider_id'] == provider['provider_id']){
          var url = sprintf(globals.requests['image']!, [provider['logo_path'].toString()]);

          if(!providersList.contains(url)){
            providersList.add(url);
          }
        }
        if(providersList.length == providerLen) break;
      }
      if(providersList.length == providerLen) break;
    }
  }

  Future<void> fetchData(String url, List<dynamic>? dataList, Map<String, dynamic>? dataMap) async {
    final response = await http.get(Uri.parse( url ));

    if (response.statusCode == 200) {
      dynamic responseJson = jsonDecode(response.body);

      setState(() {
        if(dataList != null){
          dataList.addAll(responseJson['results']);
        }
        else if(dataMap != null){
          dataMap.addAll(responseJson['results']);
        }
      }); 
    } 
    else {
      throw Exception('Request Failed ${response.statusCode}');
    }
  }

  Future<void> fetchProviderData() async {
    totalBlock = true;
    String url;
    List<Map<String, dynamic>> removeList = [];
    List<dynamic> responseList = [];

    if(searchQuery.isNotEmpty){
      url = sprintf(globals.requests['search']!, [contentType, searchQuery, pageIndex.toString()]);
    }
    else {
      url = sprintf(globals.requests['trending']!, [contentType, timePeriod, pageIndex.toString()]);
    }
    
    await fetchData(
      url,
      responseList,
      null
    );
    block = true;
    trendingList.addAll(responseList);
    block = false;
    if(genre != 0) removeByGenre();

    for (var i = lastIndex; i < trendingList.length; i++) {
      Map<String, dynamic> providersMap = {};
      await fetchData(
        sprintf(globals.requests['providers']!, [contentType, trendingList[i]['id'].toString()]),
        null,
        providersMap
      );

      if(providersMap.isNotEmpty){
        trendingList[i]['providers'] = <String, dynamic>{};
        trendingList[i]['providers'].addAll( providersMap );
      }
      else {
        removeList.add(trendingList[i]);
      }
      lastIndex = i + 1;
    }
    block = true;

    for (var trend in removeList) {
      trendingList.remove(trend);
      if(lastIndex > 0) lastIndex -= 1;
    }
    block = false;
    totalBlock = false;
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
                      if(!totalBlock){
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
                      if(!totalBlock){
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
                      if(!totalBlock){
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
                      if(!totalBlock){
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
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'Netflixalizer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
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
                onSubmitted: onTextChanged,
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
          if (index < trendingList.length && !block) {
            Map<String, dynamic> item           = trendingList[index];
            String title                        = item[titleKeyName];
            String coverUrl                     = sprintf(globals.requests['image']!, [item['poster_path'].toString()]);
            Map<String, dynamic>? providersMap  = item['providers'];
            List<Text> providersCountryList     = [];
            List<String> providersList          = [];
            List<Container> logoList            = [];
            List<dynamic> totalList             = [];

            if (item['poster_path'] != null){
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

                providersMap.forEach((key, value) {
                  if(providersMap[key].keys.contains('buy')) totalList.addAll(providersMap[key]['buy']);
                  if(providersMap[key].keys.contains('rent')) totalList.addAll(providersMap[key]['rent']);
                  if(providersMap[key].keys.contains('flatrate')) totalList.addAll(providersMap[key]['flatrate']);
                  if(providersMap[key].keys.contains('free')) totalList.addAll(providersMap[key]['free']);
                });

                fillProviderList(totalList, providersList);
                    
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
            }
          } else if (index < 100 && totalBlock == false) {
            fetchProviderData();
            pageIndex += 1;
          } 

          return null;
        },
      ),
    );
  }
}