import 'package:flutter/material.dart';


import '../../../core/helpers/globals.dart';
import '../../../core/util/time/date_utils.dart';
import '../../../screens/personal/details_screen.dart';



class TaskListPage extends StatefulWidget {
  final List<Item> items;
  final Future<void> Function() onRefresh;
  final void Function(Item) removeItem;
  late int currentPage;

   TaskListPage({
    Key? key,
    required this.items,
    required this.onRefresh,
    required this.removeItem,
    required this.currentPage,
  }) : super(key: key);

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  Widget build(BuildContext context) {
    List<Item> sortedItems = List.from(widget.items)..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: SizedBox(
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - kBottomNavigationBarHeight,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (sortedItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No tasks for now.',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    for (final item in sortedItems)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: Colors.lime[400] ?? Colors.green,
                              width: 4.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey[600] ?? Colors.grey,
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              '${item.name} - ${DateUtilsHelper.formatDate(item.date)}',
                              style: const TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              DateUtilsHelper.calculateDaysLeft(item.date),
                              style: const TextStyle(color: Colors.black),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailsPage(
                                    title: "Screen ${widget.currentPage + 1}",
                                    item: item.name,
                                    description: item.description ?? "",
                                    itemDate: item.date,
                                    onRemove: () {
                                      widget.removeItem(item);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
