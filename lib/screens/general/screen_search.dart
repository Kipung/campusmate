// -----------------------------------------------------------------------
// Filename: screen_search.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Description: Allows students to search every study group in Firestore and
//              narrow results by name, personality traits, and majors.

// //////////////////////////////////////////////////////////////////////////
// Imports
// //////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'dart:async';

// Flutter external package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// App relative file imports
import '../../constants/group_filters.dart';
import '../../db_helpers/firestore_keys.dart';
import '../../models/groups.dart';
import '../../util/message_display/snackbar.dart';
import '../../models/user_profile.dart';

// //////////////////////////////////////////////////////////////////////////
// Search screen implemented as a StatefulWidget that fetches Firestore data
// and manages local filters.
// //////////////////////////////////////////////////////////////////////////
class ScreenSearch extends StatefulWidget {
  static const routeName = '/search';

  const ScreenSearch({super.key});

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

// //////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
// //////////////////////////////////////////////////////////////////////////
class _ScreenSearchState extends State<ScreenSearch> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final List<String> _selectedTraits = [];
  final List<String> _selectedMajors = [];
  final List<Groups> _allGroups = [];
  final List<Groups> _filteredGroups = [];
  final List<UserProfile> _allMembers = [];
  final List<UserProfile> _filteredMembers = [];
  bool _loading = true;
  String? _errorMessage;

  // Searching groups or members toggle
  bool _searchMode = false; // false = groups, true = members

