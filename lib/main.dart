import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'globals.dart' as globals;

Future httpRequest(String url) async {
  final response = await http.get(Uri.parse( url ));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } 
  else {
    throw Exception('Request Failed ${response.statusCode}');
  }
}

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
      home: ScrollableWidget(),
    );
  }
}

class ScrollableWidget extends StatefulWidget {
  const ScrollableWidget({super.key});
  @override
  _ScrollableWidgetState createState() => _ScrollableWidgetState();
}

class _ScrollableWidgetState extends State<ScrollableWidget> {
  String genre = '28';
  String contentType = 'movie';
  int loadCounter = 1;
  int itemIndex = 0;
  dynamic response;

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
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  DropdownButton(
                    value: contentType,
                    items: globals.contentTypeItems,
                    onChanged: (String? newValue) {
                      setState(() {
                        contentType = newValue!;
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
            Expanded(child: Row(
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
            ), // Empty widget to take up the remaining space
            const SearchBarWidget(),
            Expanded(child: Container()), // Empty widget to take up the remaining space
          ],
        ),
      ),
      body: GridView.builder(
        itemCount: 100, // Replace with the actual number of items you have
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Number of tiles per row
        ),
        itemBuilder: (BuildContext context, int index) {  
/*
          if(index % 20 == 0){
            response = httpRequest(
              'https://api.themoviedb.org/3/trending/movie/week?api_key=e2c7d1908816457a2156268c1fb5d7ae&page=$loadCounter'
            );
            loadCounter++;
            itemIndex = 0;
          }

          dynamic item = response['results'][itemIndex];
          String title = item['original_title'];
          String cover = item['poster_path'];
          List genres = item['genre_ids'];
*/
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                /*
                Image.network(
                  imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                */
                Text('Tile $index'),
              ],
            ),
          );
          itemIndex++;
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