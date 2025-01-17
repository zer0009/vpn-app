class TrafficStats {
  final double downloadSpeed; // in MB/s
  final double uploadSpeed; // in MB/s
  final int bytesIn;
  final int bytesOut;
  final Duration duration;
  final int ping;

  const TrafficStats({
    this.downloadSpeed = 0.0,
    this.uploadSpeed = 0.0,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.duration = Duration.zero,
    this.ping = 0,
  });

  factory TrafficStats.fromData({
    required double downloadSpeed,
    required double uploadSpeed,
    required int bytesIn,
    required int bytesOut,
    required Duration duration,
    required int ping,
  }) {
    return TrafficStats(
      downloadSpeed: downloadSpeed,
      uploadSpeed: uploadSpeed,
      bytesIn: bytesIn,
      bytesOut: bytesOut,
      duration: duration,
      ping: ping,
    );
  }

  TrafficStats copyWith({
    double? downloadSpeed,
    double? uploadSpeed,
    int? bytesIn,
    int? bytesOut,
    Duration? duration,
    int? ping,
  }) {
    return TrafficStats(
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      duration: duration ?? this.duration,
      ping: ping ?? this.ping,
    );
  }

  @override
  String toString() {
    return 'TrafficStats(downloadSpeed: $downloadSpeed, uploadSpeed: $uploadSpeed, bytesIn: $bytesIn, bytesOut: $bytesOut, duration: $duration, ping: $ping)';
  }
} 