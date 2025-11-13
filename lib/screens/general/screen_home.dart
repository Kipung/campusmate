// -----------------------------------------------------------------------
// Filename: screen_home.dart
// Original Author: Dan Grissom
// Creation Date: 10/31/2024
// Copyright: (c) 2024 CSC322
// Description: This file contains the screen for a dummy home screen
//               history screen.

//////////////////////////////////////////////////////////////////////////
// Imports
//////////////////////////////////////////////////////////////////////////

// Flutter imports
import 'dart:async';

// Flutter external package imports
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// App relative file imports
import '../../util/message_display/snackbar.dart';

import 'dart:convert';
import '../../widgets/general/recommended_user.dart';
import 'dart:math';

//////////////////////////////////////////////////////////////////////////
// StateFUL widget which manages state. Simply initializes the state object.
//////////////////////////////////////////////////////////////////////////
class ScreenHome extends ConsumerStatefulWidget {
  static const routeName = '/home';

  @override
  ConsumerState<ScreenHome> createState() => _ScreenHomeState();
}

//////////////////////////////////////////////////////////////////////////
// The actual STATE which is managed by the above widget.
//////////////////////////////////////////////////////////////////////////
class _ScreenHomeState extends ConsumerState<ScreenHome> {
  // The "instance variables" managed in this state
  bool _isInit = true;

  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void didChangeDependencies() {
    // If first time running this code, update provider settings
    if (_isInit) {
      _init();
      _isInit = false;
      super.didChangeDependencies();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  ////////////////////////////////////////////////////////////////
  // Initializes state variables and resources
  ////////////////////////////////////////////////////////////////
  Future<void> _init() async {}

  //////////////////////////////////////////////////////////////////////////
  // Primary Flutter method overridden which describes the layout and bindings for this widget.
  //////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    // Return the scaffold
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote card
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD5C7AD),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                    color: const Color(0xFFF1EAD8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<String>(
                        // load the bundled JSON asset (correct path & spelling)
                        future: DefaultAssetBundle.of(
                          context,
                        ).loadString('assets/motivational_quotes.json'),
                        // builder to display the quote or a loading/error state
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const SizedBox(
                              height: 60,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          // handle error or no data
                          if (snapshot.hasError || snapshot.data == null) {
                            return const Text(
                              'Could not load quote',
                              style: TextStyle(fontSize: 24.0),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          // parse JSON and pick a random quote
                          final List<dynamic> quotes = jsonDecode(
                            snapshot.data!,
                          );
                          final quoteText = quotes.isNotEmpty
                              ? quotes[Random().nextInt(quotes.length)]
                                    .toString()
                              : 'No quotes available';

                          return Text(
                            quoteText,
                            style: const TextStyle(fontSize: 24.0),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '- Somebody Famous',
                        style: TextStyle(fontSize: 18.0),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // Header left-aligned
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 6.0,
              ),
              child: Text(
                'People You May Know',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 8.0),

            // Horizontal scrollable list of RecommendedUser widgets
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(width: 12.0),
                itemBuilder: (context, index) {
                  return const RecommendedUser();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
