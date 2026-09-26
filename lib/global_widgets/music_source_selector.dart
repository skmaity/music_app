import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/music_source_controller.dart';
import 'package:music_app/model/track_ref.dart';

class MusicSourceSelector extends StatelessWidget {
  const MusicSourceSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MusicSourceController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.sm,
      ),
      child: Obx(
        () => Semantics(
          label: 'Browsing source',
          child: SegmentedButton<TrackSource>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: TrackSource.local,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Local', maxLines: 1),
                ),
              ),
              ButtonSegment(
                value: TrackSource.nyroServer,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Nyro Server', maxLines: 1),
                ),
              ),
              ButtonSegment(
                value: TrackSource.youtube,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('YouTube', maxLines: 1),
                ),
              ),
            ],
            selected: {controller.selectedSource.value},
            onSelectionChanged: (selection) {
              controller.selectSource(selection.single);
            },
          ),
        ),
      ),
    );
  }
}
