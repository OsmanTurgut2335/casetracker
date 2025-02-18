import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseEditScreen<T> extends ConsumerStatefulWidget {
  final T item;
  const BaseEditScreen({Key? key, required this.item}) : super(key: key);
}

abstract class BaseEditScreenState<T extends BaseEditScreen> extends ConsumerState<T> with RouteAware {
  DateTime _selectedDueDate = DateTime.now();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  late String itemName;
  late String foundKey;
  late String? taskKey;

  String findKeyByValue(Map<String, String> map, String targetValue) {
    return map.entries.firstWhere((entry) => entry.value == targetValue, orElse: () => MapEntry("", "")).key;
  }

  @override
  void initState() {
    super.initState();
    initFields();
  }

  void initFields();

  Future<void> saveChanges(BuildContext context, String itemKey, String collectionName);

  Widget buildDueDateSelector() {
    return Row(
      children: [
        const Text('Due Date:', style: TextStyle(color: Colors.black)),
        const SizedBox(width: 16),
        TextButton(
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (pickedDate != null) {
              setState(() => _selectedDueDate = pickedDate);
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
          child: Text('${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
              style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

