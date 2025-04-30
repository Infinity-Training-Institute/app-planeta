import 'package:app_planeta/infrastructure/local_db/dao/datos_mcabfa_dao.dart';
import 'package:flutter/material.dart';

class SubeDatosNube extends StatefulWidget {
  const SubeDatosNube({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SubeDatosNubeState createState() => _SubeDatosNubeState();
}

class _SubeDatosNubeState extends State<SubeDatosNube> {
  // Datos simulados para las bases de datos
  int mclienteCount = 125;
  int mlinfaCount = 84;
  int mcabfaCount = 56;
  bool isLoading = false;

  // Función para obtener los datos
  void obtenerDatos() async {
    final countMcafba = await DatosMcabfaDao().getCountMcabfa();
    final data = await DatosMcabfaDao().getAllMcabfa();

    // print
    data.forEach((p) {
      print({
        "mcnufa": p.mcnufa,
        "mcnuca": p.mcnuca,
        "mccecl": p.mccecl,
        "mcfefa": p.mcfefa,
        "mchora": p.mchora,
        "mcfopa": p.mcfopa,
        "mcpode": p.mcpode,
        "mcvade": p.mcvade,
        "mctifa": p.mctifa,
        "mcvabr": p.mcvabr,
        "mcvane": p.mcvane,
        "mcesta": p.mcesta,
        "mcvaef": p.mcvaef,
        "mcvach": p.mcvach,
        "mcvata": p.mcvata,
        "mcvabo": p.mcvabo,
        "mctobo": p.mctobo,
        "mcnubo": p.mcnubo,
        "mcusua": p.mcusua,
        "mcusan": p.mcusan,
        "mchoan": p.mchoan,
        "mcnuau": p.mcnuau,
        "mcnufi": p.mcnufi,
        "mccaja": p.mccaja,
        "mcufe": p.mcufe,
        "mstand": p.mstand,
        "mnube": p.mnube
      });
    });
    setState(() {
      mclienteCount = 125;
      mlinfaCount = 84;
      mcabfaCount = countMcafba;
    });
  }

  // Función para subir a la nube
  Future<void> subirDatosNube() async {
    setState(() {
      isLoading = true;
    });

    // Simulamos una operación de carga
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoading = false;
    });

    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos subidos a la nube exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subir Datos a la Nube'), elevation: 2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Contadores de Datos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _buildDataCounter('mcliente', mclienteCount, Colors.blue.shade100),
            const SizedBox(height: 16),
            _buildDataCounter('mlinfa', mlinfaCount, Colors.green.shade100),
            const SizedBox(height: 16),
            _buildDataCounter('mcabfa', mcabfaCount, Colors.orange.shade100),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: isLoading ? null : subirDatosNube,
              icon:
                  isLoading
                      ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                      : const Icon(Icons.cloud_upload),
              label: Text(
                isLoading ? 'Subiendo...' : 'Subir a la nube',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCounter(String tableName, int count, Color bgColor) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            tableName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
