class DeviceInfo {
  final String deviceId;
  final String os;
  final String osVersion;
  final String appVersion;
  final String manufacturer;
  final String model;

  DeviceInfo({
    required this.deviceId,
    required this.os,
    required this.osVersion,
    required this.appVersion,
    required this.manufacturer,
    required this.model,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      os: json['os'] as String,
      osVersion: json['osVersion'] as String,
      appVersion: json['appVersion'] as String,
      manufacturer: json['manufacturer'] as String,
      model: json['model'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'os': os,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'manufacturer': manufacturer,
      'model': model,
    };
  }
}
