import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/presentation/components/drawer_component.dart';
import 'package:flutter/material.dart';

class InvoiceComponent extends StatefulWidget {
  final String title;
  final Widget body;

  const InvoiceComponent({super.key, required this.title, required this.body});

  @override
  State<InvoiceComponent> createState() => _InvoiceComponentState();
}

class _InvoiceComponentState extends State<InvoiceComponent> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> usuarios = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final data = await AppDatabase.getUsuarios();
    setState(() {
      usuarios = data;
      isLoading = false;
    });

    debugPrint(usuarios.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: DrawerComponent(),
      body: SafeArea(child: Column(children: [Expanded(child: widget.body)])),
    );
  }
}
