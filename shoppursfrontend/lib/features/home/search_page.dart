import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchTerm = 'Chocolate';
    final results = [
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Chocolates'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Cornetto Double Chocolate'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Double Chocolate'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Milk Chocolate'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Kitkat Chocolate'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Chocolate Chip'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Nestle Kitkat Chocolate'},
      {'image': 'assets/images/cat_chocolates.png', 'title': 'Dark Chocolate'},
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'chocolate',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: results.length + 1,
        itemBuilder: (context, index) {
          if (index < results.length) {
            final item = results[index];
            final title = item['title']!;
            final image = item['image']!;
            final matchIndex = title.toLowerCase().indexOf(searchTerm.toLowerCase());
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
              title: matchIndex >= 0
                  ? RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        children: [
                          TextSpan(text: title.substring(0, matchIndex)),
                          TextSpan(
                            text: title.substring(matchIndex, matchIndex + searchTerm.length),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: title.substring(matchIndex + searchTerm.length)),
                        ],
                      ),
                    )
                  : Text(title, style: const TextStyle(fontSize: 16)),
              onTap: () {},
            );
          } else {
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search, color: Colors.grey, size: 28),
              ),
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    const TextSpan(text: 'Show all results for '),
                    TextSpan(
                      text: searchTerm,
                      style: const TextStyle(color: Color(0xFF9B1B1B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              onTap: () {},
            );
          }
        },
      ),
    );
  }
} 