import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fixnum/fixnum.dart';

/// Blockies widget with customized painter
///
/// [size] - number of blocks on x and y axis
/// [color] - main color of the identicon (43% probability)
/// [bgColor] - background color of the identicon (43% probability)
/// [spotColor] - additional color of the identicon (13% probability)
class Blockies extends StatelessWidget {
  const Blockies({
    required this.seed,
    this.size = 10,
    this.color, // 43% probability
    this.bgColor, // 43% probability
    this.spotColor, // 13% probability
    super.key,
  });

  final String seed;
  final int size;
  final Color? color;
  final Color? bgColor;
  final Color? spotColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlockiesPainter(
        seed: seed,
        size: size,
        color: color,
        bgColor: bgColor,
        spotColor: spotColor,
      ),
      isComplex: true,
      willChange: false,
    );
  }
}

class _BlockiesPainter extends CustomPainter {
  _BlockiesPainter({
    required this.seed,
    this.size = 8,
    this.color,
    this.bgColor,
    this.spotColor,
  });

  final String seed;
  final int size;
  final Color? color;
  final Color? bgColor;
  final Color? spotColor;

  @override
  void paint(Canvas canvas, Size size) {
    _randSeed = _createRandSeed(seed: seed);
    // NOTE: keep the same order otherwise the resulting blocky will be affected
    final colorPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color ?? _createColor();
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = bgColor ?? _createColor();
    final spotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = spotColor ?? _createColor();

    final imageData = _createImageData(this.size);
    final width = sqrt(imageData.length);
    final blockSize = Size(size.width / this.size, size.height / this.size);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (var i = 0; i < imageData.length; i++) {
      // if data is 0, leave the background
      if (imageData[i] != 0) {
        final row = (i / width).floor();
        final col = (i % width).floor();

        // if data is 2, choose spot color, if 1 choose foreground
        canvas.drawRect(
            Rect.fromLTWH(col * blockSize.width, row * blockSize.height,
                blockSize.width + 1, blockSize.height + 1),
            (imageData[i] == 1) ? colorPaint : spotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  List<int> _createRandSeed({required String seed}) {
    var randSeed = List<int>.filled(4, 0);

    for (int i = 0; i < seed.length; i++) {
      // Note: JS << treats arguments as 32bit numbers with result being 32bit as well
      randSeed[i % 4] = Int32(randSeed[i % 4] << 5).toInt() -
          randSeed[i % 4] +
          seed.codeUnitAt(i);
    }
    return randSeed;
  }

  double _rand() {
    // based on Java's String.hashCode(), expanded to 4 32bit values
    final t = Int32(_randSeed[0] ^ Int32(_randSeed[0] << 11).toInt());
    final third = Int32(_randSeed[3]);

    _randSeed[0] = _randSeed[1];
    _randSeed[1] = _randSeed[2];
    _randSeed[2] = _randSeed[3];
    _randSeed[3] = ((third ^ (third >> 19)) ^ t ^ (t >> 8)).toInt();

    return (Int32(_randSeed[3] >>> 0)).toInt() / ((1 << 31) >>> 0);
  }

  Color _createColor() {
    //saturation is the whole color spectrum
    final h = (_rand() * 360).floorToDouble();
    //saturation goes from 40 to 100, it avoids greyish colors
    final s = ((_rand() * 60) + 40);
    //lightness can be anything from 0 to 100, but probabilities are a bell curve around 50%
    final l = ((_rand() + _rand() + _rand() + _rand()) * 25);
    return HSLColor.fromAHSL(1, h, s / 100, l / 100).toColor();
  }

  List<int> _createImageData(int size) {
    final width = size; // Only support square icons for now
    final height = size;

    final dataWidth = (width / 2).ceil();
    final mirrorWidth = width - dataWidth;

    var data = <int>[];
    for (var y = 0; y < height; y++) {
      var row = <int>[];
      for (var x = 0; x < dataWidth; x++) {
        // this makes foreground and background color to have a 43% (1/2.3) probability
        // spot color has 13% chance
        row.add((_rand() * 2.3).floor());
      }
      final r = row.sublist(0, mirrorWidth).toList();
      row.addAll(r.reversed.toList());

      for (var i = 0; i < row.length; i++) {
        data.add(row[i]);
      }
    }

    return data;
  }

  // PRIVATE:
  List<int> _randSeed = [];
}
