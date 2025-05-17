import 'package:app_planeta/presentation/components/drawer_component.dart';
import 'package:app_planeta/services/shared_preferences.dart';
import 'package:flutter/material.dart';

class DescargaScreen extends StatefulWidget {
  const DescargaScreen({super.key});

  @override
  State<DescargaScreen> createState() => _DescargaScreenState();
}

class _DescargaScreenState extends State<DescargaScreen> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, bool> _opciones = {
    'productos': true,
    'productosEspeciales': true,
    'productosPaquetes': true,
    'textoFactura': true,
    'datosCaja': true,
    'datosEmpresa': true,
    'promociones': true,
    'promocionHora': true,
    'promocionCantidad': true,
  };

  bool _descargarTodo = true;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _prefsService.init();
    final keys = _opciones.keys.toList();
    final saved = _prefsService.getMultipleBools(keys);

    // Convertir posibles valores nulos en false para evitar problemas
    final cleanedSaved = <String, bool>{};
    for (var key in keys) {
      cleanedSaved[key] = saved[key] ?? false;
    }

    setState(() {
      _opciones.updateAll((key, _) => cleanedSaved[key]!);
      _descargarTodo = _opciones.values.every((v) => v);
      _cargando = false;
    });
  }

  Future<void> _savePreferences() async {
    await _prefsService.setMultipleBools(_opciones);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Preferencias guardadas'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  void _toggleDescargarTodo(bool value) {
    setState(() {
      _descargarTodo = value;
      _opciones.updateAll((key, _) => value);
    });
  }

  void _toggleOpcion(String key, bool value) {
    setState(() {
      _opciones[key] = value;
      _descargarTodo = _opciones.values.every((v) => v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Seleccionar Preferencias',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        centerTitle: true,
      ),
      drawer: DrawerComponent(),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: SwitchListTile(
                        title: const Text('Descargar Todo'),
                        value: _descargarTodo,
                        onChanged: _toggleDescargarTodo,
                        activeColor: theme.colorScheme.primary,
                        tileColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          _sectionCard('Datos de Productos', [
                            _checkbox('productos', 'Productos'),
                            _checkbox(
                              'productosEspeciales',
                              'Productos especiales',
                            ),
                            _checkbox(
                              'productosPaquetes',
                              'Productos paquetes',
                            ),
                          ]),
                          _sectionCard('Información Adicional', [
                            _checkbox('textoFactura', 'Texto factura'),
                            _checkbox('datosCaja', 'Datos caja'),
                            _checkbox('datosEmpresa', 'Datos empresa'),
                          ]),
                          _sectionCard('Promociones', [
                            _checkbox('promociones', 'Promociones'),
                            _checkbox('promocionHora', 'Promoción por hora'),
                            _checkbox(
                              'promocionCantidad',
                              'Promoción por cantidad',
                            ),
                          ]),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _savePreferences,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Guardar Selección'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _checkbox(String key, String label) {
    return CheckboxListTile(
      title: Text(label),
      value: _opciones[key],
      onChanged: _descargarTodo ? null : (val) => _toggleOpcion(key, val!),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
