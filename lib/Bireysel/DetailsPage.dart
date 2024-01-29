import 'dart:core';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Utility/globals.dart';
import 'EditItemScreen.dart';
import '../Utility/main.dart';
import 'mainBireysel.dart';

class DetailsPage extends StatefulWidget {
  final String title;
  final String item;
  final String description;
  final DateTime itemDate;
  final VoidCallback onRemove;

  DetailsPage({
    required this.title,
    required this.item,
    required this.description,
    required this.itemDate,
    required this.onRemove,
  });

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Item _item = Item(name: "", description: "", date: DateTime.now());

  @override
  void initState() {
    super.initState();
    _item = Item(name: widget.item, description: widget.description, date: widget.itemDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detay Sayfası'),
        backgroundColor: Colors.grey,
        elevation: 4,
        shape: UnderlineInputBorder(),
      ),
      body: CustomPaint(
        painter: MyCustomPainter(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(

            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 150,),
              _buildItemNameField('', _item.name),
              SizedBox(height: 30),
              _buildDescriptionField('', _item.description),
              SizedBox(height: 30),
              Text('Tarih: ${_formatDate(_item.date)}',
              style: TextStyle(
                fontSize: 20
              ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  _navigateToEditItemScreen(context);
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  foregroundColor: Colors.limeAccent,
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text('Edit'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Kaldır'),
                        content: Text('Bunu kaldırmak istediğinizden emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.popUntil(
                                context,
                                    (route) => route.isFirst,
                              );
                              Navigator.pop(context);

                            },
                            child: Text('Kaldır'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 5,
                  foregroundColor: Colors.limeAccent,
                  backgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text('Kaldır'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildItemNameField(String label, String? value) {
    return SizedBox(
            height: 75, // Adjust the height for the item name field
            child: TextField(
              textAlign: TextAlign.center,
              readOnly: true,
              controller: TextEditingController(text: value),
              style: TextStyle(
                backgroundColor: Colors.transparent, // Set background color to be barely visible
                fontSize: 18.0,
              ),
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.brown[100], // Set a slightly visible background color
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
    );
  }
  Widget _buildDescriptionField(String label, String? value) {

      return  SizedBox(
        child: TextField(
          readOnly: true,
          controller: TextEditingController(text: value),
          style: TextStyle(
            backgroundColor: Colors.grey[200],
            fontSize: 20.0,  // Increase the font size if needed
          ),
          maxLines: 9,  // Increase the maxLines property to make the text field taller
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.lightGreen[200] ?? Colors.green),
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
        ),
      );
  }

  void _navigateToEditItemScreen(BuildContext context) async {
    final editedItem = await Navigator.push(
      context,
      MaterialPageRoute<Item>(
        builder: (context) => EditItemScreen(item: _item),
      ),
    );
    if (editedItem != null) {
      setState(() {
        _item.name = editedItem.name;
        _item.description = editedItem.description;
        _item.date = editedItem.date;
      });
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    final double radius = size.width / 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, 0), radius: radius),
      pi / 2,
      -pi / 2,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
