import 'dart:ui';

import 'package:clockify/data/models/hourly_rate.dart';
import 'package:vit_dart_extensions/vit_dart_extensions.dart';

class Project {
  final String id;
  final String name;
  final Color color;
  final bool archived;
  final List<Membership> memberships;

  Project({
    required this.id,
    required this.name,
    required this.color,
    required this.memberships,
    required this.archived,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    String colorStr = map['color'].startsWith('#')
        ? map['color'].substring(1)
        : map['color'];

    // Ensure the color has an alpha channel (FF for fully opaque)
    if (colorStr.length == 6) {
      colorStr = 'FF$colorStr';
    }

    return Project(
      id: map['id'],
      name: map['name'],
      color: Color(int.parse(colorStr, radix: 16)),
      archived: map['archived'] ?? false,
      memberships: map.getList('memberships', (x) => Membership.fromMap(x)),
    );
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Project && other.id == id;
  }
}

class Membership {
  final String userId;
  HourlyRate hourlyRate;

  Membership({required this.userId, required this.hourlyRate});

  factory Membership.fromMap(Map<String, dynamic> map) {
    return Membership(
      userId: map['userId'],
      hourlyRate: HourlyRate.fromMap(map['hourlyRate'] ?? {'amount': 0}),
    );
  }
}
