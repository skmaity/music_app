import 'package:flutter/material.dart';

class Artists extends StatefulWidget {
  const Artists({super.key});

  @override
  State<Artists> createState() => _ArtistsState();
}

class _ArtistsState extends State<Artists> {
  // List<String> artist = [
  //   'assets/arijit.jfif',
  //   'assets/billieeilish.jfif',
  //   'assets/justinbieber.jfif',
  //   'assets/theweeknd.jfif',
  //   'assets/postmelone.jfif',
  // ];

  int listLength = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
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
                        'Artists',
                        style: TextStyle(fontSize: 45, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    )
                  ],
                ),
               SizedBox(
  height: MediaQuery.of(context).size.height + 800,
  child: ListView.builder(
    itemCount: (listLength / 5).ceil() + 1, // First list + grouped lists
    itemBuilder: (context, index) {
      if (index == 0) {
        // First list: UI for the top horizontal list
        return Column(
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: listLength >= 5 ? 5 : listLength,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.all(
                                Radius.circular(100),
                              ),
                              child: Image(
                                height: 130,
                                width: 130,
                                image: AssetImage('assets/arijit.jfif'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Arijit Sing',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Text(
                    'More',
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Image(
                      image: AssetImage('assets/vectors/album_line2.png'),
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      } 
      else{
   // Remaining lists: Group remaining items in batches of 5
        int startIndex = (index - 1) * 5 + 5;
        int endIndex = startIndex + 5;
        int remainingItems = listLength - startIndex;

        if (remainingItems <= 0) return const SizedBox.shrink();

        int itemCount = remainingItems >= 5 ? 5 : remainingItems;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: itemCount,
                itemBuilder: (context, subIndex) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image(
                              image: AssetImage('assets/arijit.jfif'),
                              fit: BoxFit.cover,
                              width: 110,
                              height: 110,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Arijit Sing',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          const SizedBox(
                            width: 110,
                            child: Text(
                              'Arijit Sing,alka yatri,kumar sanu',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    },
  ),
),
              ],
            ),
          ),
        ));
  }
}
