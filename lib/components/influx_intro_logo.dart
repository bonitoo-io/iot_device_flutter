import 'package:flutter/cupertino.dart';
import 'package:iot_device_flutter/components/styles/influx_colors.dart'
    as influx_colors;

class InfluxIntroLogo extends StatelessWidget {
  const InfluxIntroLogo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(50),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [
            0,
            0.6,
          ],
          colors: influx_colors.primaryDark,
        )),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/influxdata-logo.png"),
                fit: BoxFit.contain),
          ),
        ));
  }
}
