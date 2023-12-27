import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'intro_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return this.year == other.year && this.month == other.month && this.day == other.day;
  }
}

class Item {
  late String name;
  late String? description; // Allow null for description
  late DateTime date;

  Item({required this.name, this.description, required this.date});
}

class Task {
  late String details;
  late DateTime date;

  Task({required this.details, required this.date});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data as User?;
            if (user == null) {
              // User not signed in, show the login screen
              return LoginScreen();
            } else {
              // User is signed in, show the main screen
              return MyHomePage(user: user);
            }
          } else {
            // Show a loading indicator while checking authentication state
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
class MyHomePage extends StatefulWidget {
  final User? user; // Change the type to User?

  MyHomePage({this.user});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  Map<DateTime, List<Task>> tasksMap = {};
  List<List<Item>> itemsList = [
    [],
    [],
  ];

  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchDataFromDatabase();
  }

  Future<void> _fetchDataFromDatabase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL:
        "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();

      // Update the reference to include the user's UID
      DatabaseReference userTaskReference =
      firebaseRef.child('users').child(user.uid);

      final snapshot = await userTaskReference.get();

      if (snapshot.value is Map<dynamic, dynamic>) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        itemsList[0].clear();

        data.forEach((key, value) {
          final item = Item(
            name: value['name'],
            description: value['description'],
            date: DateTime.parse(value['date']),
          );
          itemsList[0].add(item);
        });

        setState(() {});
      }
    }
  }




  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp()), // Change here
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("App Title"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signOut') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'signOut',
                  child: Text('Sign Out'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          _currentPage == 0 ? _buildSearchBar() : SizedBox(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                Expanded(
                  child: _buildPage(itemsList[0]),
                ),

                _buildCalendarPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentPage == 0
          ? _buildFloatingButton(context)
          : null,
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem("First Screen", 0),
          _buildTabItem("Second Screen", 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text, int index) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(index,
            duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      child: Container(
        padding: EdgeInsets.all(10),
        color: _currentPage == index ? Colors.blue : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            color: _currentPage == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPage(List<Item> items) {
    items.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final daysLeft = _calculateDaysLeft(item.date);
              final daysLeftText = daysLeft == 0
                  ? 'Due today'
                  : daysLeft > 0
                  ? '$daysLeft days left'
                  : 'Expired';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.lightBlue, // Set your desired background color
                    borderRadius: BorderRadius.circular(8.0), // Optional: Add rounded corners
                  ),
                  child: ListTile(
                    title: Text(
                      '${item.name} - ${_formatDate(item.date)} - $daysLeftText',
                      style: TextStyle(
                        color: Colors.white, // Set text color to contrast with the background
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                            title: "Screen ${_currentPage + 1}",
                            item: item.name,
                            description: item.description ?? "",
                            itemDate: item.date,
                            onRemove: () {
                              _removeItem(item);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }




  Widget _buildCalendarPage() {
    // Clear tasksMap before populating it again
    tasksMap.clear();

    itemsList[0].forEach((item) {
      tasksMap[item.date] = tasksMap[item.date] ?? [];
      tasksMap[item.date]!.add(Task(details: item.name, date: item.date));
    });

    return Column(
      children: [
        TableCalendar(
          focusedDay: _selectedDay,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
            });

            // Fetch tasks for the selected day from the database
            _fetchTasksForSelectedDay(selectedDay);
          },
        ),
        SizedBox(height: 16),
        if (tasksMap[_selectedDay] != null && tasksMap[_selectedDay]!.isNotEmpty)
          Column(
            children: [
              Text('Tasks for ${_formatDate(_selectedDay)}:'),
              GestureDetector(
                onTap: () {
                  _navigateToDetailsPage(tasksMap[_selectedDay]!.first);
                },
                child: ListTile(
                  title: Text(tasksMap[_selectedDay]!.first.details),
                ),
              ),
            ],
          )
        else
          Text('No tasks for ${_formatDate(_selectedDay)}'),
      ],
    );
  }




/*User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final firebaseRef = FirebaseDatabase(
        databaseURL:
        "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
      ).reference();
      final snapshot = await firebaseRef.get();

      if (snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;*/

  Future<void> _fetchTasksForSelectedDay(DateTime selectedDay) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (DateTime.now().isSameDate(selectedDay)) {
        // If the selected day is today, fetch tasks from local itemsList
        final todayTasks = itemsList[0].where((item) {
          return item.date.isSameDate(selectedDay);
        }).toList();

        tasksMap[selectedDay] = todayTasks.map((item) {
          return Task(details: item.name, date: item.date);
        }).toList();

        setState(() {});
      } else {
        // Fetch tasks for the selected day from the database
        final firebaseRef = FirebaseDatabase(
          databaseURL:
          "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();
        final snapshot = await firebaseRef.get();

        if (snapshot.value != null) {
          final Map<dynamic, dynamic> data =snapshot.value as Map<dynamic, dynamic>;

          tasksMap[selectedDay] = [];

          data.forEach((key, value) {
            final task = Task(
              details: value['name'],
              date: DateTime.parse(value['date']),
            );
            tasksMap[selectedDay]!.add(task);
          });

          setState(() {});
        }
      }
    }

  }



  Widget _buildTasksForSelectedDay(List<Task> tasks) {
    return tasks.isNotEmpty
        ? Column(
      children: [
        Text('Tasks for ${_formatDate(_selectedDay)}:'),
        for (Task task in tasks)
          ListTile(
            title: Text(task.details),
          ),
      ],
    )
        : Text('No tasks for ${_formatDate(_selectedDay)}');
  }
  void _navigateToDetailsPage(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPage(
          title: "Screen 2",
          item: task.details,
          description: "", // Add description logic if needed
          itemDate: task.date,
          onRemove: () {
            // Implement removal logic if needed
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) {},
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final newItem = await _navigateToNewItemScreen(context);
        if (newItem != null) {

          _addItem(newItem);
        }
      },
      child: Icon(Icons.add),
    );
  }

  void _addItem(Item newItem) {
    setState(() {
      itemsList[0].add(newItem);

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      // Print statement to check if user is null
      print("Current user: $user");

      if (user != null) {
        final firebaseRef = FirebaseDatabase(
          databaseURL:
          "https://casetracker-4a2ac-default-rtdb.europe-west1.firebasedatabase.app",
        ).reference();

        // Update the reference to include the user's UID
        DatabaseReference userTaskReference =
        firebaseRef.child('users').child(user.uid);

        // Create a map for the new task
        Map<String, dynamic> newTaskData = {
          "name": newItem.name,
          "description": newItem.description ?? "",
          "date": newItem.date.toUtc().toIso8601String(),
        };

        // Print statement to check the new task data
        print("New task data: $newTaskData");

        // Use push to generate a unique key for the new task
        DatabaseReference newTaskReference = userTaskReference.push();

        // Set the value of the new task using the generated key
        newTaskReference.set(newTaskData);

        // Print statement to check if data is added to the database
        print("Task added to the database with key: ${newTaskReference.key}");
      }
    });
  }









  Future<Item?> _navigateToNewItemScreen(BuildContext context) async {
    return await Navigator.push(
      context,
      MaterialPageRoute<Item>(
        builder: (context) => NewItemScreen(),
      ),
    );
  }

  void _removeItem(Item item) {
    setState(() {
      itemsList[0].remove(item);
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  int _calculateDaysLeft(DateTime date) {
    final currentDate = DateTime.now();
    final difference = date.difference(currentDate);
    return difference.inDays;
  }
}


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
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${_item.name.toUpperCase()}'),
            SizedBox(height: 10,),
            Text('Detaylar: ${_item.description}'),
            SizedBox(height: 30,),
            Text('Tarih: ${_formatDate(_item.date)}'),
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: () {
                _navigateToEditItemScreen(context);
              },
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
                            widget.onRemove();
                          },
                          child: Text('Kaldır'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Kaldır'),
            ),
          ],
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
      // Handle the edited item, update the UI, and save changes to the database if needed.
      // For simplicity, you can print the edited item.
      print("Edited Item: ${editedItem.name}, ${editedItem.description}, ${editedItem.date}");

      // If you need to update the UI with the edited item, you can do so here.
      setState(() {
        // Update the item details in the UI.
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


class NewItemScreen extends StatefulWidget {
  @override
  _NewItemScreenState createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  DateTime _selectedDueDate = DateTime.now();
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDueDateSelector(),
            SizedBox(height: 16),
            _buildItemNameField(),
            SizedBox(height: 16),
            _buildDescriptionField(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_validateAndSave()) {
                  final newItem = Item(
                    name: _itemNameController.text,
                    description: _descriptionController.text,
                    date: _selectedDueDate,
                  );
                  Navigator.pop(context, newItem);
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Row(
      children: [
        Text('Due Date:'),
        SizedBox(width: 16),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null && pickedDate != _selectedDueDate) {
              setState(() {
                _selectedDueDate = pickedDate;
              });
            }
          },
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
          ),
        ),
      ],
    );
  }

  Widget _buildItemNameField() {
    return TextField(
      controller: _itemNameController,
      decoration: InputDecoration(
        labelText: 'Item Name',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
    );
  }

  bool _validateAndSave() {
    return true; // Add your validation logic here
  }
}
// EditItemScreen class
class EditItemScreen extends StatefulWidget {
  final Item item;

  EditItemScreen({required this.item});

  @override
  _EditItemScreenState createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  DateTime _selectedDueDate = DateTime.now();
  TextEditingController _itemNameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDueDate = widget.item.date;
    _itemNameController.text = widget.item.name;
    _descriptionController.text = widget.item.description ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDueDateSelector(),
            SizedBox(height: 16),
            _buildItemNameField(),
            SizedBox(height: 16),
            _buildDescriptionField(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final editedItem = Item(
                  name: _itemNameController.text,
                  description: _descriptionController.text,
                  date: _selectedDueDate,
                );
                Navigator.pop(context, editedItem);
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Row(
      children: [
        Text('Due Date:'),
        SizedBox(width: 16),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null && pickedDate != _selectedDueDate) {
              setState(() {
                _selectedDueDate = pickedDate;
              });
            }
          },
          child: Text(
            '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
          ),
        ),
      ],
    );
  }

  Widget _buildItemNameField() {
    return TextField(
      controller: _itemNameController,
      decoration: InputDecoration(
        labelText: 'Item Name',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        border: OutlineInputBorder(),
      ),
    );
  }
}
