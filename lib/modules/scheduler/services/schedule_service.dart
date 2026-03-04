
import 'dart:async';
import 'package:business_analytics_chat/modules/scheduler/models/schedule_model.dart';

class ScheduleService {
  // --- MOCK STORAGE ---
  final _schedules = <ScheduleModel>[
    ScheduleModel(
      id: '1',
      title: 'Weekly Sales Summary',
      reportType: 'Sales Report',
      frequency: ScheduleFrequency.weekly,
      scheduledTime: 'Every Monday - 8:00 AM',
      status: ScheduleStatus.active,
      description: 'Review of the previous week\'s sales performance.',
      destinations: [Destination.email],
    ),
    ScheduleModel(
      id: '2',
      title: 'Monthly Visit Plan Status',
      reportType: 'Visit Plan',
      frequency: ScheduleFrequency.monthly,
      scheduledTime: '1st of every Month - 9:00 AM',
      status: ScheduleStatus.paused,
      description: 'Monthly status check of the visit plan.',
      destinations: [Destination.widget, Destination.notification],
    ),
  ];

  Future<List<ScheduleModel>> getSchedules() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List<ScheduleModel>.from(_schedules);
  }

  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newSchedule = schedule.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    _schedules.add(newSchedule);
    return newSchedule;
  }

  Future<ScheduleModel> updateSchedule(ScheduleModel schedule) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
      return schedule;
    }
    throw Exception('Schedule not found');
  }

  Future<void> deleteSchedule(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _schedules.removeWhere((s) => s.id == id);
  }

  Future<ScheduleModel> pauseSchedule(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      final current = _schedules[index];
      final updated = current.copyWith(
        status: current.status == ScheduleStatus.active 
            ? ScheduleStatus.paused 
            : ScheduleStatus.active
      );
      _schedules[index] = updated;
      return updated;
    }
    throw Exception('Schedule not found');
  }
}
