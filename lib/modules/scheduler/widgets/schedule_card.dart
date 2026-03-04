
import 'package:flutter/material.dart';
import 'package:business_analytics_chat/core/theme/app_colors.dart';
import 'package:business_analytics_chat/modules/scheduler/models/schedule_model.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive = schedule.status == ScheduleStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? AppColors.accentGreen.withOpacity(0.2) : AppColors.borderGray, 
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(
                width: 6,
                color: isActive ? AppColors.accentGreen : AppColors.inactive,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    schedule.reportType,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFFB8860B), // Darker gold for contrast
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(isActive),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildInfoItem(context, Icons.calendar_month_outlined, frequencyToString(schedule.frequency)),
                          const SizedBox(width: 32),
                          _buildInfoItem(context, Icons.access_time_rounded, schedule.scheduledTime),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            context, 
                            onEdit, 
                            Icons.edit_outlined, 
                            'Edit', 
                            AppColors.textSecondary
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            context, 
                            onToggleStatus, 
                            isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, 
                            isActive ? 'Pause' : 'Resume', 
                            isActive ? const Color(0xFFE67E22) : AppColors.accentGreen
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            context, 
                            onDelete, 
                            Icons.delete_outline_rounded, 
                            'Delete', 
                            Colors.redAccent
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentGreen.withOpacity(0.12) : AppColors.inactive.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.accentGreen.withOpacity(0.3) : AppColors.inactive.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.accentGreen : AppColors.inactive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'Active' : 'Paused',
            style: TextStyle(
              color: isActive ? AppColors.accentGreen : AppColors.inactive,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, VoidCallback onPressed, IconData icon, String tooltip, Color color) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.2), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
