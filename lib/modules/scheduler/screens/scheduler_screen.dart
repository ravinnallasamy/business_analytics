
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
import 'package:business_analytics_chat/modules/scheduler/controllers/scheduler_controller.dart';
import 'package:business_analytics_chat/modules/scheduler/widgets/schedule_card.dart';
import 'package:business_analytics_chat/modules/scheduler/widgets/schedule_empty.dart';
import 'package:business_analytics_chat/modules/scheduler/models/schedule_model.dart';
import 'package:go_router/go_router.dart';
import 'package:business_analytics_chat/modules/chat/state/chat_state.dart';

class SchedulerScreen extends ConsumerWidget {
  const SchedulerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schedulerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final hPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(hPadding, 40, hPadding, 32),
              child: Builder(
                builder: (context) {
                  final headerContent = Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled Tasks',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your automated reports and reminders',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );

                  final actions = Row(
                    mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      if (!isMobile) ...[
                        _buildHeaderButton(
                          context,
                          'Refresh',
                          Icons.refresh_rounded,
                          false,
                          () => ref.read(schedulerProvider.notifier).loadSchedules(),
                          isMobile,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        flex: isMobile ? 1 : 0,
                        child: _buildHeaderButton(
                          context,
                          isMobile ? 'New' : 'Create Schedule',
                          Icons.add_rounded,
                          true,
                          () => _showCreateScheduleModal(context),
                          isMobile,
                        ),
                      ),
                      if (isMobile) ...[
                         const SizedBox(width: 12),
                         IconButton(
                           onPressed: () => ref.read(schedulerProvider.notifier).loadSchedules(),
                           icon: const Icon(Icons.refresh_rounded, color: AppColors.accentGreen),
                           style: IconButton.styleFrom(
                             backgroundColor: Colors.white,
                             padding: const EdgeInsets.all(12),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                               side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                             ),
                           ),
                         ),
                      ],
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                ref.read(chatProvider.notifier).clearActiveConversation();
                                GoRouter.of(context).go('/chat');
                              },
                              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.borderGray),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            headerContent,
                          ],
                        ),
                        const SizedBox(height: 24),
                        actions,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).clearActiveConversation();
                          GoRouter.of(context).go('/chat');
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderGray),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      headerContent,
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
            ),
          ),
          
          // List Section
          if (state.isLoading)
             const SliverFillRemaining(
               child: Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
             )
          else if (state.schedules.isEmpty)
             SliverPadding(
               padding: EdgeInsets.symmetric(horizontal: hPadding),
               sliver: const SliverToBoxAdapter(child: ScheduleEmpty()),
             )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final schedule = state.schedules[index];
                    return ScheduleCard(
                      schedule: schedule,
                      onEdit: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit feature placeholder')));
                      },
                      onDelete: () => ref.read(schedulerProvider.notifier).deleteSchedule(schedule.id),
                      onToggleStatus: () => ref.read(schedulerProvider.notifier).toggleScheduleStatus(schedule.id),
                    );
                  },
                  childCount: state.schedules.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(BuildContext context, String label, IconData icon, bool primary, VoidCallback onPressed, bool isMobile) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isMobile ? 18 : 20, color: primary ? Colors.white : AppColors.accentGreen),
        label: Text(
          label, 
          style: TextStyle(
            color: primary ? Colors.white : AppColors.accentGreen,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).textTheme.labelLarge?.fontSize,
          )
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppColors.accentGreen : Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: primary ? BorderSide.none : const BorderSide(color: AppColors.accentGreen, width: 1.5),
          ),
          foregroundColor: primary ? Colors.white : AppColors.accentGreen,
        ),
      ),
    );
  }

  void _showCreateScheduleModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateScheduleDialog(),
    );
  }
}

class CreateScheduleDialog extends ConsumerStatefulWidget {
  const CreateScheduleDialog({super.key});

