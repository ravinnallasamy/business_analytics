
enum ScheduleStatus { active, paused }

enum ScheduleFrequency { daily, weekly, monthly, custom }

enum Destination { email, widget, notification }

class ScheduleModel {
  final String id;
  final String title;
  final String reportType;
  final ScheduleFrequency frequency;
  final String scheduledTime; 
  final ScheduleStatus status;
  final String? description;
  final List<Destination> destinations;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.reportType,
    required this.frequency,
    required this.scheduledTime,
    required this.status,
    this.description,
    this.destinations = const [],
  });

  ScheduleModel copyWith({
    String? id,
    String? title,
    String? reportType,
    ScheduleFrequency? frequency,
    String? scheduledTime,
    ScheduleStatus? status,
    String? description,
    List<Destination>? destinations,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      reportType: reportType ?? this.reportType,
      frequency: frequency ?? this.frequency,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      description: description ?? this.description,
      destinations: destinations ?? this.destinations,
    );
  }

  factory ScheduleModel.mock(String id, String title, String type, ScheduleFrequency freq, String time, ScheduleStatus status) {
    return ScheduleModel(
      id: id,
      title: title,
      reportType: type,
      frequency: freq,
      scheduledTime: time,
      status: status,
      description: 'Mock description for $title',
      destinations: [Destination.email],
    );
  }
}

String frequencyToString(ScheduleFrequency freq) {
  switch (freq) {
    case ScheduleFrequency.daily: return 'Daily';
    case ScheduleFrequency.weekly: return 'Weekly';
    case ScheduleFrequency.monthly: return 'Monthly';
    case ScheduleFrequency.custom: return 'Custom';
  }
}

String destinationToString(Destination dest) {
  switch (dest) {
    case Destination.email: return 'Email';
    case Destination.widget: return 'Widget';
    case Destination.notification: return 'Notification';
  }
}
