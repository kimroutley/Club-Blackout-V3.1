import '../models/script_step.dart';

class GameScript {
  static const List<ScriptStep> intro = [
    ScriptStep(
      id: 'intro_party_time',
      title: 'Start',
      readAloudText:
          "Read aloud: It's party time! Music's pumping, drinks are flowing, club is PACKED.\n\nEveryone, close your eyes.\nLights out... Don't lose your head... yet.\nNo sneaky peeks!",
      instructionText:
          'Host: Wait for 10-15 seconds of silence. Transition immediately to setup or night actions.\n\nVoice: Deep, clear, and authoritative.\nPacing: Slow down. Silence creates tension.',
      isNight: true,
    ),
  ];
}
