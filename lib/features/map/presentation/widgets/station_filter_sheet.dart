import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/station_entity.dart';
import '../providers/map_providers.dart';

class StationFilterSheet extends ConsumerWidget {
  const StationFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(mapViewNotifierProvider).filters;
    var local = filters;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filtreler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Soket Tipi',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SocketType.values.map((type) {
                  final selected = local.socketTypes.contains(type);
                  return FilterChip(
                    label: Text(_socketLabel(type)),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        final types = Set<SocketType>.from(local.socketTypes);
                        if (v) {
                          types.add(type);
                        } else {
                          types.remove(type);
                        }
                        local = StationFiltersEntity(
                          socketTypes: types,
                          networks: local.networks,
                          minPowerKw: local.minPowerKw,
                          maxPrice: local.maxPrice,
                          onlyAvailable: local.onlyAvailable,
                          minReliability: local.minReliability,
                        );
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Şarj Ağı',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: StationNetwork.values.map((network) {
                  final selected = local.networks.contains(network);
                  return FilterChip(
                    label: Text(network.displayName),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        final networks =
                            Set<StationNetwork>.from(local.networks);
                        if (v) {
                          networks.add(network);
                        } else {
                          networks.remove(network);
                        }
                        local = StationFiltersEntity(
                          socketTypes: local.socketTypes,
                          networks: networks,
                          minPowerKw: local.minPowerKw,
                          maxPrice: local.maxPrice,
                          onlyAvailable: local.onlyAvailable,
                          minReliability: local.minReliability,
                        );
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Yalnızca müsait'),
                value: local.onlyAvailable,
                onChanged: (v) => setState(() {
                  local = StationFiltersEntity(
                    socketTypes: local.socketTypes,
                    networks: local.networks,
                    minPowerKw: local.minPowerKw,
                    maxPrice: local.maxPrice,
                    onlyAvailable: v,
                    minReliability: local.minReliability,
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(mapViewNotifierProvider.notifier)
                            .applyFilters(const StationFiltersEntity());
                        Navigator.pop(context);
                      },
                      child: const Text('Temizle'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(mapViewNotifierProvider.notifier)
                            .applyFilters(local);
                        Navigator.pop(context);
                      },
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _socketLabel(SocketType type) => switch (type) {
        SocketType.ccs2 => 'CCS2',
        SocketType.chademo => 'CHAdeMO',
        SocketType.acType2 => 'AC Type 2',
        SocketType.tesla => 'Tesla',
      };
}
