import 'package:flutter/material.dart';

class TabBarViews{
  final PageController _pageController = PageController();



  Widget buildTabBar(int currentPage) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildTabItem("Liste Görünümü", 0,currentPage),
          buildTabItem("Takvim Görünümü", 1,currentPage),
        ],
      ),
    );
  }

  Widget buildTabItem(String text, int index, int currentPage) {

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(index,
            duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        color: currentPage == index ? Colors.grey : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            color: currentPage == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.grey,
                offset: Offset(2, 2), // Set the shadow offset for a 3D effect
                blurRadius: 3, // Set the blur radius for a softer shadow
              ),
            ],
          ),
        ),
      ),
    );
  }
}