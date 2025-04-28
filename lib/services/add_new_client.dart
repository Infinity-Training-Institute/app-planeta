import 'package:app_planeta/infrastructure/local_db/dao/datos_cliente_dao.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';

class AddNewClient {
  // Method to add a new client to the database
  Future<int> addClient(DatosClienteModel cliente) async {
    try {
      // Validate client data before attempting to insert
      if (cliente.clcecl.isEmpty ||
          cliente.clnmcl.isEmpty ||
          cliente.clpacl.isEmpty) {
        throw Exception('Client ID, name, and last name are required fields');
      }

      // Insert the client using the existing insertCliente method
      final dao = DatosClienteDao();
      final clientId = await dao.insertCliente(cliente);

      return clientId;
    } catch (e) {
      throw Exception('Failed to add client: $e');
    }
  }
}

// obtener el cliente por id
class GetClientById {
  // Method to get a client by ID from the database
  Future<DatosClienteModel?> getClientById(String clientId) async {
    try {
      // Validate client ID before attempting to fetch
      if (clientId.isEmpty) {
        throw Exception('Client ID is required');
      }

      // Fetch the client using the existing method in DatosClienteDao
      final dao = DatosClienteDao();
      final clients = await dao.getClientes();

      // Find the client with the matching ID
      final client = clients.firstWhere(
        (c) => c.clcecl == clientId,
        orElse:
            () => DatosClienteModel(
              clcecl: '',
              clnmcl: '',
              clpacl: '',
              clsacl: '',
              clmail: '',
              cldire: '',
              clciud: '',
              cltele: '',
              clusua: '',
              cltipo: '',
              clfecha: DateTime.now().toString(),
              cl_nube: '', // Default to current date
              // Add other required fields with default values here
            ),
      );

      return client;
    } catch (e) {
      throw Exception('Failed to get client: $e');
    }
  }
}
