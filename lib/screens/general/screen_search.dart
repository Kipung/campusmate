// -----------------------------------------------------------------------
// Filename: screen_alternative.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the screen for a dummy alternative screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'dart:async';

// Flutter external package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../util/message_display/snackbar.dart';

//////////////////////////////////////////////////////////////////////////
// Search screen implemented as a ConsumerStatefulWidget so it can access
// Riverpod providers via `ref` while managing local UI state.
//////////////////////////////////////////////////////////////////////////
class ScreenSearch extends ConsumerStatefulWidget {
  static const routeName = '/search';

  const ScreenSearch({super.key});

  @override
  ConsumerState<ScreenSearch> createState() => _ScreenSearchState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _ScreenSearchState extends ConsumerState<ScreenSearch> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce; // delays search until user stops typing
  String _query = ''; // current search query
  bool _loading = false;
  DocumentSnapshot? _lastDoc; // last document for pagination
  final List<QueryDocumentSnapshot> _results = [];
  final int _pageSize = 10; // number of results to fetch per page
  bool _hasMore = true;

  static const List<String> _traits = [
    'Friendly',
    'Organized',
    'Creative',
    'Analytical',
    'Adaptable',
    'Motivated',
    'Patient',
    'Welcoming',
    'Spontaneous',
  ];

  // Make list of majors selectable
  static const List<String> _majors = [
    'Computer Science',
    'Biology',
    'Business',
    'Psychology',
    'Engineering',
    'Nursing',
    'Education',
    'Art',
    'Economics',
    'Political Science',
  ];


  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  // Clean up controllers and timers
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  // Called when the search input changes
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final text = _controller.text.trim().toLowerCase();
      setState(() {
        _query = text;
        _results.clear();
        _lastDoc = null;
        _hasMore = true;
      });
      if (text.isNotEmpty) {
        _runQuery(initial: true);
      }
    });
  }

  // Run the search query
  Future<void> _runQuery({bool initial = false}) async {
    if (!_hasMore && !initial) return;
    setState(() => _loading = true);

  // Search the 'groups' collection. Each group document should include
  // a lowercased name field 'name_lower' for case-insensitive prefix queries.
  final collection = FirebaseFirestore.instance.collection('groups');
  Query baseQuery = collection
    .orderBy('name_lower')
    .startAt([_query])
    .endAt([_query + '\uf8ff'])
    .limit(_pageSize);

    Query query = (_lastDoc != null) ? baseQuery.startAfterDocument(_lastDoc!) : baseQuery;

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _results.addAll(snap.docs);
      if (snap.docs.length < _pageSize) _hasMore = false;
    } else {
      _hasMore = false;
    }

    if (mounted) setState(() => _loading = false);
  }

  List<String> get selectedTraits => _selectedTraits;
  final List<String> _selectedTraits = [];

  List<String> get selectedMajors => _selectedMajors;
  final List<String> _selectedMajors = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          onPressed: () => Snackbar.show(
            SnackbarDisplayType.SB_INFO,
            'You clicked the floating button on the search screen!',
            context,
          ),
          splashColor: theme.colorScheme.primary.withOpacity(0.3),
          child: Icon(
            FontAwesomeIcons.plus,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Search bar container with rounded corners and shadow
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  style: textTheme.bodyLarge,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    hintText: 'Search groups by name',
                    hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _results.clear();
                                _lastDoc = null;
                                _query = '';
                                _hasMore = true;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Traits section card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Traits', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        itemCount: _traits.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final trait = _traits[index];
                          final isSelected = _selectedTraits.contains(trait);
                          return FilterChip(
                            label: Text(trait, style: textTheme.bodyMedium),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
                            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey[800],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!_selectedTraits.contains(trait)) _selectedTraits.add(trait);
                                } else {
                                  _selectedTraits.remove(trait);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Majors section card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Majors', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        itemCount: _majors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final major = _majors[index];
                          final isSelected = selectedMajors.contains(major);
                          return FilterChip(
                            label: Text(major, style: textTheme.bodyMedium),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: theme.colorScheme.primaryContainer.withOpacity(0.6),
                            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey[800],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  if (!selectedMajors.contains(major)) selectedMajors.add(major);
                                } else {
                                  selectedMajors.remove(major);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _query.isEmpty
                    ? Center(child: Text('Type to search', style: textTheme.bodyLarge))
                    : _loading && _results.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notif) {
                              if (notif is ScrollEndNotification &&
                                  notif.metrics.pixels >=
                                      notif.metrics.maxScrollExtent - 120 &&
                                  !_loading &&
                                  _hasMore) {
                                _runQuery();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              itemCount: _results.length + (_hasMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, index) {
                                if (index >= _results.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final doc = _results[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['name'] ?? 'No name';
                                final description = data['description'] ?? '';
                                final members = data['memberCount']?.toString() ?? '';
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      // Optionally navigate to group details screen
                                    },
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: (data['photoUrl'] != null)
                                          ? CircleAvatar(
                                              radius: 24,
                                              backgroundImage: NetworkImage(data['photoUrl']),
                                            )
                                          : CircleAvatar(
                                              radius: 24,
                                              backgroundColor: theme.colorScheme.primaryContainer,
                                              child: Icon(FontAwesomeIcons.peopleGroup, color: theme.colorScheme.primary, size: 20),
                                            ),
                                      title: Text(name, style: textTheme.titleMedium),
                                      subtitle: Text(
                                        description.isNotEmpty ? description : members.isNotEmpty ? '$members members' : '',
                                        style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                      ),
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
    );
  }
}
