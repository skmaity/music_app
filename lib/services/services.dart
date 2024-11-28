import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:music_app/model/song_model.dart';

class FireStoreServices extends GetxController{

@override
  void onInit() {
  getSongsStream();
  getArtist();
    super.onInit();
  }

  RxList<MySongs> quickpicks = <MySongs>[].obs;
  final  db = FirebaseFirestore.instance;


void  getSongsStream()async{
    quickpicks.clear();
    await db.collection('quickpicks').get().then((v){
for (var element in v.docs) {
quickpicks.add(MySongs.fromJson(element.data()));
}
  }
); 
}

void getArtist() async {
  try {
    // Fetch the snapshot of the 'artists' collection
    var snapshot = await db.collection('artists').get();
    
    // Iterate over all documents and print their data
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}');
      print('Data: ${doc.data()}');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}

}
