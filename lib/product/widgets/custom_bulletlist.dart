import 'package:flutter/material.dart';

class CustomBulletlist extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected; // Callback to notify parent

  const CustomBulletlist({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CustomBulletlist> createState() => _CustomBulletlistState();
}

class _CustomBulletlistState extends State<CustomBulletlist> {
  late DateTime _selectedDueDate; // Local state for the selected date

  @override
  void initState() {
    super.initState();
    _selectedDueDate = widget.initialDate; // Initialize with the initial date
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 175,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              for (final slot in [1, 3, 5, 7, 10, 14, 15, 30, 45])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      final newDate = DateTime.now().add(Duration(days: slot));
                      setState(() {
                        _selectedDueDate = newDate;
                      });
                      widget.onDateSelected(newDate); // Notify parent
                    },
                    style: ElevatedButton.styleFrom(
                      maximumSize: const Size.fromHeight(40),
                      backgroundColor: Colors.grey[400] ?? Colors.grey,
                    ),
                    child: Text(
                      '$slot gün',
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bitiş Tarihi:',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDueDate = pickedDate;
                  });
                  widget.onDateSelected(pickedDate); // Notify parent
                }
              },
              child: Text(
                '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Tarihe basarak takvim üzerinden tarih seçimi yapabilirsiniz',
          style: TextStyle(color: Colors.black, fontSize: 10),
        ),
      ],
    );
  }
}
