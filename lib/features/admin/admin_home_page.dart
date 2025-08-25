import 'package:flutter/material.dart';
import 'api/admin_api.dart';
import 'package:attendex_app/core/http_error.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),

      body: Column(
        children: [
          const SizedBox(height: 21),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Zones'),
              Tab(text: 'Shifts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _UsersTab(),
                _ZonesTabEditable(),
                _ShiftsTabEditable(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======= USERS (same as before, read+actions) =======
class _UsersTab extends StatefulWidget {
  const _UsersTab({super.key});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _api = AdminApi();
  List<dynamic>? rows;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      rows = await _api.listUsers();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
  Future<void> _setRole(String id, String role) async {
    try {
      await _api.setUserRole(id, role);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _setActive(String id, bool active) async {
    try {
      await _api.setUserActive(id, active);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  @override
  Widget build(BuildContext c) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (rows == null) return const Center(child: Text('Failed to load users'));
    if (rows!.isEmpty) return const Center(child: Text('No users'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: rows!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = rows![i] as Map;
          final id = (u['id'] ?? u['_id']).toString();
          final email = (u['email'] ?? '').toString();
          final name = (u['name'] ?? '').toString();
          final role = (u['role'] ?? 'EMPLOYEE').toString();
          final active = (u['active'] ?? true) as bool;
          return ListTile(
            title: Text(name.isEmpty ? email : name),
            subtitle: Text('$email • $id'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                      value: 'EMPLOYEE',
                      child: Text('EMPLOYEE'),
                    ),
                    DropdownMenuItem(value: 'HR', child: Text('HR')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                  ],
                  onChanged: (v) => v == null ? null : _setRole(id, v),
                ),
                const SizedBox(width: 8),
                Switch(value: active, onChanged: (v) => _setActive(id, v)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ======= ZONES (editable) =======
class _ZonesTabEditable extends StatefulWidget {
  const _ZonesTabEditable({super.key});
  @override
  State<_ZonesTabEditable> createState() => _ZonesTabEditableState();
}

class _ZonesTabEditableState extends State<_ZonesTabEditable> {
  final _api = AdminApi();
  List<dynamic>? rows;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      rows = await _api.listZones();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final r = await showDialog<_ZoneFormResult>(
      context: context,
      builder: (_) => _ZoneFormDialog(),
    );
    if (r == null) return;
    try {
      await _api.createZone(
        name: r.name,
        lat: r.lat,
        lng: r.lng,
        radiusMeters: r.radius,
      );
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _edit(Map z) async {
    final id = (z['id'] ?? z['_id']).toString();
    final center = z['center'] is Map ? (z['center'] as Map) : {};
    final coords = (center['coordinates'] as List?) ?? [];
    final curLat = coords.length == 2 ? (coords[1] as num).toDouble() : 0.0;
    final curLng = coords.length == 2 ? (coords[0] as num).toDouble() : 0.0;
    final r = await showDialog<_ZoneFormResult>(
      context: context,
      builder: (_) => _ZoneFormDialog(
        initialName: (z['name'] ?? '').toString(),
        initialLat: curLat,
        initialLng: curLng,
        initialRadius: (z['radiusMeters'] as num?)?.toDouble() ?? 300,
      ),
    );
    if (r == null) return;
    try {
      await _api.updateZone(
        id: id,
        name: r.name,
        lat: r.lat,
        lng: r.lng,
        radiusMeters: r.radius,
      );
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _delete(Map z) async {
    final id = (z['id'] ?? z['_id']).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete zone?'),
        content: Text('This cannot be undone.\n\n${z['name']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteZone(id);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows == null
          ? const Center(child: Text('Failed to load zones'))
          : rows!.isEmpty
          ? const Center(child: Text('No zones'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: rows!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final z = rows![i] as Map;
                  final name = (z['name'] ?? 'Zone').toString();
                  final radius = (z['radiusMeters'] ?? '').toString();
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('Radius: $radius m'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _edit(z),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(z),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ZoneFormResult {
  _ZoneFormResult(this.name, this.lat, this.lng, this.radius);
  final String name;
  final double lat;
  final double lng;
  final double radius;
}

class _ZoneFormDialog extends StatefulWidget {
  const _ZoneFormDialog({
    super.key,
    this.initialName = '',
    this.initialLat = 0,
    this.initialLng = 0,
    this.initialRadius = 300,
  });
  final String initialName;
  final double initialLat;
  final double initialLng;
  final double initialRadius;
  @override
  State<_ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends State<_ZoneFormDialog> {
  final _f = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.initialName);
  late final lat = TextEditingController(text: widget.initialLat.toString());
  late final lng = TextEditingController(text: widget.initialLng.toString());
  late final rad = TextEditingController(text: widget.initialRadius.toString());
  @override
  void dispose() {
    name.dispose();
    lat.dispose();
    lng.dispose();
    rad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AlertDialog(
      title: const Text('Zone'),
      content: Form(
        key: _f,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: lat,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Number' : null,
              ),
              TextFormField(
                controller: lng,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Number' : null,
              ),
              TextFormField(
                controller: rad,
                decoration: const InputDecoration(labelText: 'Radius (m)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v ?? '') == null ? 'Number' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_f.currentState?.validate() ?? false)) return;
            Navigator.pop(
              c,
              _ZoneFormResult(
                name.text.trim(),
                double.parse(lat.text),
                double.parse(lng.text),
                double.parse(rad.text),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ======= SHIFTS (editable) =======
class _ShiftsTabEditable extends StatefulWidget {
  const _ShiftsTabEditable({super.key});
  @override
  State<_ShiftsTabEditable> createState() => _ShiftsTabEditableState();
}

class _ShiftsTabEditableState extends State<_ShiftsTabEditable> {
  final _api = AdminApi();
  List<dynamic>? rows;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(prettyDioError(e))));
  Future<void> _load() async {
    setState(() => loading = true);
    try {
      rows = await _api.listShifts();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final r = await showDialog<_ShiftFormResult>(
      context: context,
      builder: (_) => const _ShiftFormDialog(),
    );
    if (r == null) return;
    try {
      await _api.createShift(name: r.name, start: r.start, end: r.end);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _edit(Map s) async {
    final id = (s['id'] ?? s['_id']).toString();
    final r = await showDialog<_ShiftFormResult>(
      context: context,
      builder: (_) => _ShiftFormDialog(
        initialName: (s['name'] ?? '').toString(),
        initialStart: (s['start'] ?? '').toString(),
        initialEnd: (s['end'] ?? '').toString(),
      ),
    );
    if (r == null) return;
    try {
      await _api.updateShift(id: id, name: r.name, start: r.start, end: r.end);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _delete(Map s) async {
    final id = (s['id'] ?? s['_id']).toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shift?'),
        content: Text('This cannot be undone.\n\n${s['name']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteShift(id);
      await _load();
    } catch (e) {
      _snack(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows == null
          ? const Center(child: Text('Failed to load shifts'))
          : rows!.isEmpty
          ? const Center(child: Text('No shifts'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: rows!.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final s = rows![i] as Map;
                  final name = (s['name'] ?? 'Shift').toString();
                  final start = (s['start'] ?? '').toString();
                  final end = (s['end'] ?? '').toString();
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('$start – $end'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _edit(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(s),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _ShiftFormResult {
  _ShiftFormResult(this.name, this.start, this.end);
  final String name;
  final String start;
  final String end;
}

class _ShiftFormDialog extends StatefulWidget {
  const _ShiftFormDialog({
    super.key,
    this.initialName = '',
    this.initialStart = '09:00',
    this.initialEnd = '17:00',
  });
  final String initialName;
  final String initialStart;
  final String initialEnd;
  @override
  State<_ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<_ShiftFormDialog> {
  final _f = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.initialName);
  late final start = TextEditingController(text: widget.initialStart);
  late final end = TextEditingController(text: widget.initialEnd);
  @override
  void dispose() {
    name.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    return AlertDialog(
      title: const Text('Shift'),
      content: Form(
        key: _f,
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: start,
                decoration: const InputDecoration(labelText: 'Start (HH:mm)'),
                validator: (v) =>
                    (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v))
                    ? 'HH:mm'
                    : null,
              ),
              TextFormField(
                controller: end,
                decoration: const InputDecoration(labelText: 'End (HH:mm)'),
                validator: (v) =>
                    (v == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(v))
                    ? 'HH:mm'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_f.currentState?.validate() ?? false)) return;
            Navigator.pop(
              c,
              _ShiftFormResult(
                name.text.trim(),
                start.text.trim(),
                end.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
