import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/inspection_filter.dart';
import '../controllers/insurers_controller.dart';

final class InspectionFiltersSheet extends ConsumerStatefulWidget {
  const InspectionFiltersSheet({required this.initialFilter, super.key});

  final InspectionFilter initialFilter;

  @override
  ConsumerState<InspectionFiltersSheet> createState() =>
      _InspectionFiltersSheetState();
}

final class _InspectionFiltersSheetState
    extends ConsumerState<InspectionFiltersSheet> {
  late final TextEditingController _cedulaController;
  late final TextEditingController _placaController;
  late final TextEditingController _nombreController;
  late final TextEditingController _casoController;

  late int _selectedInsurer;
  late String _selectedInsurerName;

  @override
  void initState() {
    super.initState();

    _selectedInsurer = widget.initialFilter.aseguradora;
    _selectedInsurerName = widget.initialFilter.aseguradoraNombre;

    _cedulaController = TextEditingController(
      text: widget.initialFilter.cedula,
    );

    _placaController = TextEditingController(text: widget.initialFilter.placa);

    _nombreController = TextEditingController(
      text: widget.initialFilter.nombre,
    );

    _casoController = TextEditingController(
      text: widget.initialFilter.nroCaso > 0
          ? widget.initialFilter.nroCaso.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _placaController.dispose();
    _nombreController.dispose();
    _casoController.dispose();

    super.dispose();
  }

  void _apply() {
    final filter = InspectionFilter(
      aseguradora: _selectedInsurer,
      aseguradoraNombre: _selectedInsurerName,
      tipoConsulta: widget.initialFilter.tipoConsulta,
      cedula: _cedulaController.text.trim(),
      placa: _placaController.text.trim().toUpperCase(),
      nombre: _nombreController.text.trim(),
      nroCaso: int.tryParse(_casoController.text.trim()) ?? 0,
    );

    Navigator.of(context).pop(filter);
  }

  void _clear() {
    Navigator.of(
      context,
    ).pop(InspectionFilter(tipoConsulta: widget.initialFilter.tipoConsulta));
  }

  @override
  Widget build(BuildContext context) {
    final insurersState = ref.watch(insurersControllerProvider);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutralDark.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtros',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Busca tus inspecciones por los datos principales.',
                              style: TextStyle(
                                color: AppColors.neutralDark,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Divider(
                  height: 1,
                  color: AppColors.neutralDark.withValues(alpha: 0.08),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Column(
                      children: [
                        _FilterField(
                          controller: _casoController,
                          label: 'Número de caso',
                          icon: Icons.assignment_outlined,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 12),

                        _FilterField(
                          controller: _placaController,
                          label: 'Placa',
                          icon: Icons.directions_car_outlined,
                          textCapitalization: TextCapitalization.characters,
                        ),

                        const SizedBox(height: 12),

                        _FilterField(
                          controller: _cedulaController,
                          label: 'Cédula',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 12),

                        _FilterField(
                          controller: _nombreController,
                          label: 'Asegurado',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                        ),

                        const SizedBox(height: 12),

                        insurersState.when(
                          loading: () {
                            return const _InsurerLoadingField();
                          },
                          error: (error, stackTrace) {
                            return const _InsurerErrorField();
                          },
                          data: (insurers) {
                            final validCodes = insurers
                                .map((item) => item.codigo)
                                .toSet();

                            final selectedValue =
                                validCodes.contains(_selectedInsurer)
                                ? _selectedInsurer
                                : null;

                            return DropdownButtonFormField<int>(
                              initialValue: selectedValue,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Aseguradora',
                                prefixIcon: Icon(Icons.business_outlined),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                              hint: const Text('Selecciona una aseguradora'),
                              items: insurers
                                  .map((insurer) {
                                    return DropdownMenuItem<int>(
                                      value: insurer.codigo,
                                      child: Text(
                                        insurer.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  })
                                  .toList(growable: false),
                              onChanged: (value) {
                                final selectedCode = value ?? 0;

                                var selectedName = '';

                                for (final insurer in insurers) {
                                  if (insurer.codigo == selectedCode) {
                                    selectedName = insurer.nombre.trim();

                                    break;
                                  }
                                }

                                setState(() {
                                  _selectedInsurer = selectedCode;

                                  _selectedInsurerName = selectedName;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.neutralDark.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clear,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpiar'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _apply,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.surface,
      ),
    );
  }
}

final class _InsurerLoadingField extends StatelessWidget {
  const _InsurerLoadingField();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Aseguradora',
        prefixIcon: Icon(Icons.business_outlined),
        filled: true,
        fillColor: AppColors.surface,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Cargando aseguradoras...'),
        ],
      ),
    );
  }
}

final class _InsurerErrorField extends StatelessWidget {
  const _InsurerErrorField();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(
        labelText: 'Aseguradora',
        prefixIcon: Icon(Icons.business_outlined),
        filled: true,
        fillColor: AppColors.surface,
      ),
      child: Text(
        'No fue posible cargar las aseguradoras.',
        style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
      ),
    );
  }
}
