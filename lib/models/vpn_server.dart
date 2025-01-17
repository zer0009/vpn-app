import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VpnServer {
  final String id;
  final String country;
  final String city;
  final String flag;
  final String ovpnConfiguration;
  int ping;
  final String ip;
  final bool isPremium;
  final String hostname;
  final int port;
  final String protocol;
  final String? countryLong;
  final int? numVpnSessions;
  final double? uptime;
  final double? totalUsers;
  final String? speed;
  final String? configData;
  final double load;
  final double bandwidth;
  final bool hasDoubleVPN;
  final String configPath;
  bool isFavorite;

  VpnServer({
    required this.id,
    required this.country,
    required this.city,
    String? flag,
    required this.ovpnConfiguration,
    this.ping = 0,
    required this.ip,
    this.isPremium = false,
    required this.hostname,
    required this.port,
    required this.protocol,
    this.countryLong,
    this.numVpnSessions,
    this.uptime,
    this.totalUsers,
    this.speed,
    this.configData,
    this.load = 0.0,
    this.bandwidth = 0.0,
    this.hasDoubleVPN = false,
    required this.configPath,
    this.isFavorite = false,
  }) : this.flag = flag ?? 'assets/flags/default_flag.png';

  String get flagAsset {
    return flag.isNotEmpty ? flag : 'assets/flags/default_flag.png';
  }

  Future<String> getConfig() async {
    if (configData != null && configData!.isNotEmpty) {
      try {
        final bytes = base64.decode(configData!);
        return utf8.decode(bytes);
      } catch (e) {
        debugPrint('Error decoding config: $e');
        throw Exception('Failed to decode OpenVPN config');
      }
    }
    throw Exception('No OpenVPN config data available');
  }

  String get serverName => '$country - $city';

  static Future<List<VpnServer>> getVPNGateServers() async {
    final urls = [
      'http://164.70.86.55:53336/api/iphone/',
      'http://222.255.11.117:54621/api/iphone/',
      'http://38.146.27.9:11602/api/iphone/',
      'http://58.70.80.237:60656/api/iphone/',
      'http://218.147.63.115:23602/api/iphone/',
      'http://221.253.212.68:32715/api/iphone/',
      // Keep a few backup URLs
      'http://vpn.vpngate.net/api/iphone/',
      'https://vpngate.cdngate.com/api/iphone/',
    ];

    for (var url in urls) {
      try {
        debugPrint('Fetching servers from: $url');
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final List<String> lines = const LineSplitter()
              .convert(response.body)
              .where((line) => !line.startsWith('*'))
              .skip(1)
              .toList();

          if (lines.isEmpty) continue;

          final List<VpnServer> servers = [];

          for (var line in lines) {
            try {
              final fields = line.split(',');
              if (fields.length < 15) continue;

              // Validate the OpenVPN config data
              final openVPNConfigData = fields[14];
              try {
                final bytes = base64.decode(openVPNConfigData);
                final configContent = utf8.decode(bytes);
                if (!configContent.contains('client') || 
                    !configContent.contains('remote ')) {
                  continue;
                }
              } catch (e) {
                continue;
              }

              servers.add(VpnServer(
                id: 'vpngate_${fields[0].replaceAll('.', '_')}',
                country: fields[5],
                city: fields[12].split('-').last.trim(),
                flag: 'assets/flags/${fields[6].toLowerCase()}.png',
                ovpnConfiguration: '',
                ping: int.tryParse(fields[3]) ?? 999,
                ip: fields[1],
                hostname: fields[0],
                port: 443,
                protocol: 'tcp',
                countryLong: fields[5],
                numVpnSessions: int.tryParse(fields[7]),
                uptime: double.tryParse(fields[8]),
                totalUsers: double.tryParse(fields[9]),
                speed: ((int.tryParse(fields[4]) ?? 0) / 1000000).toStringAsFixed(2),
                configData: openVPNConfigData,
                load: 0.0,
                bandwidth: 0.0,
                hasDoubleVPN: false,
                configPath: '',
              ));
            } catch (e) {
              debugPrint('Error parsing server: $e');
              continue;
            }
          }

          if (servers.isNotEmpty) {
            debugPrint('Successfully loaded ${servers.length} servers from $url');
            return servers;
          }
        }
      } catch (e) {
        debugPrint('Error fetching from $url: $e');
        continue;
      }
    }
    return [];
  }

  static List<VpnServer> getFreeServers() {
    return [
      VpnServer(
        id: 'vpngate-backup-1',
        country: 'Japan',
        city: 'Tokyo',
        flag: 'assets/flags/jp.png',
        ovpnConfiguration: 'assets/configs/vpngate_backup.ovpn',
        ping: 100,
        ip: 'vpn.vpngate.net',
        hostname: 'vpn.vpngate.net',
        port: 443,
        protocol: 'tcp',
        isPremium: false,
        speed: '10.0',
        countryLong: 'Japan',
        load: 0.0,
        bandwidth: 0.0,
        hasDoubleVPN: false,
        configPath: 'assets/configs/vpngate_backup.ovpn',
      ),
      VpnServer(
        id: 'vpngate-backup-2',
        country: 'United States',
        city: 'Los Angeles',
        flag: 'assets/flags/us.png',
        ovpnConfiguration: 'assets/configs/vpngate_backup_us.ovpn',
        ping: 150,
        ip: 'us.vpngate.net',
        hostname: 'us.vpngate.net',
        port: 443,
        protocol: 'tcp',
        isPremium: false,
        speed: '8.0',
        countryLong: 'United States',
        load: 0.0,
        bandwidth: 0.0,
        hasDoubleVPN: false,
        configPath: 'assets/configs/vpngate_backup_us.ovpn',
      ),
    ];
  }

  static Future<void> testVPNGateConnection() async {
    final urls = [
      'http://164.70.86.55:53336/api/iphone/',
      'http://222.255.11.117:54621/api/iphone/',
      'http://38.146.27.9:11602/api/iphone/',
      'http://58.70.80.237:60656/api/iphone/',
      'http://218.147.63.115:23602/api/iphone/',
      'http://221.253.212.68:32715/api/iphone/',
      // Keep a few backup URLs
      'http://vpn.vpngate.net/api/iphone/',
      'https://vpngate.cdngate.com/api/iphone/',
    ];

    debugPrint('Starting VPNGate mirror tests at ${DateTime.now()}');
    
    for (var url in urls) {
      try {
        debugPrint('Testing mirror: $url');
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15)); // Increased timeout
        
        if (response.statusCode == 200) {
          final lines = const LineSplitter()
              .convert(response.body)
              .where((line) => line.isNotEmpty && !line.startsWith('*'))
              .skip(1)
              .toList();

          if (lines.isEmpty) {
            debugPrint('No server data in response from $url');
            continue;
          }

          debugPrint('✅ Success! Found ${lines.length} servers from $url');
          
          // Print first server details
          if (lines.isNotEmpty) {
            final fields = lines[0].split(',');
            if (fields.length >= 15) {
              debugPrint('📡 Sample server details:');
              debugPrint('🔹 Hostname: ${fields[0]}');
              debugPrint('🔹 IP: ${fields[1]}');
              debugPrint('🔹 Country: ${fields[5]}');
              debugPrint('🔹 Speed: ${(int.parse(fields[4]) / 1000000).toStringAsFixed(2)} Mbps');
              
              // Validate OpenVPN config
              try {
                final configData = fields[14];
                final bytes = base64.decode(configData);
                final config = utf8.decode(bytes);
                if (config.contains('client') && config.contains('remote ')) {
                  debugPrint('✅ Valid OpenVPN configuration found');
                  debugPrint('🌟 Working mirror found: $url');
                  return; // Successfully found a working mirror
                }
              } catch (e) {
                debugPrint('❌ Config validation error: $e');
              }
            }
          }
        } else {
          debugPrint('❌ Failed to fetch from $url: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Error testing $url: $e');
      }
    }
    debugPrint('⚠️ All mirrors tested - completed at ${DateTime.now()}');
  }

  // Add a method to test direct server connection
  static Future<void> testDirectConnection() async {
    final testServers = [
      'vpn984097791.opengw.net:443',
      'vpn720337505.opengw.net:443',
      'public-vpn-172.opengw.net:443'
    ];
    
    for (var server in testServers) {
      try {
        debugPrint('Testing direct connection to: $server');
        final socket = await Socket.connect(
          server.split(':')[0],
          int.parse(server.split(':')[1]),
          timeout: const Duration(seconds: 5),
        );
        
        debugPrint('Successfully connected to $server');
        await socket.close();
        
        // If we can connect, try to get the config
        final url = 'http://103.253.72.103/api/iphone/';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
            
        if (response.statusCode == 200) {
          final lines = const LineSplitter()
              .convert(response.body)
              .where((line) => line.contains(server.split(':')[0]))
              .toList();
              
          if (lines.isNotEmpty) {
            debugPrint('Found server configuration');
            return;
          }
        }
      } catch (e) {
        debugPrint('Error connecting to $server: $e');
      }
    }
  }

  static Future<void> testSpecificServer() async {
    final testServer = 'public-vpn-225.opengw.net';
    final serverIP = '219.100.37.169';
    
    try {
      debugPrint('Testing connection to $testServer ($serverIP)');
      
      // Test ping
      final stopwatch = Stopwatch()..start();
      try {
        final socket = await Socket.connect(testServer, 443, 
            timeout: const Duration(seconds: 5));
        await socket.close();
        stopwatch.stop();
        debugPrint('Direct connection successful! Ping: ${stopwatch.elapsedMilliseconds}ms');
        
        // Get the application documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final configDir = Directory('${appDir.path}/configs');
        if (!await configDir.exists()) {
          await configDir.create(recursive: true);
        }

        // Save the config file
        final configFile = File('${configDir.path}/public-vpn-225.opengw.net_tcp443.ovpn');
        final config = '''client
dev tun
proto tcp
remote public-vpn-225.opengw.net 443
cipher AES-256-CBC
auth SHA256
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
auth-user-pass
comp-lzo
verb 3
<ca>
-----BEGIN CERTIFICATE-----
MIIDujCCAqKgAwIBAgIJALUF2M68U08LMA0GCSqGSIb3DQEBCwUAMHAxCzAJBgNV
BAYTAkpQMQ4wDAYDVQQIEwVPc2FrYTEOMAwGA1UEBxMFT3Nha2ExDjAMBgNVBAoT
BVNvZnRFMQwwCgYDVQQLEwNWUE4xDjAMBgNVBAMTBVZQTkNBMRMwEQYJKoZIhvcN
AQkBFgRub25lMB4XDTE0MTEyNjA5Mjc0OFoXDTI0MTEyMzA5Mjc0OFowcDELMAkG
A1UEBhMCSlAxDjAMBgNVBAgTBU9zYWthMQ4wDAYDVQQHEwVPc2FrYTEOMAwGA1UE
ChMFU29mdEUxDDAKBgNVBAsTA1ZQTjEOMAwGA1UEAxMFVlBOQ0ExEzARBgkqhkiG
9w0BCQEWBGub25lMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5H7D
GKwqZgn1qE0CjlOsZZ6Tl3Ge+AhwZyxQJ7hib7MqkX1wYQYSDxqE0HJJTUHyk9My
cQ4QjQ+lHF/o1G7E+49Oo4h/z+wEdHR1yR6ElKUHtQYlYNjcX+h4CARA6Qj3hxKx
k7D5r3J3c5slFX5J5PXa5qEqOtD+8E4EqdicG7pZHBsLh/Zo1UHcUPHgzA8qEqzc
vz9LHZj+/1cvhB3k4CFQeaF5vy9x3Z8MwFs/VhxPwcWSyJG5XnF/DM/oyH+LQcwm
dKlvpR0vz6yVDwWPo8/7ej+pJZxC4wH2GL0QamJ1F2zlocO4iPFHpjYz7DBYYWlu
h1MdnqLN5Z+U/4J00QIDAQABo1AwTjAdBgNVHQ4EFgQUNEG6jktd8dpJzYBGKkWX
hVhA9IgwHwYDVR0jBBgwFoAUNEG6jktd8dpJzYBGKkWXhVhA9IgwDAYDVR0TBAUw
AwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAQNqCvgdYktZIQ8YbLtXGVYnsX/UR1JFw
LXxhF6lxbDg6F8xUVEVj8KvlmA04WoZ02jHUYGxQxGHLHVznxaJV0U5M9CuOPCh0
Lg7njZX/88FFEzWG0zpe5BjJqKDZ5Uj9UJ8+KFBSBLwL+uZL9ZrF3oX11k3vVKOB
F6dBEXeRRec1wHGzL1kDhfXB6GWKYV3cSo8/6NGXyEwZxn9R1YHGJbx5stGMEMvJ
PmXJyJGpQryYGwO8USnK/ASF3WH5DBpNGXDEGVE8wqFk/TNlW44Q8Oz+HvJz4StH
JhAzwJHvOUP+oZcpHFSZF11RZ3+4xpbeEvLKXqOPzVK6S2kophHsUA==
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
MIID6TCCA1KgAwIBAgIBATANBgkqhkiG9w0BAQsFADBwMQswCQYDVQQGEwJKUDEO
MAwGA1UECBMFT3Nha2ExDjAMBgNVBAcTBU9zYWthMQ4wDAYDVQQKEwVTb2Z0RTEM
MAoGA1UECxMDVlBOMQ4wDAYDVQQDEwVWUE5DQTETMBEGCSqGSIb3DQEJARYEbm9u
ZTAeFw0xNDExMjYwOTI3NDhaFw0yNDExMjMwOTI3NDhaMHkxCzAJBgNVBAYTAkpQ
MQ4wDAYDVQQIEwVPc2FrYTEOMAwGA1UEBxMFT3Nha2ExDjAMBgNVBAoTBVNvZnRF
MQwwCgYDVQQLEwNWUE4xFzAVBgNVBAMTDnZwbi5zb2Z0ZXRoZXIxEzARBgkqhkiG
9w0BCQEWBGub25lMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5Kbk
sNGmKY/2zvxzy/Iq/C5v+BfGmwI4oqQXGQGbLxYYo4AVud8XwXxkbqG+11Z8i5eX
QeQDBIZvfm91kqAJAzGUX3LGoh4e8HJj3dqfGlqEqWICECMKZmRP+6f8RBQC6qpl
j4lQCHQY8GkCGp3C3tQHAkhC3pYkgXJzqYhQ7YGFmQf6VAZPxpzf9hxYvx/jm3qz
EP8+XqpF/RFfhzxcWmOZLNDUBqPALj5eCRIhbBgAKfF8ltrhZK7FVgWn78SkSKh7
wRwB+YxGDg0j+7hxkITEXXyGo7KTMi3EMsl2JnUZ0Xu1AYzxkKsA1KGxTRY8V2N4
+4+8QJ7RHqYiDQIDAQABo4IBQzCCAT8wCQYDVR0TBAIwADAtBglghkgBhvhCAQ0E
IBYeRWFzeS1SU0EgR2VuZXJhdGVkIENlcnRpZmljYXRlMB0GA1UdDgQWBBRTXX3g
Gy7yQpmTZRqGYS97f+YgwjCB3AYDVR0jBIHUMIHRgBQ0QbqOS13x2knNgEYqRZeF
WED0iKF0pHIwcDELMAkGA1UEBhMCSlAxDjAMBgNVBAgTBU9zYWthMQ4wDAYDVQQH
EwVPc2FrYTEOMAwGA1UEChMFU29mdEUxDDAKBgNVBAsTA1ZQTjEOMAwGA1UEAxMF
VlBOQ0ExEzARBgkqhkiG9w0BCQEWBGub25lgglkAMBMGA1UdJQQMMAoGCCsGAQUF
BwMCMAsGA1UdDwQEAwIHgDATBgNVHREEDDAKggh2cG4uY29tMBEGCWCGSAGG+EIB
AQQEAwIHgDANBgkqhkiG9w0BAQsFAAOCAQEAeZwK5+nNd1jH9mf2/cZ1g/kbRJB5
qR3XHVQvDHN+jzY6cO8+8oKGNOlwF8DhVlM08+6JQ6yTxW6O9Na5N6FfUBjHQZ6N
W37X8LYkY9Ow0Lec0WkAJY8Q8LXz1jZKF4TQ5jc1wY1JzQ0ohzn2GJ/oX/Qf6YCk
4RJFA2b8/ZQz8GE2lLk6XYVF2ZYhC5YHqHpKnt3/9sDNwrnOYkgGGUZgzqgbBYEW
yzY0QVxm7q8kJkzxJfJDs+SwJQXf84GcEZKYSj+bALWpTVwpb+XBCQww3KTHXPBy
Iq2sIZwwlRRbhUXkQEj+xtqKdm/Aw+WDjqoKkMzqHC/Fj9uDGg==
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDkpuSw0aYpj/bO
/HPL8ir8Lm/4F8abAjiipBcZAZsvFhijgBW53xfBfGRuob7XVnyLl5dB5AMEhm9+
b3WSoAkDMZRfcsaiHh7wcmPd2p8aWoSpYgIQIwpmZE/7p/xEFALqqmWPiVAIdBjw
aQIancLe1AcCSELeliSBcnOpiGDtgYWZB/pUBk/GnN/2HFi/H+OberMQ/z5eqkX9
EV+HPFxaY5ks0NQGo8AuPl4JEiFsGAAp8XyW2uFkrsVWBafvxKRIqHvBHAH5jEYO
DSP7uHGQhMRdfIajspMyLcQyyXYmdRnRe7UBjPGQqwDUobFNFjxXY3j7j7xAntEe
piINAgMBAAECggEABt2TZ7WqQdoFV07GBmLYEWQZhm1+S8F6YX0/XuBa/eH3KTr8
1S4KgPpw3UKDF6ZhAKEXipEYkJJhGxlHj/MweWBHk8EBHF/Qwk06j5x+LXxVVhBH
Zw6UE4TQ5EDGGwE+MYMTvAEXvJDJpwVwKUIqZIVQXYVDGNJwjXDyOqgBTIq+5Zcj
oJJnr5BwVY0Qx3HgBcBwF1IWsYEOHN2hGKEQE/qD8rp3jIlHESWRHYlYyYD0pCGS
QnE6VZYdDhYDLJGRk51RGSFLGMxBZX1M5HHlqHFi6oG/Qq8IA/11vZ6CWY1YVS4U
KrWWuNgZuHcgQMkF3qpVT9AoQyOHBHEFgXMK4QKBgQD7IhKrLFwqCFRyK4QxPFXW
o2qwKA2+JKq5fJ0Oe+zDqhvYDGHKjIYBfYYcqRzwWUhj5PTSxuVl0/2pxqKLU2KF
YQtpCzVHhwW3uQYOEHGBBpVGOBPVXFI+tKd4s/Ln2Wz4AQNY7rlgYvOHXswWp3Zw
Tz4+XP5s5UZDKFgEVl0KqQKBgQDo8E36VQw3X4XxUVGGRYnhEEwTJAYBK7h2JjWD
+nEhxjPQk/7F09qifFJrv6g4FRxI0vRrALf/0/Jw01uODhxGXgwlxqfKqQlgVlsX
EZXJPJEzB0UwGFgqezE3w9o0iYXt0c8+Qk7KvG0oETGj5/k8MvAGC/3+sWxWz/Ey
9KQNVQKBgQCpFMxqZxzJ6YH4v0JVRkNzJNFRyyMMgzVe8Zs+HhPtdkKBUuB4zOXl
N/jvYLUXFJ3hP7Qb9BSZrP5StgF3YAqEHXX4FsY+yBxW2b6wlzKZfVGMPjfIjK7c
YZrLkEpUVXEZzVVOXr7q+oGBZHHHMHYzGrwO4f5qyfzRvKEPUFYPkQKBgQCBxJWh
+xtpvcEm4z6E7/0K9XBX7JRdxPQnq/Ysj+7aCxAEZZ9mA+oXqYBVmDvhXxKCzuQx
BL0Gs2+ZEwjXSSfI/QkzZEHq/QYEMa+yqKv+wtqC8f6dsHsFHiGB+EPWH+K9qWww
Yd8rmWoKUxsZUvFGqDvOIB/TQzHgQFxXBQKBgQDXVxDq9axGBJtlHs/6CBF8nYPg
Q1Ar3UHltEYRSZ5Fs2ZRYupy6S5Qk3vGZZGvWPaZj4QZo0XD3c1YLuZBbWuNsXJx
kc6hkmV4C5+kHraw/0y8oKWC5H0q8JxUHxsHYw5/LVedX4Uw+BBCVoIVUGzVYuHw
QhO3LP7Ql4J+Q==
-----END PRIVATE KEY-----
</key>
<tls-auth>
-----BEGIN OpenVPN Static key V1-----
939fe6669b91b8850d1872b82281c75b
8b5e66a85b9908b67e4859e66d1e850c
cf5e4e16bba4313938e0d4c09e9dc224
c10e4bf2a8f4ce5b5f2e7ef1d936f24b
939fe6669b91b8850d1872b82281c75b
8b5e66a85b9908b67e4859e66d1e850c
cf5e4e16bba4313938e0d4c09e9dc224
c10e4bf2a8f4ce5b5f2e7ef1d936f24b
-----END OpenVPN Static key V1-----
</tls-auth>''';

        await configFile.writeAsString(config);
        debugPrint('Config saved to: ${configFile.path}');
      } catch (e) {
        debugPrint('Error during test: $e');
      }
    } catch (e) {
      debugPrint('Error testing server: $e');
    }
  }

  // Make this a static method that returns a regular VpnServer
  static VpnServer getSpecificServer(String configPath) {
    return VpnServer(
      id: 'vpngate_public_vpn_225',
      country: 'Japan',
      city: 'Tokyo',
      flag: 'assets/flags/jp.png',
      ovpnConfiguration: configPath,
      ping: 10,
      ip: '219.100.37.169',
      hostname: 'public-vpn-225.opengw.net',
      port: 443,
      protocol: 'tcp',
      countryLong: 'Japan',
      numVpnSessions: 280,
      uptime: 117.0,
      totalUsers: 14337740,
      speed: '630.38',
      load: 0.5,
      bandwidth: 100.0,
      hasDoubleVPN: false,
      configPath: configPath,
    );
  }

  VpnServer copyWith({
    String? serverName,
    String? hostname,
    int? port,
    int? ping,
    double? load,
    double? bandwidth,
    bool? hasDoubleVPN,
    String? configPath,
  }) {
    return VpnServer(
      id: id,
      country: country,
      city: city,
      flag: flag,
      ovpnConfiguration: ovpnConfiguration,
      ping: ping ?? this.ping,
      ip: ip,
      isPremium: isPremium,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      protocol: protocol,
      countryLong: countryLong,
      numVpnSessions: numVpnSessions,
      uptime: uptime,
      totalUsers: totalUsers,
      speed: speed,
      configData: configData,
      load: load ?? this.load,
      bandwidth: bandwidth ?? this.bandwidth,
      hasDoubleVPN: hasDoubleVPN ?? this.hasDoubleVPN,
      configPath: configPath ?? this.configPath,
    );
  }

  // Add method to toggle favorite status
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}