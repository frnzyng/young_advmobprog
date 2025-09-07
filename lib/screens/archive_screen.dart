import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:young_longexam_mobile/models/item_model.dart';
import 'package:young_longexam_mobile/screens/item_details_screen.dart';
import 'package:young_longexam_mobile/services/item_service.dart';
import 'package:young_longexam_mobile/widgets/custom_text.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _svc = ItemService();
  final List<Item> _items = [];
  List<Item> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    // Start listening for changes in the search field
    _searchController.addListener(_onSearchChanged);
    _loadFuture = _loadItems();
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final res = await _svc.getArchivedItems();
    final list =
        (res['items'] ?? res) as dynamic; // supports {items:[...]} OR [...]
    final List data = list is List ? list : (list['data'] ?? []);
    _items.clear();
    _items.addAll(data.map<Item>((e) => Item.fromJson(e)));
    // Initialize filtered list with all items after loading
    _filteredItems = List.from(_items);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // If the search query is empty, show all items
        _filteredItems = List.from(_items);
      } else {
        // Filter items based on name or description
        _filteredItems = _items
            .where((item) =>
                item.name.toLowerCase().contains(query) ||
                item.description.any(
                    (desc) => desc.toLowerCase().contains(query))) // Corrected logic
            .toList();
      }
    });
  }

  Widget _leadingThumb(Item item) {
    final url = item.photoUrl.trim();
    if (url.isEmpty) {
      return Container(
        width: 72.sp,
        height: 72.sp,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.inventory_2_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 72.sp,
        height: 72.sp,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72.sp,
          height: 72.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // Search field here
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(), // Add onChanged to trigger search
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search items...",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator.adaptive(strokeWidth: 3.sp),
                          SizedBox(height: 10.h),
                          const CustomText(text: 'Loading items...'),
                        ],
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CustomText(text: 'Failed to load items'),
                    ),
                  );
                }
                // Check _filteredItems instead of _items
                if (_filteredItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CustomText(text: 'No items to display...'),
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                  itemCount: _filteredItems.length, // Use _filteredItems
                  itemBuilder: (_, index) {
                    final item = _filteredItems[index]; // Use _filteredItems
                    final subtitle = item.description.isNotEmpty
                        ? item.description.first
                        : '';
                    return Card(
                      child: InkWell(
                        onTap: () async {
                          debugPrint('Open item ${item.iid}');
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(item: item),
                            ),
                          );
                          if (result is Map && result['deleted'] == true) {
                            final id = result['id'] as String;
                            setState(() {
                              _items.removeWhere((e) => e.iid == id);
                              // Update filtered list after removal
                              _onSearchChanged();
                            });
                          }
                          if (result is Item) {
                            setState(() {
                              final i = _items.indexWhere((e) => e.iid == result.iid);
                              if (i != -1) _items[i] = result;
                              // Update filtered list after update
                              _onSearchChanged();
                            });
                          }
                        },
                        child: ListTile(
                          leading: _leadingThumb(item),
                          title: CustomText(
                            text: item.name.isEmpty ? 'Untitled' : item.name,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            maxLines: 2,
                          ),
                          subtitle: CustomText(text: subtitle, maxLines: 2),
                          trailing: SizedBox(
                            height: double.infinity,
                            child: GestureDetector(
                              onTap: () => debugPrint('More ${item.iid}'),
                              child: const Icon(Icons.keyboard_arrow_right),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}