  void _toggleSearchMode() {
    setState(() {
      _searchMode = !_searchMode;
      _query = '';
      _controller.clear();
      _recomputeFilters();
    });
    if (_searchMode) {
      _loadMembers();
    } else {
      _loadGroups();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    if (_searchMode) {
      _loadMembers();
    } else {
      _loadGroups();
    }
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
      if (!mounted) return;
      setState(() {
        _query = text;
      });
      _recomputeFilters();
    });
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FS_COL_IC_GROUPS)
          .get();
      if (!mounted) return;

      final groups = snapshot.docs
          .map((doc) => Groups.defFromJsonDbObject(doc.data(), doc.id))
          .toList();

      _allGroups
        ..clear()
        ..addAll(groups);
      _filteredGroups
        ..clear()
        ..addAll(_filterGroups(_allGroups));

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load groups. Pull down to try again.';
        _allGroups.clear();
        _filteredGroups.clear();
      });
    }
  }

  Future<void> _loadMembers() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(FS_COL_IC_USER_PROFILES).get();
      if (!mounted) return;

      final members = snapshot.docs
          .map((doc) => UserProfile.defFromJsonDbObject(doc.data(), doc.id))
          .toList();

      _allMembers
        ..clear()
        ..addAll(members);
      _filteredMembers
        ..clear()
        ..addAll(_filterMembers(_allMembers));

      // Ensure UI updates and loading indicator is hidden after data is loaded
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load members. Pull down to try again.';
        _allMembers.clear();
        _filteredMembers.clear();
      });
    }
  }

  void _recomputeFilters() {
    if (!mounted) return;
    _filteredGroups
      ..clear()
      ..addAll(_filterGroups(_allGroups));
    setState(() {});
    _filteredMembers
      ..clear()
      ..addAll(_filterMembers(_allMembers));
    setState(() {});
  }

  List<Groups> _filterGroups(List<Groups> source) {
    final query = _query;
    final traitsLower = _selectedTraits.map((t) => t.toLowerCase()).toList();
    final majorsLower = _selectedMajors.map((m) => m.toLowerCase()).toList();

    final filtered =
        source.where((group) {
          final nameLower = group.groupName.toLowerCase();
          if (query.isNotEmpty && !nameLower.contains(query)) {
            return false;
          }

          if (traitsLower.isNotEmpty) {
            final groupTraits = group.personalityTraits
                .map((t) => t.toLowerCase())
                .toSet();
            if (!traitsLower.every(groupTraits.contains)) {
              return false;
            }
          }

          if (majorsLower.isNotEmpty) {
            final groupMajors = group.majors
                .map((major) => major.toLowerCase())
                .toSet();
            if (!majorsLower.every(groupMajors.contains)) {
              return false;
            }
          }

          return true;
        }).toList()..sort(
          (a, b) =>
              a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase()),
        );

    return filtered;
  }

  List<UserProfile> _filterMembers(List<UserProfile> source) {
    final query = _query.toLowerCase();
    final traitsLower = _selectedTraits.map((t) => t.toLowerCase()).toList();
    final majorsLower = _selectedMajors.map((m) => m.toLowerCase()).toList();

    final filtered = source.where((member) {
      final fullName = '${member.firstName} ${member.lastName}'.toLowerCase();
      if (query.isNotEmpty && !fullName.contains(query)) {
        return false;
      }

      if (majorsLower.isNotEmpty) {
        final memberMajor = member.major.toLowerCase();
        if (!majorsLower.contains(memberMajor)) {
          return false;
        }
      }

      if (traitsLower.isNotEmpty) {
        final memberTraits =
            member.personalityTraits.map((t) => t.toLowerCase()).toSet();
        if (!traitsLower.every(memberTraits.contains)) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort(
        (a, b) {
          final nameA = '${a.firstName} ${a.lastName}'.toLowerCase();
          final nameB = '${b.firstName} ${b.lastName}'.toLowerCase();
          return nameA.compareTo(nameB);
        },
      );

    return filtered;
  }

  ////////////////////////////////////////////////////////////////////////
  // Primary Flutter method overridden which describes the layout and bindings for this widget.
  ////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
        children: [
          _buildSearchBar(textTheme),
          const SizedBox(height: 12),

          // Toggle to switch between searching groups and members/users
          Container(
          width: double.infinity,
          padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text(
              'Search mode',
              style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
              Text('Groups',
                style: textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[700])),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _searchMode,
                onChanged: (_) => _toggleSearchMode(),
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('Members',
                style: textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey[700])),
              ],
            ),
            ],
          ),
          ),

          const SizedBox(height: 16),
          _buildTraitsFilter(theme, textTheme),
          const SizedBox(height: 12),
          _buildMajorsFilter(theme, textTheme),
          const SizedBox(height: 16),
          Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _searchMode ? _loadMembers : _loadGroups,
              child: _buildResultsList(theme, textTheme),
              ),
          ),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchBar(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          hintText: _searchMode ? 'Search members by name' : 'Search groups by name',
          hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _query = '';
                    });
                    _recomputeFilters();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTraitsFilter(ThemeData theme, TextTheme textTheme) {
    final traits = PersonalityTraits.traits;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traits',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: traits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final trait = traits[index];
                final isSelected = _selectedTraits.contains(trait);
                return FilterChip(
                  label: Text(trait, style: textTheme.bodyMedium),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey[800],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedTraits.contains(trait)) {
                          _selectedTraits.add(trait);
                        }
                      } else {
                        _selectedTraits.remove(trait);
                      }
                    });
                    _recomputeFilters();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajorsFilter(ThemeData theme, TextTheme textTheme) {
    final majors = AcademicMajors.majors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Majors',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: majors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final major = majors[index];
                final isSelected = _selectedMajors.contains(major);
                return FilterChip(
                  label: Text(major, style: textTheme.bodyMedium),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey[800],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedMajors.contains(major)) {
                          _selectedMajors.add(major);
                        }
                      } else {
                        _selectedMajors.remove(major);
                      }
                    });
                    _recomputeFilters();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, TextTheme textTheme) {
    if (_searchMode) {
      // Show members list
      if (_errorMessage != null) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(FontAwesomeIcons.triangleExclamation,
                color: theme.colorScheme.error, size: 32),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _loadMembers,
                child: const Text('Try again'),
              ),
            ),
          ],
        );
      }

      if (_filteredMembers.isEmpty) {
        final message =
            _query.isEmpty ? 'No members available.' : 'No members match your filters.';
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(FontAwesomeIcons.user, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        );
      }

      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredMembers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final member = _filteredMembers[index];
          final fullName = '${member.firstName} ${member.lastName}'.trim();

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // TODO: navigate to member profile page
              },
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    FontAwesomeIcons.user,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(fullName.isNotEmpty ? fullName : 'Unnamed',
                    style: textTheme.titleMedium),
              ),
            ),
          );
        },
      );
    }

    // If not in member search mode, fall through to groups handling below.
    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loadGroups,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    if (_filteredGroups.isEmpty) {
      final message =
          _query.isEmpty && _selectedTraits.isEmpty && _selectedMajors.isEmpty
          ? 'No groups available.'
          : 'No groups match your filters.';
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Icon(
            FontAwesomeIcons.peopleGroup,
            color: theme.colorScheme.primary,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final group = _filteredGroups[index];
        final memberCount = group.members.length;
        final description = group.groupDescription.trim();
        final subtitle = description.isNotEmpty
            ? description
            : memberCount > 0
            ? '$memberCount member${memberCount == 1 ? '' : 's'}'
            : '';
        final traitsPreview = group.personalityTraits.take(2).join(', ');
        final majorsPreview = group.majors.take(2).join(', ');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO: navigate to group detail page
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  FontAwesomeIcons.peopleGroup,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              title: Text(group.groupName, style: textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  if (traitsPreview.isNotEmpty)
                    Text(
                      'Traits: $traitsPreview',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  if (majorsPreview.isNotEmpty)
                    Text(
                      'Majors: $majorsPreview',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
