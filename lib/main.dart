import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future httpRequest() async {
  final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } 
  else {
    throw Exception('Request Failed ${response.statusCode}');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

class ScrollableWidget extends StatelessWidget {
  const ScrollableWidget({super.key});

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
            const Expanded(child: Row(
                children: [
                  Text('Netflixalizer'),
                  Text('sdfds')
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
          // Replace with your own logic to retrieve the image URL
          String imageUrl = 'https://example.com/image_$index.jpg';

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