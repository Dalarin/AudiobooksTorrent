// ignore_for_file: avoid_print, sized_box_for_whitespace, must_be_immutable, use_key_in_widget_constructors

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../bloc/audio_bloc/audio_bloc.dart';
import '../bloc/book_bloc/book_bloc.dart';
import '../models/book.dart';

class AudioPage extends StatelessWidget {
  final Book book;
  final List<Book> books;

  const AudioPage({
    Key? key,
    required this.book,
    required this.books,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AudioBloc>(
      create: (context) {
        return AudioBloc(
          book: book,
          books: books,
          bookBloc: context.read<BookBloc>(),
        )..add(InitializeAudio(book: book));
      },
      child: Scaffold(
        body: BlocConsumer<AudioBloc, AudioState>(
          listener: (context, state) {
            if (state is AudioError) {
              _showSnackBar(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is AudioLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is AudioInitialized) {
              return _audioPageContent(
                context: context,
                books: books,
                book: book,
                audioPlayer: state.audioPlayer,
              );
            } else if (state is AudioError) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    final bloc = context.read<AudioBloc>();
                    bloc.add(InitializeAudio(book: book));
                  },
                  child: const Text('Повторить попытку'),
                ),
              );
            }
            return Container();
          },
        ),
      ),
    );
  }

  Stream<PositionData> _positionDataStream(AudioPlayer player) {
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      player.positionStream,
      player.bufferedPositionStream,
      player.durationStream,
      (position, bufferedPosition, duration) {
        return PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        );
      },
    );
  }

  Widget _audioPageContent({
    required BuildContext context,
    required Book book,
    required List<Book> books,
    required AudioPlayer audioPlayer,
  }) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _seekBar(context, audioPlayer),
          _controlButtons(context, book, books, audioPlayer),
        ],
      ),
    );
  }

  Widget _controlButtons(
    BuildContext context,
    Book book,
    List<Book> books,
    AudioPlayer player,
  ) {
    final bloc = context.read<AudioBloc>();
    return ControlButtons(book, player, bloc, books);
  }

  Widget _seekBar(BuildContext context, AudioPlayer player) {
    return StreamBuilder<PositionData>(
      stream: _positionDataStream(player),
      builder: (context, snapshot) {
        final positionData = snapshot.data;
        return SeekBar(
          duration: positionData?.duration ?? Duration.zero,
          position: positionData?.position ?? Duration.zero,
          bufferedPosition: positionData?.bufferedPosition ?? Duration.zero,
          onChangeEnd: (newPosition) {
            player.seek(newPosition);
          },
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;
  final Book book;
  final List<Book> books;
  final AudioBloc audioBloc;

  const ControlButtons(this.book, this.player, this.audioBloc, this.books, {Key? key}) : super(key: key);

  void _selectChaptersDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      scrollable: true,
      title: const Text("Главы"),
      content: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.3,
        child: StreamBuilder<SequenceState?>(
          stream: player.sequenceStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            final sequence = state?.sequence ?? [];
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.25,
              child: ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                itemCount: sequence.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    child: Text(sequence[index].tag.title),
                    onTap: () {
                      player.seek(Duration.zero, index: index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _selectChaptersDialog(context),
          icon: const Icon(Icons.library_music_outlined),
        ),
        IconButton(
          onPressed: () {
            final bloc = context.read<AudioBloc>();
            bloc.add(const SkipSeconds(seconds: -10));
          },
          icon: const Icon(Icons.replay_10_rounded),
        ),
        StreamBuilder<SequenceState?>(
          stream: player.sequenceStateStream,
          builder: (context, snapshot) => IconButton(
            icon: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(pi),
              child: const Icon(Icons.double_arrow_rounded),
            ),
            onPressed: player.hasPrevious ? player.seekToPrevious : null,
          ),
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause_circle_rounded),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              book.listeningInfo.isCompleted = true;
              final bloc = context.read<BookBloc>();
              bloc.add(UpdateBook(book: book, books: books));
              return IconButton(
                icon: const Icon(Icons.replay_circle_filled),
                iconSize: 64.0,
                onPressed: () {
                  player.seek(Duration.zero, index: player.effectiveIndices!.first);
                  book.listeningInfo.isCompleted = false;
                  bloc.add(UpdateBook(book: book, books: books));
                },
              );
            }
          },
        ),
        StreamBuilder<SequenceState?>(
          stream: player.sequenceStateStream,
          builder: (context, snapshot) => IconButton(
            icon: const Icon(Icons.double_arrow_rounded),
            onPressed: player.hasNext ? player.seekToNext : null,
          ),
        ),
        IconButton(
          onPressed: () {
            final bloc = context.read<AudioBloc>();
            bloc.add(const SkipSeconds(seconds: 10));
          },
          icon: const Icon(Icons.forward_10_outlined),
        ),
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) {
            return IconButton(
              icon: Text(
                "${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                _selectAudioSpeedDialog(
                  context: context,
                  title: "Регулировка скорости",
                  divisions: 10,
                  min: 0.8,
                  max: 2.0,
                  stream: player.speedStream,
                  onChanged: player.setSpeed,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ExcludeSemantics(
          child: Slider(
            min: 0.0,
            max: widget.duration.inMilliseconds.toDouble(),
            value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(), widget.duration.inMilliseconds.toDouble()),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              });
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
            RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$').firstMatch("$_remaining")?.group(1) ?? '$_remaining',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

void _selectAudioSpeedDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  required Stream<double> stream,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(32.0),
          ),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: StreamBuilder<double>(
          stream: stream,
          builder: (context, snapshot) => Container(
            height: 100.0,
            child: Column(
              children: [
                Text(
                  '${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
                Slider(
                  divisions: divisions,
                  min: min,
                  max: max,
                  value: snapshot.data ?? 1.0,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
