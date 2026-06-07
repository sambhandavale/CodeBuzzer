class Contest {
  final String id;
  final int alarmId;
  final String name;
  final String description;
  final String url;
  final DateTime startTime;
  final DateTime endTime;
  final String duration;
  final String site;
  final String status;
  final bool isAlarmActive; // Track if dismissed
  final int snoozeCount;    // Track snoozes

  Contest({
    required this.id,
    int? alarmId,
    required this.name,
    this.description = '',
    required this.url,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.site,
    required this.status,
    this.isAlarmActive = true,
    this.snoozeCount = 0,
  }) : alarmId = alarmId ?? id.hashCode.abs() % 100000;

  Contest copyWith({
    String? id,
    int? alarmId,
    String? name,
    String? description,
    String? url,
    DateTime? startTime,
    DateTime? endTime,
    String? duration,
    String? site,
    String? status,
    bool? isAlarmActive,
    int? snoozeCount,
  }) {
    return Contest(
      id: id ?? this.id,
      alarmId: alarmId ?? this.alarmId,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      site: site ?? this.site,
      status: status ?? this.status,
      isAlarmActive: isAlarmActive ?? this.isAlarmActive,
      snoozeCount: snoozeCount ?? this.snoozeCount,
    );
  }

  factory Contest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    final generatedAlarmId = id.hashCode.abs() % 100000;

    final startTimeDate = json['start_time'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['start_time']).toLocal()
        : DateTime.tryParse(json['start_time'] ?? '')?.toLocal() ??
            DateTime.now();

    return Contest(
      id: id.isEmpty ? 'id_${startTimeDate.millisecondsSinceEpoch}' : id,
      alarmId: json['alarm_id'] ?? generatedAlarmId,
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      startTime: startTimeDate,
      endTime: json['end_time'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time']).toLocal()
          : DateTime.tryParse(json['end_time'] ?? '')?.toLocal() ??
              DateTime.now(),
      duration: json['duration'] ?? '',
      site: json['site'] ?? '',
      status: json['status'] ?? '',
      isAlarmActive: json['is_alarm_active'] ?? true,
      snoozeCount: json['snooze_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarm_id': alarmId,
      'name': name,
      'description': description,
      'url': url,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration': duration,
      'site': site,
      'status': status,
      'is_alarm_active': isAlarmActive,
      'snooze_count': snoozeCount,
    };
  }
}
