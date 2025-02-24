import 'package:casetracker/core/helpers/globals.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final List<KurumsalItem> initialItems;

  CustomSearchBar({required this.initialItems});

  @override
  _CustomSearchBarState createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late List<KurumsalItem> filteredItems;

  @override
  void initState() {
    super.initState();
    filteredItems = widget.initialItems;
  }

  void _filterItems(String searchTerm) {
    setState(() {
      filteredItems = Globals.kurumsalItemsList[0]
          .where((item) =>
          item.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: _filterItems,
        decoration: const InputDecoration(
          hintText: 'Görev Ara',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }
}
