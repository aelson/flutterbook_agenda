import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Nome dos campos na tabela do banco de dados, por isso são constantes
final String contactTable = "contactTable";
final String idColumn = "idColumn";
final String nameColumn = "nameColumn";
final String emailColumn = "emailColumn";
final String phoneColumn = "phoneColumn";

class DatabaseProvider {

  static final DatabaseProvider _instance = DatabaseProvider.internal();

  factory DatabaseProvider() => _instance;

  DatabaseProvider.internal();
  Database? _db;
  
  Future<Database> get db async {
    if(_db != null){
      return _db!;
    } else {
      _db = await initDb();
      return _db!;
    }
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "contactsnew.db");

    return await openDatabase(path, version: 1, onCreate: (Database db, int newerVersion) async {
      await db.execute(
        "CREATE TABLE $contactTable($idColumn INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, $nameColumn TEXT, $emailColumn TEXT,"
            "$phoneColumn TEXT)"
      );
    });
  }

  Future<Contact> saveContact(Contact contact) async {
    Database dbContact = await db;
    contact.id = await dbContact.insert(contactTable, contact.toMap());
    return contact;
  }

  Future<Contact?> getContact(int id) async {
    Database dbContact = await db;
    List<Map> maps = await dbContact.query(contactTable,
      columns: [idColumn, nameColumn, emailColumn, phoneColumn],
      where: "$idColumn = ?",
      whereArgs: [id]);
    if(maps.length > 0){
      return Contact.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> deleteContact(int id) async {
    Database dbContact = await db;
    return await dbContact.delete(contactTable, where: "$idColumn = ?", whereArgs: [id]);
  }

  Future<int> updateContact(Contact contact) async {
    Database dbContact = await db;
    return await dbContact.update(contactTable,
        contact.toMap(),
        where: "$idColumn = ?",
        whereArgs: [contact.id]);
  }

  Future<List<Contact>> getAllContacts() async {
    final Database dbContact = await db;
    final List<Map<String, dynamic>> maps = await dbContact.rawQuery("SELECT * FROM $contactTable");
    return List.generate(maps.length, (i) {
      Contact contact = Contact();
      contact.id = maps[i]['idColumn'] as int;
      contact.name = maps[i]['nameColumn'] as String;
      contact.email = maps[i]['emailColumn'] as String;
      contact.phone = maps[i]['phoneColumn'] as String;
      return contact;
    });
  }

}

class Contact {

  late int? id;
  late String name;
  late String email;
  late String phone;

  Contact() {
    this.name = '';
    this.email = '';
    this.phone = '';
  }

  // Construtor que converte os dados de mapa (JSON) para objeto do contato
  Contact.fromMap(Map? map){
    if (map == null) {
      return;
    }
    id = map[idColumn];
    name = map[nameColumn];
    email = map[emailColumn];
    phone = map[phoneColumn];
  }

  // Método que transforma o objeto do contato em Mapa (JSON) para armazenar no banco de dados
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
    };

    // O id pode ser nulo caso o registro esteja sendo criado já que é o banco de dados que 
    // atribui o ID ao registro no ato de salvar
    //map[idColumn] = id;
    return map;
  }
}