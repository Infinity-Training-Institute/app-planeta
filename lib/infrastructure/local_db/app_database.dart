import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      version: 2,
      onCreate: (db, version) async {
        // Tabla Usuarios
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Usuarios (
            Cod_Usuario INTEGER PRIMARY KEY AUTOINCREMENT,
            Nombre_Usuario TEXT NOT NULL,
            Apellido_Usuario TEXT NOT NULL,
            Nick_Usuario TEXT NOT NULL,
            Pwd_Usuario TEXT NOT NULL,
            Tipo_Usuario INTEGER NOT NULL,
            Estado_Usuario INTEGER NOT NULL,
            Serie_Imp_Usuario TEXT,
            Factura_Alterna_Usuario INTEGER NOT NULL,
            Caja_Usuario TEXT NOT NULL,
            Stand INTEGER NOT NULL
          )
        ''');

        // tipo usuarios
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Tipo_Usuarios (
            Cod_Tipo INTEGER PRIMARY KEY AUTOINCREMENT,
            Tipo_Nombre TEXT NOT NULL,
            Tipo_Descripcion TEXT NOT NULL
          )
        ''');

        // insertamos los tipos de usuarios
        await db.execute('''
          INSERT INTO Tipo_Usuarios (Tipo_Nombre, Tipo_Descripcion) 
          VALUES 
          ('Administrador', 'Acceso a todos los módulos menos al de facturación'), 
          ('Coordinador', 'Crea usuarios pero solo usuarios de Traspaso, Si anula, Si reimprime, No gestion de productos,Si descarga, No Factura, No logistica, Si datos venta'),
          ('Cajero', 'Solo facturacion normal y especial, No anula, No reimprime'),
          ('Tesorería', 'Usuario Tesorería'),
          ('Comercial', 'Usuario Comercial')
        ''');

        // Tabla Productos
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ISBN TEXT NOT NULL,
            EAN TEXT NOT NULL,
            Referencia TEXT NOT NULL,
            Desc_Referencia TEXT NOT NULL,
            Precio INTEGER NOT NULL,
            Cantidad INTEGER NOT NULL,
            Autor TEXT NOT NULL,
            Sello_Editorial TEXT NOT NULL,
            Familia INTEGER NOT NULL
          )
        ''');

        // productos expeciales
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Productos_Especiales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            Referencia TEXT NOT NULL,
            Desc_Referencia TEXT NOT NULL,
            Porcentaje_Descuento INTEGER NOT NULL,
            Precio INTEGER NOT NULL,
            Acumula TEXT NOT NULL,
            Acumula_Obsequio TEXT NOT NULL,
            Usuario TEXT NOT NULL
          )
        ''');

        // producto paquetes
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Productos_Paquetes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            Codigo_Paquete INTEGER NOT NULL,
            Codigo_Ean TEXT NOT NULL,
            Referencia TEXT NOT NULL,
            Desc_Referencia TEXT NOT NULL,
            Precio INTEGER NOT NULL,
            Usuario TEXT NOT NULL
          )
        ''');

        // promociones (3x2, 50%, PROMO HORAS)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Promociones (
            Cod_Promocion INTEGER PRIMARY KEY AUTOINCREMENT,
            Fecha_Promocion TEXT NOT NULL,
            Hora_Desde TEXT NOT NULL,
            Hora_Hasta TEXT NOT NULL,
            Minuto_Hasta TEXT NOT NULL,
            Usuario TEXT NOT NULL,
            Tipo_Promocion TEXT NOT NULL
          )
        ''');

        //Tabla Promocion bono
        await db.execute('''
          CREATE TABLE Promocion_Bono (
            Cod_Promocion INTEGER PRIMARY KEY AUTOINCREMENT,
            Fecha_Promocion TEXT NOT NULL,
            Fecha_Promocion_Hasta TEXT NOT NULL,
            Valor_Maximo INTEGER NOT NULL,
            Descuento_Promocion INTEGER NOT NULL,
            Frase_Bono TEXT NOT NULL
          )
        ''');

        // Tabla Promocion Cantidad
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Promocion_Cantidad (
            Cod_Promocion INTEGER PRIMARY KEY AUTOINCREMENT,
            Productos_Desde INTEGER NOT NULL,
            Productos_Hasta INTEGER NOT NULL,
            Porcentaje_Descuento INTEGER NOT NULL,
            Obsequio TEXT NOT NULL,
            Usuario TEXT NOT NULL
          )
        ''');

        // tabla promocion paquetes
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Promocion_Paquetes (
            Cod_Promocion INTEGER PRIMARY KEY AUTOINCREMENT,
            Descripcion_Paquete TEXT NOT NULL,
            Cantidad_Paquete INTEGER NOT NULL,
            Precio INTEGER NOT NULL,
            Usuario TEXT NOT NULL
          )
        ''');

        // tabla promocion stand
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Promocion_Stand (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            Num_Stand INTEGER NOT NULL
          )
        ''');

        // texto que ira en el footer de la factura
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Texto_Factura (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            descripcion TEXT NOT NULL
          )
        ''');

        // Tabla mcabfa
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mcabfa (
            mcnufa INTEGER NOT NULL,
            mcnuca TEXT NOT NULL,
            mccecl INTEGER NOT NULL,
            mcfefa INTEGER NOT NULL,
            mchora TEXT NOT NULL,
            mcfopa TEXT NOT NULL,
            mcpode INTEGER NOT NULL,
            mcvade INTEGER NOT NULL,
            mctifa TEXT NOT NULL,
            mcvabr INTEGER NOT NULL,
            mcvane INTEGER NOT NULL,
            mcesta TEXT NOT NULL,
            mcvaef INTEGER NOT NULL,
            mcvach INTEGER NOT NULL,
            mcvata INTEGER NOT NULL,
            mcvabo INTEGER NOT NULL,
            mctobo INTEGER NOT NULL,
            mcnubo TEXT NOT NULL,
            mcusua TEXT NOT NULL,
            mcusan TEXT NOT NULL,
            mchoan INTEGER NOT NULL,
            mcnuau TEXT NOT NULL,
            mcnufi INTEGER NOT NULL,
            mccaja TEXT NOT NULL,
            mcufe TEXT NOT NULL,
            mstand INTEGER NOT NULL,
            mnube INTEGER NOT NULL
          )
        ''');

        // Tabla mlinfa
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mlinfa (
            mlnufc INTEGER NOT NULL, -- Numero Factura
            mlnuca TEXT NOT NULL, -- numero de caja
            mlcdpr TEXT NOT NULL, -- Cod. Producto
            mlnmpr TEXT NOT NULL, -- descripcion referencia
            mlpvpr INTEGER NOT NULL, -- pvp bruto
            mlpvne INTEGER NOT NULL, -- pvp neto
            mlcant INTEGER NOT NULL, -- cantidad
            mlesta TEXT NOT NULL, -- estado
            mlestao TEXT NOT NULL, -- Estado Obsequios
            mlfefa INTEGER NOT NULL, -- Fecha Factura
            mlestf TEXT NOT NULL, -- estado factura
            mlusua TEXT NOT NULL, -- usuario
            mlnufi INTEGER NOT NULL, -- Factura Alterna
            mlcaja TEXT NOT NULL, -- Caja
            mstand INTEGER NOT NULL,
            mnube INTEGER NOT NULL
          )
        ''');

        // tabla datos caja
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Datos_Caja (
            Cod_Caja INTEGER PRIMARY KEY AUTOINCREMENT, -- Codigo de la caja
            Stand TEXT NOT NULL, -- Stand
            Numero_Caja TEXT NOT NULL, -- Numero Caja
            Factura_Inicio INTEGER NOT NULL, -- # Factura Inicia
            Numero_Resolucion TEXT NOT NULL, -- Resolucion
            Factura_Actual INTEGER NOT NULL, -- # Factura Actual
            Nick_Usuario TEXT NOT NULL, -- Nick Usuario
            Clave_Tecnica TEXT NOT NULL,
            Factura_Final INTEGER NOT NULL, -- # Factura Final
            Datos_Nube INTEGER NOT NULL
          )
        ''');

        // Tabla datos empresa
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Datos_Empresa (
            Id INTEGER PRIMARY KEY AUTOINCREMENT, -- ID autoincremental
            Nombre_Empresa TEXT NOT NULL, -- Nombre de la empresa
            Nit TEXT NOT NULL, -- NIT
            Direccion TEXT NOT NULL, -- Dirección
            Telefono INTEGER NOT NULL, -- Teléfono
            Email TEXT NOT NULL, -- Correo electrónico
            Logo TEXT NOT NULL
          )
        ''');

        // Tabla clientes
        await db.execute('''
          CREATE TABLE IF NOT EXISTS mclien (
            clcecl INTEGER NOT NULL, -- Cédula del cliente (bigint en MySQL → INTEGER en SQLite)
            clnmcl TEXT NOT NULL, -- Nombre del cliente
            clpacl TEXT NOT NULL, -- Primer apellido
            clsacl TEXT NOT NULL, -- Segundo apellido
            clmail TEXT NOT NULL, -- Correo electrónico
            cldire TEXT NOT NULL, -- Dirección
            clciud TEXT NOT NULL, -- Ciudad
            cltele TEXT NOT NULL, -- Teléfono (bigint en MySQL → INTEGER en SQLite)
            clusua TEXT NOT NULL, -- Usuario
            cl_nube INTEGER NOT NULL, -- Datos en la nube
            cltipo TEXT NOT NULL, -- Tipo de cliente
            clfecha TEXT NOT NULL -- Fecha (date en MySQL → TEXT en SQLite, formato 'YYYY-MM-DD')
          ) 
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS actualizacion_datos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha_actualizacion TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS actualizacion_datos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fecha_actualizacion TEXT NOT NULL
          )
        ''');
        }
      },
    );
  }

  // Obtener usuarios
  static Future<List<Map<String, dynamic>>> getUsuarios() async {
    final db = await database;
    return await db.query('Usuarios');
  }
}
