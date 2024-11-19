import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/background_controller.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> {
final BackgroundController _backgroundController = Get.put(BackgroundController());

  @override
  Widget build(BuildContext context) {
    return
       Obx(
         ()=> AnimateGradient(
                    
                    primaryColors: _backgroundController.primaryColorsList,
                    secondaryColors:  _backgroundController.secondaryColorsList
                  
                  ),
       );

  } 
}