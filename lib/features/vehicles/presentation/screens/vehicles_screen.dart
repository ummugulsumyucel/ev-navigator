import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/loading_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../providers/vehicle_providers.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Araçlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/vehicles/add'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: vehiclesAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Text('Henüz araç eklemediniz'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/vehicles/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Araç Ekle'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, i) {
              final v = vehicles[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              v.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (v.isPrimary)
                            const Chip(
                              label: Text('Birincil'),
                              backgroundColor: AppColors.primary,
                            ),
                        ],
                      ),
                      Text(
                        '${v.year} • ${v.batteryKwh.toStringAsFixed(1)} kWh • ${v.wltpRangeKm.toStringAsFixed(0)} km WLTP',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (v.plate != null)
                        Text(
                          v.plate!,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!v.isPrimary && user != null)
                            TextButton(
                              onPressed: () => ref
                                  .read(vehicleControllerProvider.notifier)
                                  .setPrimary(user.uid, v.id),
                              child: const Text('Birincil Yap'),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Aracı Sil'),
                                  content: Text(
                                    '${v.displayName} silinsin mi?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Sil'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(vehicleControllerProvider.notifier)
                                    .deleteVehicle(v.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  int _year = DateTime.now().year;
  double _batteryKwh = 75;
  double _wltpRangeKm = 450;
  bool _isPrimary = true;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final vehicle = VehicleEntity(
      id: const Uuid().v4(),
      ownerId: user.uid,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: _year,
      batteryKwh: _batteryKwh,
      wltpRangeKm: _wltpRangeKm,
      plate: _plateController.text.trim().isEmpty
          ? null
          : _plateController.text.trim(),
      isPrimary: _isPrimary,
      createdAt: DateTime.now(),
    );

    await ref.read(vehicleControllerProvider.notifier).addVehicle(vehicle);
    if (mounted) {
      final state = ref.read(vehicleControllerProvider);
      if (!state.hasError) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Araç Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Marka'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Marka gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Model gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Plaka (isteğe bağlı)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Yıl'),
                items: List.generate(10, (i) {
                  final y = DateTime.now().year - i;
                  return DropdownMenuItem(value: y, child: Text('$y'));
                }),
                onChanged: (v) => setState(() => _year = v!),
              ),
              const SizedBox(height: 16),
              Text('Batarya: ${_batteryKwh.toStringAsFixed(1)} kWh'),
              Slider(
                value: _batteryKwh,
                min: 30,
                max: 120,
                divisions: 18,
                onChanged: (v) => setState(() => _batteryKwh = v),
              ),
              Text('WLTP Menzil: ${_wltpRangeKm.toStringAsFixed(0)} km'),
              Slider(
                value: _wltpRangeKm,
                min: 200,
                max: 700,
                divisions: 25,
                onChanged: (v) => setState(() => _wltpRangeKm = v),
              ),
              SwitchListTile(
                title: const Text('Birincil araç olarak ayarla'),
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Aracı Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
