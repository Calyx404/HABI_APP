import 'package:flutter/material.dart';

class InterviewScheduleInput {
  const InterviewScheduleInput({
    required this.startsAt,
    required this.endsAt,
    required this.format,
    required this.locationOrLink,
    required this.instructions,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final String format;
  final String locationOrLink;
  final String instructions;
}

class InterviewScheduleDialog extends StatefulWidget {
  const InterviewScheduleDialog({super.key});

  static Future<InterviewScheduleInput?> show(BuildContext context) =>
      showDialog<InterviewScheduleInput>(
        context: context,
        builder: (_) => const InterviewScheduleDialog(),
      );

  @override
  State<InterviewScheduleDialog> createState() =>
      _InterviewScheduleDialogState();
}

class _InterviewScheduleDialogState extends State<InterviewScheduleDialog> {
  final _location = TextEditingController();
  final _instructions = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  String _format = 'Online';
  String? _error;

  @override
  void dispose() {
    _location.dispose();
    _instructions.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay time) =>
      DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _pickTime({required bool start}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (time == null || !mounted) return;
    setState(() {
      if (start) {
        _start = time;
      } else {
        _end = time;
      }
    });
  }

  void _submit() {
    final startsAt = _combine(_start);
    final endsAt = _combine(_end);
    if (!endsAt.isAfter(startsAt)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    if (_format != 'Phone' && _location.text.trim().isEmpty) {
      setState(
        () => _error = _format == 'Online'
            ? 'Enter the meeting link.'
            : 'Enter the interview location.',
      );
      return;
    }
    Navigator.of(context).pop(
      InterviewScheduleInput(
        startsAt: startsAt,
        endsAt: endsAt,
        format: _format,
        locationOrLink: _location.text.trim(),
        instructions: _instructions.text.trim(),
      ),
    );
  }

  String _timeText(TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Schedule interview'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(
              MaterialLocalizations.of(context).formatMediumDate(_date),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(start: true),
                  child: Text('Start ${_timeText(_start)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(start: false),
                  child: Text('End ${_timeText(_end)}'),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _format,
            decoration: const InputDecoration(labelText: 'Interview format'),
            items: const [
              DropdownMenuItem(value: 'In-person', child: Text('In-person')),
              DropdownMenuItem(value: 'Online', child: Text('Online')),
              DropdownMenuItem(value: 'Phone', child: Text('Phone')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _format = value);
            },
          ),
          if (_format != 'Phone')
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: _format == 'Online' ? 'Meeting link' : 'Location',
              ),
            ),
          TextField(
            controller: _instructions,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Instructions (optional)',
            ),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Schedule')),
    ],
  );
}
