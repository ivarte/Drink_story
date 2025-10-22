class License {
  final String licenseId, routeId, signature;
  final DateTime activatedAt;
  License({
    required this.licenseId,
    required this.routeId,
    required this.signature,
    required this.activatedAt,
  });

  factory License.fromJson(Map<String, dynamic> j) => License(
        licenseId: j['license_id'],
        routeId: j['route_id'],
        signature: j['signature'],
        activatedAt: DateTime.parse(j['activated_at'] ?? DateTime.now().toIso8601String()),
      );

  Map<String, dynamic> toJson() => {
        'license_id': licenseId,
        'route_id': routeId,
        'signature': signature,
        'activated_at': activatedAt.toIso8601String(),
      };
}

class Scene {
  final String id, file, type;
  final String? unlock, nextId;
  Scene({required this.id, required this.file, required this.type, this.unlock, this.nextId});

  factory Scene.fromJson(Map<String, dynamic> j) => Scene(
        id: j['id'],
        file: j['file'],
        type: j['type'],
        unlock: j['unlock'],
        nextId: j['next'],
      );
}

class RouteManifest {
  final String routeId, version, checksumSha256, title;
  final int durationMin;
  final List<Scene> scenes;

  RouteManifest({
    required this.routeId,
    required this.version,
    required this.title,
    required this.durationMin,
    required this.scenes,
    required this.checksumSha256,
  });

  factory RouteManifest.fromJson(Map<String, dynamic> j) => RouteManifest(
        routeId: j['route_id'],
        version: j['version'] ?? '1.0.0',
        title: j['title'] ?? '',
        durationMin: j['duration_min'] ?? 0,
        scenes: (j['scenes'] as List? ?? [])
            .map((e) => Scene.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        checksumSha256: j['checksum_sha256'] ?? '',
      );

  Scene? byId(String id) {
    for (final s in scenes) {
      if (s.id == id) return s;
    }
    return null;
  }
}
