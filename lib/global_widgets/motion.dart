import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/settings_controller.dart';

/// True when the platform asks for reduced motion, or when Settings does.
///
/// The background gradient loops forever and the now-playing marker is a
/// looping Lottie; both need to hold still when this is set.
///
/// The two sources are OR'd rather than the setting overriding the platform:
/// a phone-wide "reduce motion" is an accessibility need, and an in-app
/// toggle has no business turning it back off.
///
/// Reading the observable here rather than in an `Obx` is deliberate. Call
/// sites already inside one (the dashboard's page switcher) react the instant
/// the toggle flips; the rest — song rows, skeletons, the scrolling title —
/// pick it up on their next build, which is the same frame the user leaves
/// Settings on. A `GetBuilder` around every one of them would buy nothing a
/// user could see.
bool noMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations ||
    Get.find<SettingsController>().reducedMotion.value;

/// List-entrance stagger — slide up and in, fading, [Motion.stagger] apart.
/// Returns [child] untouched under reduced motion.
///
/// Two things were wrong with the old version. It staggered 100ms per item
/// against Material's 20–50, so a 20-row list took two full seconds to finish
/// appearing. And it slid rows in horizontally *from the right* while the page
/// itself was sliding in from the right — two competing right-to-left motions
/// on the same frame. Rows now only move on the axis the list scrolls on.
///
/// Pass [columnCount] for a grid so the stagger runs diagonally across it
/// rather than one cell at a time down the reading order.
Widget staggeredEntrance(
  BuildContext context,
  int index,
  Widget child, {
  int columnCount = 1,
}) {
  if (noMotion(context)) return child;

  final slide = SlideAnimation(
    // Vertical only. No horizontalOffset — that is the point.
    verticalOffset: 50,
    duration: Motion.normal,
    curve: Motion.enter,
    child: FadeInAnimation(
      duration: Motion.normal,
      curve: Motion.enter,
      child: child,
    ),
  );

  if (columnCount > 1) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      columnCount: columnCount,
      delay: Motion.stagger,
      child: slide,
    );
  }

  return AnimationConfiguration.staggeredList(
    position: index,
    delay: Motion.stagger,
    child: slide,
  );
}
