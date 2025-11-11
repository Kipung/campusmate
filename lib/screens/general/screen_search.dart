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
  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  DocumentSnapshot? _lastDoc;
  final List<QueryDocumentSnapshot> _results = [];
  final int _pageSize = 25;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

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

  Future<void> _runQuery({bool initial = false}) async {
    if (!_hasMore && !initial) return;
    setState(() => _loading = true);

  // Search the `groups` collection. Each group document should include
  // a lowercased name field `name_lower` for case-insensitive prefix queries.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        shape: ShapeBorder.lerp(CircleBorder(), StadiumBorder(), 0.5),
        onPressed: () => Snackbar.show(
          SnackbarDisplayType.SB_INFO,
          'You clicked the floating button on the search screen!',
          context,
        ),
        splashColor: Theme.of(context).primaryColor,
        child: const Icon(FontAwesomeIcons.plus),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search groups by name',
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
          Expanded(
            child: _query.isEmpty
                ? const Center(child: Text('Type to search'))
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
                          separatorBuilder: (_, __) => const Divider(height: 1),
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
                            return ListTile(
                              leading: (data['photoUrl'] != null)
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(data['photoUrl']),
                                    )
                                  : const CircleAvatar(child: Icon(FontAwesomeIcons.peopleGroup)),
                              title: Text(name),
                              subtitle: Text(description.isNotEmpty ? description : members.isNotEmpty ? '$members members' : ''),
                              onTap: () {
                                // Optionally navigate to group details screen
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
