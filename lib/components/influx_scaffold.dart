import 'package:flutter/material.dart';
import 'package:iot_device_flutter/components/styles/influx_colors.dart'
    as influx_colors;

class InfluxScaffold extends StatelessWidget {
  const InfluxScaffold({required this.body, Key? key}) : super(key: key);

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              "assets/images/influxdata-logo.png",
              filterQuality: FilterQuality.low,
              height: 40,
              width: 40,
            ),
            const Text(" InfluxDB ",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Iot center device"),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  stops: [0, 0.8],
                  colors: influx_colors.primaryDark)),
        ),
      ),
      body: SafeArea(
        child:
            body, // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}
