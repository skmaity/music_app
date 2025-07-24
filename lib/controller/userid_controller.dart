import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UseridController extends GetxController {
  RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');

    if (storedUserId != null && storedUserId.isNotEmpty) {
      userId.value = storedUserId;
    } else {
      String newUserId = const Uuid().v4(); // generates a unique ID
      await prefs.setString('user_id', newUserId);
      userId.value = newUserId;
    }
  }
}
