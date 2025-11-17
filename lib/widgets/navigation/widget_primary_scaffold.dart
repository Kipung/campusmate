// -----------------------------------------------------------------------
// Filename: widget_primary_scaffold.dart
// Original Author: Dan Grissom
// Creation Date: 5/27/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the primary scaffold for the app.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////
// Dart imports

// Flutter external package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../screens/general/screen_home.dart';
import '../../screens/general/screen_search.dart';
import '../../screens/general/screen_group/screen_groups.dart';
import '../../screens/general/screen_messages.dart';

import 'widget_primary_app_bar.dart';
import 'widget_app_drawer.dart';

//////////////////////////////////////////////////////////////////////////
// Localized provider for the current tab index
//////////////////////////////////////////////////////////////////////////
final providerPrimaryBottomNavTabIndex = StateProvider<int>((ref) => 0);

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the
// state object.
//////////////////////////////////////////////////////////////////////////
class WidgetPrimaryScaffold extends ConsumerStatefulWidget {
  static const routeName = "/home";

  const WidgetPrimaryScaffold({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  ConsumerState<WidgetPrimaryScaffold> createState() =>
      _WidgetPrimaryScaffoldState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _WidgetPrimaryScaffoldState extends ConsumerState<WidgetPrimaryScaffold> {
  // The "instance variables" managed in this state
  var _isInit = true;
  // int _currentTabIndex = 0;
  late Image shareImageFocus;
  late Image shareImageLightUnfocused;
  late Image shareImageDarkUnfocused;
  CupertinoTabController controller = CupertinoTabController();

  @override
  void initState() {
    super.initState();
  }

  ////////////////////////////////////////////////////////////////////////
  // Gets the current state of the providers for consumption on
  // this page
  ////////////////////////////////////////////////////////////////////////
  _init() async {
    // Get providers
  }

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      _init();
    }

    // Now initialized; run super method
    _isInit = false;
    super.didChangeDependencies();
  }

  ////////////////////////////////////////////////////////////////
  // Describes menu options for the chat screen
  ////////////////////////////////////////////////////////////////
  List<PopupMenuEntry<String>> _getMenu() {
    return <PopupMenuEntry<String>>[
      //////////////////////////////////////////////////////////
      // Edit-style options
      //////////////////////////////////////////////////////////
      PopupMenuItem(
        child: Row(
          children: [
            Icon(Icons.share, size: 25),
            SizedBox(width: 10),
            Text("Share"),
          ],
        ),
        value: "Share",
      ),
      PopupMenuItem(
        child: Row(
          children: [
            Icon(Icons.edit, size: 25),
            SizedBox(width: 10),
            Text("Rename"),
          ],
        ),
        value: "Rename",
      ),
      PopupMenuItem(
        child: Row(
          children: [
            Icon(Icons.delete, size: 25),
            SizedBox(width: 10),
            Text("Delete"),
          ],
        ),
        value: "Delete",
      ),
    ];
  }

  ////////////////////////////////////////////////////////////////
  // Takes in the current tab index and returns the appropriate
  // screen to display.
  ////////////////////////////////////////////////////////////////
  Widget _getScreenToDisplay(int currentTabIndex) {
    if (currentTabIndex == BottomNavSelection.HOME_SCREEN.index)
      return ScreenHome();
    else if (currentTabIndex == BottomNavSelection.SEARCH_SCREEN.index)
      return ScreenSearch();
    else if (currentTabIndex == BottomNavSelection.GROUPS_SCREEN.index)
      return ScreenGroups();
    else if (currentTabIndex == BottomNavSelection.MESSAGES_SCREEN.index)
      return ScreenMessages();
    else
      return ScreenHome();
  }

  ////////////////////////////////////////////////////////////////
  // Takes in the current tab index and returns the appropriate
  // app bar widget to display.
  ////////////////////////////////////////////////////////////////
  Widget _getAppBarTitle(int currentTabIndex) {
    if (currentTabIndex == BottomNavSelection.HOME_SCREEN.index)
      return Text("Home");
    else if (currentTabIndex == BottomNavSelection.SEARCH_SCREEN.index)
      return Text("Search");
    else if (currentTabIndex == BottomNavSelection.GROUPS_SCREEN.index)
      return Text("Groups");
    else if (currentTabIndex == BottomNavSelection.MESSAGES_SCREEN.index)
      return Text("Messages");
    else
      return ScreenHome();
  }

  ////////////////////////////////////////////////////////////////
  // Takes in the current tab index and returns the appropriate
  // actions to display in the app bar (right side).
  ////////////////////////////////////////////////////////////////
  List<Widget>? _getAppBarActions(int currentTabIndex) {
    // Initialize the actions
    List<Widget> actions = [];

    // If not chat tab, return null (no actions)
    return actions.isEmpty ? null : actions;
  }

  ////////////////////////////////////////////////////////////////
  // Primary Flutter method overriden which describes the layout
  // and bindings for this widget.
  ////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    // Get providers
    final currentTabIndex = ref.watch(providerPrimaryBottomNavTabIndex);

    // Return the scaffold
    return Scaffold(
      appBar: WidgetPrimaryAppBar(
        // Add a plus icon followed by the 3-dots vertical icon on the right
        actionButtons: _getAppBarActions(currentTabIndex),
        title: _getAppBarTitle(currentTabIndex),
      ),
      drawer: WidgetAppDrawer(),
      body: _getScreenToDisplay(currentTabIndex),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: currentTabIndex,
      //   onTap: (index) {
      //     ref.read(providerPrimaryBottomNavTabIndex.notifier).state = index;
      //   },
      //   items: [
      //     BottomNavigationBarItem(
      //       label: "Home",
      //       activeIcon: Icon(FontAwesomeIcons.house),
      //       icon: Icon(FontAwesomeIcons.house),
      //     ),
      //     BottomNavigationBarItem(
      //       label: "Search",
      //       activeIcon: Icon(FontAwesomeIcons.magnifyingGlass),
      //       icon: Icon(FontAwesomeIcons.magnifyingGlass),
      //     ),
      //     BottomNavigationBarItem(
      //       label: "Messages",
      //       activeIcon: Icon(FontAwesomeIcons.envelope),
      //       icon: Icon(FontAwesomeIcons.envelope),
      //     ),
      //     BottomNavigationBarItem(
      //       label: "Profile",
      //       activeIcon: Icon(FontAwesomeIcons.envelope),
      //       icon: Icon(FontAwesomeIcons.envelope),
      //     ),
      //   ],
      // ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          ref.read(providerPrimaryBottomNavTabIndex.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Groups'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
