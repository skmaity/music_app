import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const SizedBox(
              height: 10,
            ),

            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 10, top: 40),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 45, color: Colors.white),
                  ),
                ),
                SizedBox(
                  width: 10, 
                )
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/icons/megaphone.png',
                        height: 45,
                      ),
                      const SizedBox(height: 10,),
                      const Text(
                        'Coming soon..',
                        style: TextStyle(fontSize: 25, color: Colors.white),
                      ),
                      const SizedBox(height: 2,), 
                       Text(
                        textAlign:  TextAlign.center,
                        'We are working hard to bring\nyou this feature.',
                        style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(150)),
                      ),
                    ],
                  ),
                ],
              ), 
            ),
            const SizedBox(
              height: 70,
            ),
          ],
        ));
  }
}
