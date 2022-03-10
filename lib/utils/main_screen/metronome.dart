import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

enum MetronomeState { Playing, Stopped, Stopping }

const double FAST = 200;
const double MEDIUM_FAST = 150;
const double MEDIUM = 100;
const double MEDIUM_SLOW = 60;

class MetronomeControl extends StatefulWidget {
  MetronomeControl();

  MetronomeControlState createState() => new MetronomeControlState();
}

class MetronomeControlState extends State<MetronomeControl> {
  MetronomeControlState();

  Soundpool pool = Soundpool.fromOptions();
  int soundId = -1;
  double _tempo = 60;

  MetronomeState _metronomeState = MetronomeState.Stopped;
  Timer? _tickTimer = Timer(const Duration(days: 1000), () {});

  @override
  void initState() {
    initiateSoundPool();
    super.initState();
  }

  void _start() {
    _metronomeState = MetronomeState.Playing;

    _tickTimer = Timer(_getTickInterval(), _onTick);

    SystemSound.play(SystemSoundType.click);

    if (mounted) setState(() {});
  }

  Duration _getTickInterval() {
    double bps = _tempo / 60;
    int _tickInterval = 1000 ~/ bps;
    return Duration(milliseconds: _tickInterval);
  }

  void _onTick() {
    if (_metronomeState == MetronomeState.Playing) {
      pool.play(soundId);
      _tickTimer = Timer(_getTickInterval(), _onTick);
    } else if (_metronomeState == MetronomeState.Stopping) {
      _tickTimer?.cancel();
      _metronomeState = MetronomeState.Stopped;
    }
  }

  void _stop() {
    _metronomeState = MetronomeState.Stopping;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _tempo.toString().length == 3
              ? _tempo.toString() + " BPM"
              : "  " + _tempo.toString() + " BPM",
          style: TextStyle(
              color: _tempo > FAST
                  ? Colors.red
                  : _tempo > MEDIUM_FAST
                      ? Colors.yellow
                      : _tempo > MEDIUM
                          ? Colors.green
                          : _tempo > MEDIUM_SLOW
                              ? Colors.blue
                              : Colors.purple),
        ),
        IconButton(
            onPressed: () {
              if (_tempo > 40) {
                setState(() {
                  _tempo--;
                });
              }
            },
            icon: Icon(
              Icons.remove,
              color: _tempo > FAST
                  ? Colors.red
                  : _tempo > MEDIUM_FAST
                      ? Colors.yellow
                      : _tempo > MEDIUM
                          ? Colors.green
                          : _tempo > MEDIUM_SLOW
                              ? Colors.blue
                              : Colors.purple[800],
            )),
        Slider(
          value: _tempo,
          min: 40,
          max: 220,
          divisions: 180,
          onChanged: (double value) {
            setState(() {
              _tempo = value;
            });
          },
        ),
        IconButton(
            onPressed: () {
              if (_tempo < 220) {
                setState(() {
                  _tempo++;
                });
              }
            },
            icon: Icon(
              Icons.add,
              color: _tempo > FAST
                  ? Colors.red
                  : _tempo > MEDIUM_FAST
                      ? Colors.yellow
                      : _tempo > MEDIUM
                          ? Colors.green
                          : _tempo > MEDIUM_SLOW
                              ? Colors.blue
                              : Colors.purple[800],
            )),
        IconButton(
            onPressed: () {
              if (_metronomeState == MetronomeState.Playing) {
                _stop();
              } else {
                _start();
              }
            },
            icon: _metronomeState == MetronomeState.Playing
                ? const Icon(
                    Icons.stop_circle,
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                  ))
      ],
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void initiateSoundPool() async {
    soundId = await rootBundle
        .load("assets/click_60bpm_4-4time_2beats_stereo_O9JUk5.mp3")
        .then((ByteData soundData) {
      return pool.load(soundData);
    });
  }
}
