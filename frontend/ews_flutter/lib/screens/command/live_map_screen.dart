import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/range_model.dart';
import '../../services/api_service.dart';
import '../../services/gps_service.dart';
import '../../services/map_service.dart';
import '../../services/notification_service.dart';

/// Range map. Everyone can view it (borders coloured by today's elephant
/// count + own location). With [editable] (HQ only) borders can be edited:
/// drag a point to move it, turn on "Add point" and tap the map to insert one,
/// long-press a point to delete it.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key, this.editable = false});
  final bool editable;

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _controller = MapController();
  static const LatLng _home = LatLng(ApiConstants.defaultLat, ApiConstants.defaultLon);

  bool _editing = false;
  bool _addMode = false;
  bool _dragging = false;
  bool _dirty = false;
  String? _selected;
  List<LatLng> _draft = [];

  int _today(List<RangeModel> ranges, String name) {
    for (final r in ranges) {
      if (r.name == name) return r.today;
    }
    return 0;
  }

  // ── details sheet (view mode) ───────────────────────────────
  void _details(RangeBoundary b, List<RangeModel> ranges) {
    final today = _today(ranges, b.name);
    final total = ranges.where((r) => r.name == b.name).fold(0, (s, r) => s + r.totalElephants);
    final status = today > 10 ? '🔴 HIGH ALERT' : (today > 4 ? '🟡 ACTIVE' : '🟢 CLEAR');
    Widget line(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Text(k, style: AppText.body(size: 13)),
            const Spacer(),
            Text(v, style: AppText.body(size: 13, color: AppColors.text, weight: FontWeight.w600)),
          ]),
        );
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.name, style: AppText.heading(size: 20)),
          const SizedBox(height: 10),
          line('Today', '$today elephants'),
          line('Total (2024–2026)', Helpers.number(total)),
          line('Status', status),
        ]),
      ),
    );
  }

  // ── editing ─────────────────────────────────────────────────
  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved border edits will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Discard')),
        ],
      ),
    );
    return ok ?? false;
  }

  void _select(MapService maps, String name) {
    final b = maps.boundaryFor(name);
    if (b == null) return;
    setState(() {
      _selected = name;
      _draft = List.of(b.points);
      _dirty = false;
      _addMode = false;
    });
    _controller.fitCamera(CameraFit.coordinates(
      coordinates: b.points,
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 260),
    ));
  }

  void _startEdit(MapService maps) {
    setState(() => _editing = true);
    _select(maps, _selected ?? maps.boundaries.first.name);
  }

  Future<void> _cancelEdit() async {
    if (!await _confirmDiscard()) return;
    setState(() {
      _editing = false;
      _addMode = false;
      _dirty = false;
      _selected = null;
    });
  }

  Future<void> _save(MapService maps) async {
    final name = _selected;
    if (name == null) return;
    final notify = context.read<NotificationService>();
    final api = context.read<ApiService>();
    await maps.updateBoundary(name, _draft);
    await api.saveRangeBoundary(name, _draft);
    if (!mounted) return;
    notify.show(ToastType.ok, 'Border saved', '$name range boundary updated', icon: '🗺️');
    setState(() {
      _editing = false;
      _addMode = false;
      _dirty = false;
      _selected = null;
    });
  }

  Future<void> _reset(MapService maps) async {
    final name = _selected;
    if (name == null) return;
    await maps.resetBoundary(name);
    if (!mounted) return;
    _select(maps, name);
    context.read<NotificationService>().show(
        ToastType.info, 'Border restored', '$name is back to the original KMZ border',
        icon: '↩️');
  }

  void _onMapTap(TapPosition _, LatLng point) {
    if (!_editing || !_addMode) return;
    setState(() {
      _draft = MapService.insertVertex(_draft, point);
      _dirty = true;
    });
  }

  Marker _handle(int i) => Marker(
        point: _draft[i],
        width: 32,
        height: 32,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => setState(() => _dragging = true),
          onPanUpdate: (d) {
            final cam = _controller.camera;
            final p = cam.project(_draft[i]);
            setState(() {
              _draft[i] = cam.unproject(Point<double>(p.x + d.delta.dx, p.y + d.delta.dy));
              _dirty = true;
            });
          },
          onPanEnd: (_) => setState(() => _dragging = false),
          onPanCancel: () => setState(() => _dragging = false),
          onLongPress: () {
            if (_draft.length <= 3) return;
            setState(() {
              _draft = [..._draft]..removeAt(i);
              _dirty = true;
            });
          },
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ),
      );

  // ── build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final maps = context.watch<MapService>();
    final ranges = context.watch<ApiService>().ranges;
    final loc = context.watch<GpsService>().current;
    Color colorOf(RangeBoundary b) => AppColors.forCount(_today(ranges, b.name));

    return Stack(children: [
      FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _home,
          initialZoom: 9.3,
          onTap: _onMapTap,
          interactionOptions: InteractionOptions(
            flags: _dragging
                ? InteractiveFlag.none
                : (InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
        ),
        children: [
          MapService.tileLayer(),
          PolygonLayer(
            polygons: [
              ...maps.polygons(colorOf: colorOf, exclude: _editing ? _selected : null),
              if (_editing && _draft.length >= 3)
                Polygon(
                  points: _draft,
                  color: AppColors.amber.withValues(alpha: .22),
                  borderColor: AppColors.amber,
                  borderStrokeWidth: 3,
                ),
            ],
          ),
          if (!_editing)
            MarkerLayer(markers: [
              for (final b in maps.boundaries)
                Marker(
                  point: b.centroid,
                  width: 96,
                  height: 28,
                  child: GestureDetector(
                    onTap: () => _details(b, ranges),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorOf(b),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                      ),
                      child: Text(
                        _today(ranges, b.name) > 0
                            ? '${_today(ranges, b.name)}🐘 ${b.name.substring(0, 4)}'
                            : b.name.substring(0, 4),
                        style: AppText.heading(size: 11, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ]),
          if (loc != null)
            MarkerLayer(markers: [
              Marker(
                point: LatLng(loc.lat, loc.lon),
                width: 22,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: .8), blurRadius: 8)],
                  ),
                ),
              ),
            ]),
          if (_editing)
            MarkerLayer(markers: [for (var i = 0; i < _draft.length; i++) _handle(i)]),
        ],
      ),

      // Edit button (HQ only)
      if (widget.editable && !_editing)
        Positioned(
          left: 10,
          top: 10,
          child: ElevatedButton.icon(
            onPressed: maps.boundaries.isEmpty ? null : () => _startEdit(maps),
            icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
            label: const Text('Edit borders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.card2,
              foregroundColor: AppColors.green,
              side: const BorderSide(color: AppColors.green3),
            ),
          ),
        ),

      // Recenter buttons
      Positioned(
        right: 10,
        top: 10,
        child: Column(children: [
          FloatingActionButton.small(
            heroTag: 'map_home_${widget.editable}',
            backgroundColor: AppColors.card2,
            foregroundColor: AppColors.green,
            onPressed: () => _controller.move(_home, 9.3),
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_me_${widget.editable}',
            backgroundColor: AppColors.card2,
            foregroundColor: AppColors.blue,
            onPressed: loc == null ? null : () => _controller.move(LatLng(loc.lat, loc.lon), 12),
            child: const Icon(Icons.my_location),
          ),
        ]),
      ),

      // Legend / edit panel
      Positioned(
        left: 10,
        right: 10,
        bottom: 10,
        child: _editing ? _editPanel(maps) : _legend(loc?.rangeShort),
      ),
    ]);
  }

  Widget _legend(String? where) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg2.withValues(alpha: .92),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Wrap(spacing: 14, runSpacing: 4, children: [
          Text('🔴 HIGH (>10)', style: AppText.body(size: 11, color: AppColors.text3)),
          Text('🟡 MEDIUM (5–10)', style: AppText.body(size: 11, color: AppColors.text3)),
          Text('🟢 LOW / Clear', style: AppText.body(size: 11, color: AppColors.text3)),
          Text('🔵 You${where == null ? '' : ' · $where'}',
              style: AppText.body(size: 11, color: AppColors.text3)),
        ]),
      );

  Widget _editPanel(MapService maps) {
    final name = _selected;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2.withValues(alpha: .96),
        border: Border.all(color: AppColors.amber),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('EDIT BORDER', style: AppText.heading(size: 13, color: AppColors.amber, letterSpacing: 1)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: name,
                isExpanded: true,
                isDense: true,
                dropdownColor: AppColors.bg2,
                style: AppText.body(size: 13, color: AppColors.text),
                items: [
                  for (final b in maps.boundaries)
                    DropdownMenuItem(
                      value: b.name,
                      child: Text('${b.name}${maps.isEdited(b.name) ? '  (edited)' : ''}'),
                    ),
                ],
                onChanged: (v) async {
                  if (v == null || v == name) return;
                  if (await _confirmDiscard()) _select(maps, v);
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Drag a point to move it · long-press a point to delete · '
          '${_draft.length} points${_dirty ? ' · unsaved changes' : ''}',
          style: AppText.body(size: 11, color: AppColors.text3),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          FilterChip(
            label: Text(_addMode ? 'Tap map to add point…' : 'Add point'),
            avatar: const Icon(Icons.add_location_alt_outlined, size: 16),
            selected: _addMode,
            onSelected: (v) => setState(() => _addMode = v),
          ),
          if (name != null && maps.isEdited(name))
            ActionChip(
              label: const Text('Restore original'),
              avatar: const Icon(Icons.undo, size: 16),
              onPressed: () => _reset(maps),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(onPressed: _cancelEdit, child: const Text('Cancel')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _dirty ? () => _save(maps) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.bg,
              ),
              child: const Text('Save border'),
            ),
          ),
        ]),
      ]),
    );
  }
}
