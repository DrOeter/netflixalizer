import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'globals.dart' as globals;
import 'providers.dart' as providers;

void main() {
  runApp(const Netflixalizer());
}

class Netflixalizer extends StatelessWidget {
  const Netflixalizer({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  _ScrollableWidgetState createState() => _ScrollableWidgetState();
}

class _ScrollableWidgetState extends State<ScrollableWidget> {
  String genre = '0';
  String contentType = 'movie';
  int loadCounter = 1;
  int itemCounter = 1;
  int itemIndex = 0;
  int lastIndex = 0;
  int pageIndex = 1;
  bool block = false;
  List<dynamic> trendingList = [];
  List<dynamic> imagesList = [];
  List<dynamic> imageList = [];

  String buildUrl(String key, String value){
    return globals.requests[key]!.replaceFirst('{}', value);
  }

  void _filterButtonHandler(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton(
                    value: genre,
                    items: globals.movieGenreItems,
                    onChanged: (String? newValue) {
                      setState(() {
                        genre = newValue!;
                        //itemIndex = 0;
                        //pageIndex = 1;
                        //trendingList.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButton(
                    value: contentType,
                    items: globals.contentTypeItems,
                    onChanged: (String? newValue) {
                      setState(() {
                        contentType = newValue!;
                        //itemIndex = 0;
                        //pageIndex = 1;
                        //trendingList.clear();
                      });
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
    await fetchData(
      buildUrl('trendingMovies', pageIndex.toString()),
      'results',
      trendingList,
      null
    );

    for (var i = lastIndex; i < trendingList.length; i++) {
      Map<String, dynamic> providersMap = {};
      await fetchData(
        buildUrl('providersMovies', trendingList[i]['id'].toString()),
        'results',
        null,
        providersMap
      );

      trendingList[i]['providers'] = <String, dynamic>{};
      trendingList[i]['providers'].addAll( providersMap['results'] );
      lastIndex = i + 1;
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
                      _filterButtonHandler(context);
                    },
                    child: const Text('Filter'),
                  ),
                ],
              ),
            ),
            const SearchBarWidget(),
            Expanded(child: Container()),
          ],
        ),
      ),
      body: GridView.builder(
        itemCount: trendingList.length + 1, // +1 for loading indicator at the end
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemBuilder: (BuildContext context, int index) {
          if (index < trendingList.length) {
            dynamic item = trendingList[index];
            String title = item['original_title'];
            String coverUrl = buildUrl('image', item['poster_path'].toString());
            List<dynamic> genres = item['genre_ids'];
            Map<String, dynamic>? providersMap = item['providers'];
            List<Text> providersCountryList = [];
            List<String> providersList = [];
            List<Container> logoList = [];

            if(genres.contains(int.parse(genre)) || genre == '0'){
              if(providersMap != null){
                List<String> countryList = providersMap.keys.toList();

                for (var country in globals.countryList) {
                  for (var providerCountry in countryList) {
                    if(country == providerCountry){
                      providersCountryList.add( Text( country ));
                    }
                    if(providersCountryList.length == 16) break;
                  }
                  if(providersCountryList.length == 16) break;
                }

                for (var provider in providers.providerList) {
                  for (var country in countryList) {
                    if(providersMap[country]['flatrate'] != null) {
                      for (var providerFlatrate in providersMap[country]['flatrate']) {
                        if(providerFlatrate['provider_id'] == provider['provider_id']){
                          var url = buildUrl('image', provider['logo_path']);

                          if(!providersList.contains(url)){
                            providersList.add(url);
                          }
                        }
                        if(providersList.length == 6) break;
                      }
                    }
                    if(providersMap[country]['rent'] != null) {
                      for (var providerFlatrate in providersMap[country]['rent']) {
                        if(providerFlatrate['provider_id'] == provider['provider_id']){
                          var url = buildUrl('image', provider['logo_path']);

                          if(!providersList.contains(url)){
                            providersList.add(url);
                          }
                        }
                        if(providersList.length == 6) break;
                      }
                    }
                    if(providersMap[country]['buy'] != null) {
                      for (var providerFlatrate in providersMap[country]['buy']) {
                        if(providerFlatrate['provider_id'] == provider['provider_id']){
                          var url = buildUrl('image', provider['logo_path']);

                          if(!providersList.contains(url)){
                            providersList.add(url);
                          }
                        }
                        if(providersList.length == 6) break;
                      }
                    }
                    if(providersList.length == 6) break;
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
            }
          } else if (index < 100 && block == false) {
            fetchProviderData();
            pageIndex += 1;
            //return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('End of List'));
          }
          return null;
        },
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key}); 

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged(String text) {
    // Implement your search logic here
    print(text);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400, 
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchTextChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}