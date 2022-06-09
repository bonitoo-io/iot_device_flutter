import 'package:battery_plus/battery_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Sensors can return multiple subfields.
///
/// For example sensor can return {"x": 10, "y": 20 ...}
///
/// If sensor returns only one value
///   then there will be only one entry with "" key
typedef SensorMeasurement = Map<String, double>;

typedef PermissionRequester = Future<Stream<SensorMeasurement>?> Function();

class SensorInfo {
  /// sensor or measurement name
  String name;
  String? sensorType;
  Stream<SensorMeasurement>? stream;

  bool get availeble {
    return (stream != null);
  }

  PermissionRequester? _permissionRequester;

  Future Function()? get requestPermission {
    if (_permissionRequester == null) return null;
    return (() async {
      stream = await _permissionRequester!();
      _permissionRequester = null;
    });
  }

  SensorInfo(this.name,
      {this.sensorType,
      this.stream,
      PermissionRequester? permissionRequester}) {
    _permissionRequester = permissionRequester;
  }
}

class Sensors {
  final _es = EnvironmentSensors();

  Stream<SensorMeasurement> get _accelerometer =>
      SensorsPlatform.instance.accelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _userAccelerometer =>
      SensorsPlatform.instance.userAccelerometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _gyroscope =>
      SensorsPlatform.instance.gyroscopeEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _magnetometer =>
      SensorsPlatform.instance.magnetometerEvents
          .map((event) => {"x": event.x, "y": event.y, "z": event.z});

  Stream<SensorMeasurement> get _battery async* {
    final battery = Battery();
    final SensorMeasurement batteryLastState = {};
    bool changed = true;

    setField(String name, double value) {
      if (batteryLastState[name] != value) {
        changed = true;
        batteryLastState[name] = value;
      }
    }

    await for (var _ in Stream.periodic(const Duration(seconds: 1))) {
      final level = (await battery.batteryLevel).toDouble();
      setField("level", level);

      final state = (await battery.batteryState);
      if (state != BatteryState.unknown) {
        setField("charging", state == BatteryState.charging ? 1 : 0);
      }

      if (changed) {
        changed = false;
        yield Map.from(batteryLastState);
      }
    }
  }

  Future<Stream<SensorMeasurement>?> get _temperature async =>
      (await _es.getSensorAvailable(SensorType.AmbientTemperature))
          ? EnvironmentSensors().temperature.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _humidity async =>
      (await _es.getSensorAvailable(SensorType.Humidity))
          ? EnvironmentSensors().humidity.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _light async =>
      (await _es.getSensorAvailable(SensorType.Light))
          ? EnvironmentSensors().light.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _pressure async =>
      (await _es.getSensorAvailable(SensorType.Pressure))
          ? EnvironmentSensors().pressure.map((x) => {"": x})
          : null;

  Future<Stream<SensorMeasurement>?> get _geo async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    return (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse)
        ? Geolocator.getPositionStream().map((pos) {
            // TODO: more metrics
            return {
              "lat": pos.latitude,
              "lon": pos.longitude,
              "acc": pos.accuracy
            };
          })
        : null;
  }

  Future<PermissionRequester?> get _geoRequester async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) return null;

    return () async {
      await Geolocator.requestPermission();
      return await _geo;
    };
  }

  Future<List<SensorInfo>> get sensors async => <SensorInfo>[
        SensorInfo("Accelerometer", stream: _accelerometer),
        SensorInfo("UserAccelerometer", stream: _userAccelerometer),
        SensorInfo("Magnetometer", stream: _magnetometer),
        SensorInfo("Battery", stream: _battery),
        SensorInfo("Temperature", stream: await _temperature),
        SensorInfo("Humidity", stream: await _humidity),
        SensorInfo("Light", stream: await _light),
        SensorInfo("Pressure", stream: await _pressure),
        SensorInfo("Geo",
            stream: await _geo, permissionRequester: await _geoRequester),
      ];
}
