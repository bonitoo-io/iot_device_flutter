import 'package:flutter/material.dart';
import 'package:iot_device_flutter/components/styles/influx_colors.dart'
    as influx_colors;

final influxThemeData = ThemeData.from(
  colorScheme: const ColorScheme.dark(
    background: Color(0xff181820),
    surface: Color(0xFF292933),
  ),
  textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: const Color(0xC0FFFFFF),
        fontFamily: "Rubik",
      ),
).copyWith(
  toggleableActiveColor: influx_colors.pool,
);
