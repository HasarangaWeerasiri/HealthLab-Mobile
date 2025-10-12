import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ReminderPopup extends StatefulWidget {
  final String experimentId;
  final String experimentTitle;
  final bool isReminderActive;
  final TimeOfDay? currentReminderTime;

  const ReminderPopup({
    super.key,
    required this.experimentId,
    required this.experimentTitle,
    required this.isReminderActive,
    this.currentReminderTime,
  });

  @override
  State<ReminderPopup> createState() => _ReminderPopupState();
}

class _ReminderPopupState extends State<ReminderPopup> {
  late TimeOfDay _selectedTime;
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _isReminderActive = false;

  @override
  void initState() {
    super.initState();
    _isReminderActive = widget.isReminderActive;
    _selectedTime = widget.currentReminderTime ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFFCDEDC6), // Light green background
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and bell icon
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    _isReminderActive ? 'Daily Reminder Settings' : 'Toggle on Reminder',
                    style: const TextStyle(
                      color: Color(0xFF00432D),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/icons/bell.png',
                    width: 24,
                    height: 24,
                    color: const Color(0xFF00432D),
                  ),
                ],
              ),
            ),

            // Show current reminder status if active
            if (_isReminderActive) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00432D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: const Color(0xFF00432D),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder is active',
                              style: TextStyle(
                                color: const Color(0xFF00432D),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Daily at ${_selectedTime.format(context)}',
                              style: TextStyle(
                                color: const Color(0xFF00432D).withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Choose a time text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isReminderActive ? 'Change reminder time' : 'Choose a time',
                  style: TextStyle(
                    color: const Color(0xFF00432D).withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Time picker
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours column
                  Expanded(
                    child: _TimePickerColumn(
                      values: List.generate(12, (i) => i + 1),
                      selectedValue: _selectedTime.hourOfPeriod,
                      onChanged: (value) {
                        setState(() {
                          _selectedTime = TimeOfDay(
                            hour: _selectedTime.period == DayPeriod.am 
                                ? (value == 12 ? 0 : value)
                                : (value == 12 ? 12 : value + 12),
                            minute: _selectedTime.minute,
                          );
                        });
                      },
                    ),
                  ),

                  // Separator
                  const Text(
                    ' : ',
                    style: TextStyle(
                      color: Color(0xFF00432D),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Minutes column
                  Expanded(
                    child: _TimePickerColumn(
                      values: List.generate(60, (i) => i),
                      selectedValue: _selectedTime.minute,
                      onChanged: (value) {
                        setState(() {
                          _selectedTime = TimeOfDay(
                            hour: _selectedTime.hour,
                            minute: value,
                          );
                        });
                      },
                    ),
                  ),

                  // AM/PM column
                  Expanded(
                    child: _TimePickerColumn(
                      values: const [0, 1], // 0 = AM, 1 = PM
                      selectedValue: _selectedTime.period == DayPeriod.am ? 0 : 1,
                      onChanged: (value) {
                        setState(() {
                          final isAm = value == 0;
                          _selectedTime = TimeOfDay(
                            hour: isAm 
                                ? (_selectedTime.hourOfPeriod == 12 ? 0 : _selectedTime.hourOfPeriod)
                                : (_selectedTime.hourOfPeriod == 12 ? 12 : _selectedTime.hourOfPeriod + 12),
                            minute: _selectedTime.minute,
                          );
                        });
                      },
                      displayValue: (value) => value == 0 ? 'AM' : 'PM',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Description text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _isReminderActive 
                    ? 'You can change the reminder time or turn it off completely'
                    : 'Enabling this will remind you to log your daily data at a preferred time',
                style: TextStyle(
                  color: const Color(0xFF00432D).withOpacity(0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // Cancel/Turn Off button (only show if reminder is active)
                  if (_isReminderActive) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _cancelReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Turn Off',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Apply/Update button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _applyReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00432D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isReminderActive ? 'Update' : 'Apply',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Future<void> _applyReminder() async {
    setState(() => _isLoading = true);

    try {
      // Request notification permissions
      final hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required for reminders'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Schedule the reminder
      await _notificationService.scheduleDailyReminder(
        experimentId: widget.experimentId,
        experimentTitle: widget.experimentTitle,
        time: _selectedTime,
      );

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isReminderActive 
              ? 'Reminder updated for ${_selectedTime.format(context)}'
              : 'Daily reminder set for ${_selectedTime.format(context)}'),
          backgroundColor: const Color(0xFF00432D),
        ),
      );

      // Close the dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelReminder() async {
    setState(() => _isLoading = true);

    try {
      // Cancel the reminder
      await _notificationService.cancelReminder(widget.experimentId);

      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily reminder turned off'),
          backgroundColor: Color(0xFF00432D),
        ),
      );

      // Close the dialog
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _TimePickerColumn extends StatelessWidget {
  final List<int> values;
  final int selectedValue;
  final Function(int) onChanged;
  final String Function(int)? displayValue;

  const _TimePickerColumn({
    required this.values,
    required this.selectedValue,
    required this.onChanged,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: values.length,
      itemBuilder: (context, index) {
        final value = values[index];
        final isSelected = value == selectedValue;
        final displayText = displayValue?.call(value) ?? value.toString().padLeft(2, '0');

        return GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              displayText,
              style: TextStyle(
                color: isSelected 
                    ? const Color(0xFF00432D)
                    : const Color(0xFF00432D).withOpacity(0.4),
                fontSize: isSelected ? 20 : 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }
}
