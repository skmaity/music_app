import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:music_app/model/artist_model.dart';
import 'package:music_app/model/song_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FireStoreServices extends GetxController {
  RxList<MySongs> quickpicks = <MySongs>[].obs;
  RxList<MySongs> favorite = <MySongs>[].obs;
  RxList playlists = [].obs;
  RxList playlistsIds = [].obs;



  RxList<Artist> artistsList = <Artist>[].obs;
  RxList<String> artistsDocIdList = <String>[].obs;
  RxList<MySongs> artistsongs = <MySongs>[].obs;
  

  final db = FirebaseFirestore.instance;

  void getQuickPicks() async {
    quickpicks.clear();
    await db.collection('quickpicks').get().then((v) {
      for (var element in v.docs) {
        quickpicks.add(MySongs.fromJson(element.data()));
      }
    });
  }

  void getArtists() async {
    artistsList.clear();
    await db.collection('artists').get().then((v) {
      for (var element in v.docs) {
        artistsList.add(Artist.fromJson(element.data(), element.id));
      } 
    });
  }

  void getSongsUnderArtists(doc) async {
  
    artistsongs.clear();
    await db.collection('artists').doc(doc).collection('songs').get().then((v) {
      for (var element in v.docs) {
        artistsongs.add(MySongs.fromJson(element.data()));
      }
    });
  }

void getSongsFromFavorites() async { 
  try {
    favorite.clear(); // Clear the local list before fetching data
    final String deviceId = await getDeviceId();

    // Reference to the "songs" subcollection under the device's document
    final songsCollection = await db
        .collection('favorite')
        .doc(deviceId)
        .collection('songs')
        .get();

    // Iterate over each song document and convert it into a MySongs object
    for (var doc in songsCollection.docs) {
      favorite.add(MySongs.fromJson(doc.data()));
    }

    print("Fetched ${favorite.length} favorite songs.");
  } catch (e) {
    print("Error fetching favorite songs: $e");
  }
}


Future<bool> isSongInFavorites(String song) async { 
  bool isExist = false;
  try {
    final String deviceId = await getDeviceId();

    // Reference to the songs collection under the device's collection
    final songsCollection = await db
        .collection('favorite')
        .doc(deviceId)
        .collection('songs')
        .where('song', isEqualTo: song) 
        .get();

       isExist = songsCollection.docs.isNotEmpty;

    // Check if any documents match the query 
    print("Error checking song existence shubha: $isExist");

    return songsCollection.docs.isNotEmpty;
  } catch (e) {
    print("Error checking song existence: $e");
    return false;
  }
}


Future<bool> addSongToFavorites(MySongs song) async {
  try {
    final String deviceId = await getDeviceId();

    // Reference to the "favorites" collection and document for the device
    final deviceDoc = db.collection('favorite').doc(deviceId);

    // Add the song details along with the timestamp
    await deviceDoc.collection('songs').add({
      ...song.toJson(),
      'addedAt': FieldValue.serverTimestamp(), // Add Firestore server timestamp
    });

    print("Song added successfully!");
    return true;
  } catch (e) {
    print("Error adding song: $e");
    return false;
  }
}

// void deleteDocument(String collectionPath, String docId) async {
//   await firestore.collection(collectionPath).doc(docId).delete()
//     .then((_) {
//       print("Document successfully deleted");
//     }) 
//     .catchError((error) {
//       print("Error deleting document: $error");
//     });
// }

Future<bool> removeSongFromFavorites(MySongs song) async {
  try {
    final String deviceId = await getDeviceId();
    final deviceDoc = db.collection('favorite').doc(deviceId);

    // Query to find the song by songId
    final querySnapshot = await deviceDoc.collection('songs')
        .where('song', isEqualTo: song.song)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();  // Delete each matching document
    }

    print("Song removed successfully!");
    return true;
  } catch (e) {
    print("Error removing song: $e");
    return false;
  }
}


Future<List<Map<String, dynamic>>> searchSongs(String searchQuery) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    // Query the `songs` collection
    QuerySnapshot querySnapshot = await firestore
        .collection('songs')
        .where('title', isGreaterThanOrEqualTo: searchQuery)
        .where('title', isLessThanOrEqualTo: searchQuery + '\uf8ff')
        .get();

    // Convert query results to a list of maps
    List<Map<String, dynamic>> songs = querySnapshot.docs.map((doc) {
      return {
        'songid': doc['songid'],
        'title': doc['title'],
        'artist': doc['artist'],
        'song': doc['song'],
        'cover': doc['cover'],
      };
    }).toList();

    return songs;
  } catch (e) {
    print('Error searching songs: $e');
    return [];
  }
}

    // Function to get a unique device ID

Future<String> getDeviceId() async {
  const String deviceKey = 'unique_device_id';
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if a device ID already exists
  String? deviceId = prefs.getString(deviceKey);

  if (deviceId == null) {
    // Generate a new UUID
    const uuid = Uuid();
    deviceId = uuid.v4();
    await prefs.setString(deviceKey, deviceId); // Store the ID locally
  }

  return deviceId;
}

// void getPlaylists() async {
//   try {
//     playlists.clear(); // Clear the local list before fetching data
//     String deviceId = await getDeviceId();

//     // Reference to the "playlists" subcollection
//     final playListCollection = await db
//         .collection('userplaylists')
//         // .doc(deviceId)
//         // .collection('playlists')
//         .get();

//     // Check if the collection is empty
//     if (playListCollection.docs.isEmpty) {
//       print("No playlists found for the device.");
//       return;
//     }

//     // Iterate over each document in the "playlists" collection
//     for (var doc in playListCollection.docs) {
//       // Optional: Print document ID for debugging
//       print("Playlist ID: ${doc.id}");

//     playlistsIds.add(doc.id);
//       // Add the document data to the local playlists list
//       playlists.add(doc.data()
//       );
//     }

//     print("Fetched ${playlists.length} playlists.");
//   } catch (e) {
//     print("Error fetching playlist songs: $e");
//   }
// }


// Future<bool> addNewPlayList(String playListName) async {
//   try {
//     final String deviceId = await getDeviceId();

//     // Reference to the "favorites" collection and document for the device
//     final deviceDoc = db.collection('userplaylists').doc(deviceId);

//     // Add the song details along with the timestamp
//     // await deviceDoc.collection('playlists').add({
//     //   ...song.toJson(),
//     //   'addedAt': FieldValue.serverTimestamp(), // Add Firestore server timestamp
//     // });

//   await  deviceDoc
//   .collection(playListName)
//   .doc("song_003")
//   .set({
//     'title': "Levitating",
//     'artist': "Dua Lipa",
//     'album': "Future Nostalgia",
//     'duration': 203,
//     'url': "https://...",
//     'addedAt': DateTime.now(),
//   });


//     print("Song added successfully!");
//     return true;
//   } catch (e) {
//     print("Error adding song: $e");
//     return false;
//   }
// }
}


