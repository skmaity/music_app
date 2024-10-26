import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:music_app/model/song_model.dart';

class FireStoreServices extends GetxController{

@override
  void onInit() {
   getSongsStream();
    super.onInit();
  }

  RxList<MySongs> quickpicks = <MySongs>[].obs;

  final  db = FirebaseFirestore.instance;


  //reade 
void  getSongsStream()async{
    quickpicks.clear();
    await db.collection('quickpicks').get().then((v){
for (var element in v.docs) {
quickpicks.add(MySongs.fromJson(element.data()));
}
    });
    
  }
}
