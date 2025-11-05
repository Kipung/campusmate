import 'package:flutter/material.dart';

class RecommendedUser extends StatefulWidget {
  const RecommendedUser({Key? key}) : super(key: key);

  @override
  _RecommendedUserState createState() => _RecommendedUserState();
}

class _RecommendedUserState extends State<RecommendedUser> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        // color: Colors.white,
        border: Border.all(color: const Color(0xFFD5C7AD), width: 4.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle, size: 72, color: Color(0xFF2D2D1F)),
          const SizedBox(height: 12.0),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D1F),
            ),
          ),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFD8DCC1),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Add Friend',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
