// this is going to be a screen for calendar within a group detail view
import 'package:flutter/material.dart';
import 'package:campusmate/models/groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campusmate/screens/general/screen_group/screen_groups.dart';
import 'package:campusmate/providers/provider_groups.dart';
import 'package:campusmate/providers/provider_auth.dart';
import 'package:campusmate/providers/provider_groups.dart';
import 'package:campusmate/db_helpers/db_chat.dart';
import 'package:go_router/go_router.dart';

import 'package:kalender/kalender.dart';

//////////////////////////////////////////////////////////////////////////
/// StateFUL widget which manages state. Simply initializes the state object.
/// ////////////////////////////////////////////////////////////////////////
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, required this.group});

  static const routeName = '/group_calendar';

  final Groups group;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

//////////////////////////////////////////////////////////////////////////
/// The actual STATE which is managed by the above widget.
/// ////////////////////////////////////////////////////////////////////////
class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // The "instance variables" managed in this state
  late Groups group;
  DateTime? _lastTapped;
  ////////////////////////////////////////////////////////////////
  // Runs the following code once upon initialization
  ////////////////////////////////////////////////////////////////
  @override
  void initState() {
    super.initState();
    group = widget.group;
    addEvents(); // ← add a sample event
  }

  final eventsController = DefaultEventsController();
  final calendarController = CalendarController();
  final now = DateTime.now();

  void addEvents() {
    // Here you can add events to the eventsController
    // For example:
    eventsController.addEvent(
      CalendarEvent(
        dateTimeRange: DateTimeRange(
          start: now,
          end: now.add(const Duration(hours: 1)),
        ),
        data: "Event 1",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.groupName),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              calendarController.animateToPreviousPage();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              calendarController.animateToNextPage();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CalendarView(
                eventsController: eventsController,
                calendarController: calendarController,
                viewConfiguration: MultiDayViewConfiguration.week(),
                callbacks: CalendarCallbacks(
                  onEventTapped: (event, renderBox) =>
                      calendarController.selectEvent(event),
                  onTapped: (date) {
                    setState(() {
                      _lastTapped = date;
                    });
                  },

                  onEventCreate: (event) => event.copyWith(data: "Some data"),
                  onEventCreated: (event) => eventsController.addEvent(event),
                ),
                header: CalendarHeader(),
                body: CalendarBody(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final start = (_lastTapped ?? DateTime.now());
          final end = start.add(const Duration(hours: 1));
          final newEvent = CalendarEvent(
            dateTimeRange: DateTimeRange(start: start, end: end),
            data: "New Event",
          );
          eventsController.addEvent(newEvent);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
