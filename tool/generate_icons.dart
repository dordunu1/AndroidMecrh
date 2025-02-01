import 'dart:io';
import 'package:rsvg/rsvg.dart';

void main() async {
  // Convert main icon
  final mainSvg = File('assets/images/app_icon.svg').readAsBytesSync();
  final mainRsvg = Rsvg.fromData(mainSvg);
  final mainPng = mainRsvg.renderToImage(width: 1024, height: 1024);
  File('assets/images/app_icon.png').writeAsBytesSync(mainPng);

  // Convert foreground icon
  final fgSvg = File('assets/images/app_icon_foreground.svg').readAsBytesSync();
  final fgRsvg = Rsvg.fromData(fgSvg);
  final fgPng = fgRsvg.renderToImage(width: 1024, height: 1024);
  File('assets/images/app_icon_foreground.png').writeAsBytesSync(fgPng);

  print('Icons generated successfully!');
} 