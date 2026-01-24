import 'package:flutter/material.dart';

class VideoFilterSelector extends StatelessWidget {
  final Function(String?) onFilterSelected;
  final String? selectedFilterId;

  const VideoFilterSelector({
    super.key,
    required this.onFilterSelected,
    this.selectedFilterId,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'id': null, 'name': 'Original', 'color': Colors.transparent},
      {'id': 'grayscale', 'name': 'P&B', 'color': Colors.grey},
      {'id': 'sepia', 'name': 'Sépia', 'color': const Color(0xFF704214)},
      {'id': 'vintage', 'name': 'Vintage', 'color': const Color(0xFF4B3621)},
      {'id': 'warm', 'name': 'Quente', 'color': Colors.orangeAccent},
      {'id': 'cool', 'name': 'Frio', 'color': Colors.blueAccent},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilterId == filter['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => onFilterSelected(filter['id'] as String?),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (filter['color'] as Color).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE5B80B)
                            : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (filter['name'] as String).substring(0, 1),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter['name'] as String,
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFFE5B80B) : Colors.white70,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
