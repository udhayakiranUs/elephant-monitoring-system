import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../models/elephant_model.dart';
import '../../models/report_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/camera_service.dart';
import '../../services/gps_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/elephant_counter.dart';

/// Full incident report (date, location, officer, counts, damage, chase-back).
class NewReportScreen extends StatefulWidget {
  const NewReportScreen({super.key});

  @override
  State<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends State<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  TimeOfDay? _chaseTime;

  String? _range;
  String? _rangeHint;
  String _designation = AppText.designations.first;
  String _damageType = '';
  String _chaseResult = AppText.chaseResults.first;

  bool _damage = false;
  bool _submitting = false;
  bool _gpsFilled = false;

  ElephantCounts _counts = ElephantCounts();

  /// Photos picked with the Camera / Gallery buttons.
  final List<XFile> _photos = [];

  final _beat = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _locDesc = TextEditingController();
  final _officer = TextEditingController();
  final _team = TextEditingController();
  final _dmgDesc = TextEditingController();
  final _remarks = TextEditingController();

  late final GpsService _gps;

  @override
  void initState() {
    super.initState();

    _gps = context.read<GpsService>();
    _gps.addListener(_onGps);

    final user = context.read<AuthService>().user;
    if (user != null) {
      _officer.text = user.name;
      if (AppText.designations.contains(user.designation)) {
        _designation = user.designation;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _onGps());
  }

  @override
  void dispose() {
    _gps.removeListener(_onGps);

    for (final c in [
      _beat,
      _lat,
      _lon,
      _locDesc,
      _officer,
      _team,
      _dmgDesc,
      _remarks,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  void _onGps() {
    final loc = _gps.current;
    if (loc == null || _gpsFilled || !mounted) return;

    _useGps();
    _gpsFilled = true;
  }

  void _useGps() {
    final loc = _gps.current;
    if (loc == null) return;

    setState(() {
      _lat.text = loc.lat.toStringAsFixed(4);
      _lon.text = loc.lon.toStringAsFixed(4);

      if (loc.insideRange &&
          loc.rangeName != null &&
          AppText.rangeNames.contains(loc.rangeName)) {
        _range = loc.rangeName!;
        _rangeHint = null;
      } else {
        _range = null;
        _rangeHint = loc.rangeName == null
            ? 'Range could not be detected — please select it.'
            : 'GPS is outside all range boundaries '
                '(nearest: ${loc.rangeName}, '
                '${loc.distanceKm.toStringAsFixed(1)} km). '
                'Please select the range.';
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (d != null) {
      setState(() => _date = d);
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
    );

    if (t != null) {
      setState(() => _time = t);
    }
  }

  Future<void> _pickChase() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _chaseTime ?? _time,
    );

    if (t != null) {
      setState(() => _chaseTime = t);
    }
  }

  Future<void> _addPhoto(bool camera) async {
    final cam = context.read<CameraService>();

    if (camera) {
      final p = await cam.capture();
      if (p != null && mounted) {
        setState(() => _photos.add(p));
      }
    } else {
      final ps = await cam.pickFromGallery();
      if (ps.isNotEmpty && mounted) {
        setState(() => _photos.addAll(ps));
      }
    }
  }

  Future<void> _submit() async {
    final notify = context.read<NotificationService>();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_counts.total == 0) {
      notify.show(
        ToastType.warn,
        'Add Count',
        'Enter at least 1 elephant',
        icon: '⚠️',
      );
      return;
    }

    if (_range == null ||
        _lat.text.trim().isEmpty ||
        _lon.text.trim().isEmpty) {
      notify.show(
        ToastType.warn,
        'Location Required',
        'Select a range and provide latitude and longitude',
        icon: '📍',
      );
      return;
    }

    final api = context.read<ApiService>();

    setState(() => _submitting = true);

    try {
      final report = ReportModel(
        id: 'RP-${DateTime.now().millisecondsSinceEpoch}',
        range: _range!,
        beat: _beat.text.trim(),
        lat: double.parse(_lat.text.trim()),
        lon: double.parse(_lon.text.trim()),
        locationDescription: _locDesc.text.trim(),
        dateTime: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        officer: _officer.text.trim(),
        designation: _designation,
        team: _team.text.trim(),
        counts: _counts,
        damage: _damage,
        damageType: _damage ? _damageType : '',
        damageDescription: _damage ? _dmgDesc.text.trim() : '',
        chaseStart: _chaseTime == null ? '' : Helpers.timeOfDay(_chaseTime!),
        chaseResult: _chaseResult,
        remarks: _remarks.text.trim(),
        elephantPhotoPaths: _photos.map((f) => f.path).toList(),
        damagePhotoPaths: const [],
      );

      // ONE upload path only: submitReport creates the report and uploads
      // the photos. Do NOT call uploadReportPhotos() again afterwards.
      final res = await api.submitReport(
        report,
        photos: List<XFile>.from(_photos),
      );

      debugPrint(
        'Report submitted. photos selected: ${_photos.length}, '
        'pendingSync: ${res.pendingSync}',
      );

      if (!mounted) return;

      notify.show(
        res.pendingSync ? ToastType.warn : ToastType.ok,
        res.pendingSync ? 'Report saved offline' : 'Report Submitted',
        res.pendingSync
            ? 'Will be sent to HQ when network returns'
            : '${report.range} · ${report.total} elephants · Sent to HQ',
        icon: res.pendingSync ? '📡' : '✅',
      );

      _resetForm();
    } catch (e) {
      debugPrint('Submit failed: $e');

      if (!mounted) return;

      notify.show(
        ToastType.warn,
        'Submission Failed',
        'Could not submit the report. Please try again.',
        icon: '⚠️',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _counts = ElephantCounts();
      _photos.clear();
      _damage = false;
      _damageType = '';
      _chaseTime = null;

      _beat.clear();
      _locDesc.clear();
      _team.clear();
      _dmgDesc.clear();
      _remarks.clear();
    });
  }

  Widget _two(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }

  Widget _gap() {
    return const SizedBox(height: 10);
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> cb, {
    bool allowEmpty = false,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.bg2,
      decoration: InputDecoration(
        labelText: label,
      ),
      style: AppText.body(
        size: 13,
        color: AppColors.text,
      ),
      items: [
        if (allowEmpty)
          const DropdownMenuItem<String>(
            value: '',
            child: Text('-- Select --'),
          ),
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (selected) {
        cb(selected ?? value);
      },
    );
  }

  Widget _picker(
    String label,
    String text,
    VoidCallback onTap,
    IconData icon,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: Icon(icon, size: 18),
        ),
        child: Text(
          text,
          style: AppText.body(
            size: 13,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _photoPreview() {
    if (_photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _gap(),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final photo = _photos[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 82,
                      height: 82,
                      child: FutureBuilder(
                        future: photo.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return Container(
                              color: AppColors.card2,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                              ),
                            );
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: AppColors.card2,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _photos.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: '📅 Incident Details',
            child: Column(
              children: [
                _two(
                  _picker(
                    'Date',
                    Helpers.date(_date),
                    _pickDate,
                    Icons.calendar_today,
                  ),
                  _picker(
                    'Time',
                    _time.format(context),
                    _pickTime,
                    Icons.access_time,
                  ),
                ),
                _gap(),
                _two(
                  DropdownButtonFormField<String>(
                    key: ValueKey('range-$_range'),
                    initialValue: _range,
                    isExpanded: true,
                    dropdownColor: AppColors.bg2,
                    decoration: InputDecoration(
                      labelText: 'Range',
                      helperText: _rangeHint,
                      helperMaxLines: 3,
                      helperStyle: AppText.body(
                        size: 10,
                        color: AppColors.amber,
                      ),
                    ),
                    style: AppText.body(
                      size: 13,
                      color: AppColors.text,
                    ),
                    hint: const Text('Select range'),
                    items: [
                      for (final range in AppText.rangeNames)
                        DropdownMenuItem<String>(
                          value: range,
                          child: Text(
                            range,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) {
                      return value == null ? 'Select a range' : null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _range = value;
                        _rangeHint = null;
                      });
                    },
                  ),
                  TextFormField(
                    controller: _beat,
                    decoration: const InputDecoration(
                      labelText: 'Beat / Section',
                      hintText: 'e.g. Beat 3 – Kovai Road',
                    ),
                  ),
                ),
                _gap(),
                _two(
                  TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                    ),
                    validator: Validators.latitude,
                  ),
                  TextFormField(
                    controller: _lon,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                    ),
                    validator: Validators.longitude,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _useGps,
                    icon: const Icon(
                      Icons.my_location,
                      size: 14,
                    ),
                    label: const Text('Use current GPS'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _locDesc,
                  decoration: const InputDecoration(
                    labelText: 'Location Description',
                    hintText: 'e.g. Near NH-209, village boundary',
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '👤 Reporting Officer',
            child: Column(
              children: [
                _two(
                  TextFormField(
                    controller: _officer,
                    decoration: const InputDecoration(
                      labelText: 'Officer Name',
                      hintText: 'Full name',
                    ),
                    validator: (value) {
                      return Validators.required(
                        value,
                        'Officer name',
                      );
                    },
                  ),
                  _dropdown(
                    'Designation',
                    _designation,
                    AppText.designations,
                    (value) {
                      setState(() => _designation = value);
                    },
                  ),
                ),
                _gap(),
                TextFormField(
                  controller: _team,
                  decoration: const InputDecoration(
                    labelText: 'Team Members Attended',
                    hintText: 'Names, comma separated',
                  ),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '🐘 Elephant Count',
            child: ElephantCounterGrid(
              counts: _counts,
              onChanged: (total, details) {
                setState(() {
                  _counts = _counts.change(total, details);
                });
              },
            ),
          ),
          SectionCard(
            title: '💥 Damage Assessment',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Damage Caused?',
                  style: AppText.body(size: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _yesNo(
                        'YES',
                        _damage,
                        AppColors.red,
                        () {
                          setState(() {
                            _damage = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _yesNo(
                        'NO',
                        !_damage,
                        AppColors.green,
                        () {
                          setState(() {
                            _damage = false;
                            _damageType = '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_damage) ...[
                  _gap(),
                  _dropdown(
                    'Damage Type',
                    _damageType,
                    AppText.damageTypes,
                    (value) {
                      setState(() => _damageType = value);
                    },
                    allowEmpty: true,
                  ),
                  _gap(),
                  TextFormField(
                    controller: _dmgDesc,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Damage Description',
                      hintText: 'Describe damage in detail...',
                    ),
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: '🏃 Chase-Back Operation',
            child: Column(
              children: [
                _two(
                  _picker(
                    'Chase Started',
                    _chaseTime?.format(context) ?? '--:--',
                    _pickChase,
                    Icons.access_time,
                  ),
                  _dropdown(
                    'Result',
                    _chaseResult,
                    AppText.chaseResults,
                    (value) {
                      setState(() => _chaseResult = value);
                    },
                  ),
                ),
                _gap(),
                TextFormField(
                  controller: _remarks,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Observations',
                    hintText: 'Behaviour, recurring location, etc.',
                  ),
                ),
                _gap(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addPhoto(true),
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 16,
                        ),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addPhoto(false),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                _photoPreview(),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.bg,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                : Text(
                    '✅ SUBMIT FULL REPORT TO HQ',
                    style: AppText.heading(
                      size: 16,
                      color: AppColors.bg,
                      letterSpacing: 1,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _yesNo(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : AppColors.bg2,
          border: Border.all(
            color: selected ? color : AppColors.border2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 12,
            color: selected ? color : AppColors.text2,
          ),
        ),
      ),
    );
  }
}