  @override
  ConsumerState<CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends ConsumerState<CreateScheduleDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _reportType = 'Sales Report';
  ScheduleFrequency _frequency = ScheduleFrequency.daily;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final List<Destination> _destinations = [Destination.email];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Dialog(
       backgroundColor: Colors.transparent,
       insetPadding: EdgeInsets.all(isMobile ? 12 : 48),
       child: Container(
         width: isMobile ? screenWidth - 24 : 600,
         constraints: const BoxConstraints(maxHeight: 800),
         decoration: BoxDecoration(
           color: Colors.white,
           borderRadius: BorderRadius.circular(28),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.12),
               blurRadius: 40,
               offset: const Offset(0, 12),
             ),
           ],
         ),
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // Header
             Padding(
               padding: const EdgeInsets.all(32),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Create Schedule',
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                       color: AppColors.textPrimary,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   IconButton(
                     onPressed: () => Navigator.pop(context),
                     icon: const Icon(Icons.close_rounded, color: AppColors.inactive),
                   ),
                 ],
               ),
             ),
             const Divider(height: 1),
             
             // Scrollable Content
             Flexible(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(32),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildLabel('Schedule Name'),
                     TextField(
                       controller: _nameController,
                       decoration: _inputDecoration('Enter schedule name'),
                     ),
                     const SizedBox(height: 24),
                     
                     _buildLabel('Report Type'),
                     DropdownButtonFormField<String>(
                       value: _reportType,
                       decoration: _inputDecoration('Select report type'),
                       items: ['Sales Report', 'Visit Plan', 'Dealer Outstanding', 'Inventory Summary']
                           .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                           .toList(),
                       onChanged: (val) => setState(() => _reportType = val!),
                     ),
                     const SizedBox(height: 24),
                     
                     if (isMobile) ...[
                       _buildLabel('Frequency'),
                       DropdownButtonFormField<ScheduleFrequency>(
                         value: _frequency,
                         decoration: _inputDecoration('Select frequency'),
                         items: ScheduleFrequency.values
                             .map((f) => DropdownMenuItem(value: f, child: Text(frequencyToString(f))))
                             .toList(),
                         onChanged: (val) => setState(() => _frequency = val!),
                       ),
                       const SizedBox(height: 24),
                       _buildLabel('Time'),
                       InkWell(
                         onTap: () async {
                           final picked = await showTimePicker(context: context, initialTime: _time);
                           if (picked != null) setState(() => _time = picked);
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                           decoration: BoxDecoration(
                             border: Border.all(color: AppColors.borderGray, width: 1.5),
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text(_time.format(context)),
                               const Icon(Icons.access_time_rounded, size: 20, color: AppColors.accentGreen),
                             ],
                           ),
                         ),
                       ),
                     ] else
                       Row(
                         children: [
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildLabel('Frequency'),
                                 DropdownButtonFormField<ScheduleFrequency>(
                                   value: _frequency,
                                   decoration: _inputDecoration('Select frequency'),
                                   items: ScheduleFrequency.values
                                       .map((f) => DropdownMenuItem(value: f, child: Text(frequencyToString(f))))
                                       .toList(),
                                   onChanged: (val) => setState(() => _frequency = val!),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(width: 24),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 _buildLabel('Time'),
                                 InkWell(
                                   onTap: () async {
                                     final picked = await showTimePicker(context: context, initialTime: _time);
                                     if (picked != null) setState(() => _time = picked);
                                   },
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                     decoration: BoxDecoration(
                                       border: Border.all(color: AppColors.borderGray, width: 1.5),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(_time.format(context)),
                                         const Icon(Icons.access_time_rounded, size: 20, color: AppColors.accentGreen),
                                       ],
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),
                     const SizedBox(height: 24),
                     
                     _buildLabel('Optional Description'),
                     TextField(
                       controller: _descriptionController,
                       maxLines: 2,
                       decoration: _inputDecoration('Enter description'),
                     ),
                     const SizedBox(height: 24),
                     
                     _buildLabel('Destination'),
                     Wrap(
                       spacing: 12,
                       children: Destination.values.map((d) {
                         final selected = _destinations.contains(d);
                         return FilterChip(
                           label: Text(destinationToString(d)),
                           selected: selected,
                           onSelected: (val) {
                             setState(() {
                               if (val) _destinations.add(d);
                               else _destinations.remove(d);
                             });
                           },
                           selectedColor: AppColors.accentGreen.withOpacity(0.12),
                           checkmarkColor: AppColors.accentGreen,
                           labelStyle: TextStyle(
                             color: selected ? AppColors.accentGreen : AppColors.textSecondary,
                             fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                           ),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                             side: BorderSide(
                               color: selected ? AppColors.accentGreen : AppColors.borderGray,
                               width: 1,
                             ),
                           ),
                         );
                       }).toList(),
                     ),
                   ],
                 ),
               ),
             ),
             
             // Footer Actions
             const Divider(height: 1),
             Padding(
               padding: const EdgeInsets.all(32),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   TextButton(
                     onPressed: () => Navigator.pop(context),
                     child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                     style: TextButton.styleFrom(
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                     ),
                   ),
                   const SizedBox(width: 16),
                   ElevatedButton(
                     onPressed: () {
                        if (_nameController.text.isEmpty) return;
                        final newSchedule = ScheduleModel(
                          id: '', // Service will assign
                          title: _nameController.text,
                          reportType: _reportType,
                          frequency: _frequency,
                          scheduledTime: 'At ${_time.format(context)} ${frequencyToString(_frequency)}',
                          status: ScheduleStatus.active,
                          description: _descriptionController.text,
                          destinations: _destinations,
                        );
                        ref.read(schedulerProvider.notifier).addSchedule(newSchedule);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule created (Mock)')));
                     },
                     child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.accentGreen,
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                       elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inactive),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderGray, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accentGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
