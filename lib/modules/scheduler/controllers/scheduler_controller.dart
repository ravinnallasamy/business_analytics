
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/modules/scheduler/models/schedule_model.dart';
import 'package:business_analytics_chat/modules/scheduler/services/schedule_service.dart';

class SchedulerState {
  final List<ScheduleModel> schedules;
  final bool isLoading;
  final String? error;

  SchedulerState({
    required this.schedules,
    required this.isLoading,
    this.error,
  });

  SchedulerState copyWith({
    List<ScheduleModel>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return SchedulerState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SchedulerNotifier extends Notifier<SchedulerState> {
  final _service = ScheduleService();

  @override
  SchedulerState build() {
    // We can't call async in build, so we'll do it via future
    Future.microtask(() => loadSchedules());
    return SchedulerState(schedules: [], isLoading: true);
  }

  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedules = await _service.getSchedules();
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    try {
      final newSchedule = await _service.createSchedule(schedule);
      state = state.copyWith(schedules: [...state.schedules, newSchedule]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    try {
      final updated = await _service.updateSchedule(schedule);
      state = state.copyWith(
        schedules: state.schedules.map((s) => s.id == updated.id ? updated : s).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _service.deleteSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.where((s) => s.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleScheduleStatus(String id) async {
    try {
      final updated = await _service.pauseSchedule(id);
      state = state.copyWith(
        schedules: state.schedules.map((s) => s.id == id ? updated : s).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final schedulerProvider = NotifierProvider<SchedulerNotifier, SchedulerState>(() {
  return SchedulerNotifier();
});
