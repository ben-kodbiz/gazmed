import 'dart:convert';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class MedicalKnowledgeEntry {
  final int? id;
  final String entryId;
  final String category;
  final String text;
  final String source;
  final String priority;
  final List<String> keywords;
  final List<double>? embedding;

  MedicalKnowledgeEntry({
    this.id,
    required this.entryId,
    required this.category,
    required this.text,
    required this.source,
    required this.priority,
    required this.keywords,
    this.embedding,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'category': category,
      'text': text,
      'source': source,
      'priority': priority,
      'keywords': json.encode(keywords),
      'embedding': embedding != null ? _encodeEmbedding(embedding!) : null,
    };
  }

  factory MedicalKnowledgeEntry.fromMap(Map<String, dynamic> map) {
    return MedicalKnowledgeEntry(
      id: map['id'],
      entryId: map['entry_id'],
      category: map['category'],
      text: map['text'],
      source: map['source'],
      priority: map['priority'],
      keywords: List<String>.from(json.decode(map['keywords'])),
      embedding:
          map['embedding'] != null ? _decodeEmbedding(map['embedding']) : null,
    );
  }

  static Uint8List _encodeEmbedding(List<double> embedding) {
    final buffer = ByteData(embedding.length * 8);
    for (int i = 0; i < embedding.length; i++) {
      buffer.setFloat64(i * 8, embedding[i], Endian.little);
    }
    return buffer.buffer.asUint8List();
  }

  static List<double> _decodeEmbedding(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    final embedding = <double>[];
    for (int i = 0; i < bytes.length; i += 8) {
      embedding.add(buffer.getFloat64(i, Endian.little));
    }
    return embedding;
  }
}

class MedicalDatabase {
  static Database? _database;
  static const String _databaseName = 'gaza_medical.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _knowledgeTable = 'knowledge_base';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create knowledge base table
    await db.execute('''
      CREATE TABLE $_knowledgeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        text TEXT NOT NULL,
        source TEXT NOT NULL,
        priority TEXT NOT NULL,
        keywords TEXT NOT NULL,
        embedding BLOB,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for better search performance
    await db.execute('CREATE INDEX idx_category ON $_knowledgeTable(category)');
    await db.execute('CREATE INDEX idx_priority ON $_knowledgeTable(priority)');
    await db.execute('CREATE INDEX idx_entry_id ON $_knowledgeTable(entry_id)');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades if needed
    if (oldVersion < newVersion) {
      // Add upgrade logic here
    }
  }

  Future<void> initializeKnowledgeBase() async {
    final db = await database;

    // Check if knowledge base is already populated
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_knowledgeTable'),
        ) ??
        0;

    if (count > 0) {
      print('Knowledge base already initialized with $count entries');
      return;
    }

    print('Initializing medical knowledge base...');

    try {
      // Load knowledge base from assets
      final jsonString = await rootBundle.loadString(
        'assets/medical_knowledge_rag.json',
      );
      final data = json.decode(jsonString);

      final knowledgeEntries = data['knowledge_base'] as List;

      // Insert entries in batch for better performance
      final batch = db.batch();

      for (final entryData in knowledgeEntries) {
        final entry = MedicalKnowledgeEntry(
          entryId: entryData['id'],
          category: entryData['category'],
          text: entryData['text'],
          source: entryData['source'],
          priority: entryData['priority'],
          keywords: List<String>.from(entryData['keywords']),
        );

        batch.insert(_knowledgeTable, entry.toMap());
      }

      await batch.commit(noResult: true);

      final finalCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_knowledgeTable'),
          ) ??
          0;

      print('Knowledge base initialized with $finalCount entries');
    } catch (e) {
      print('Error initializing knowledge base: $e');
      // Create minimal fallback knowledge base
      await _createFallbackKnowledge();
    }
  }

  Future<void> _createFallbackKnowledge() async {
    final db = await database;

    final fallbackEntries = [
      MedicalKnowledgeEntry(
        entryId: 'fallback_fever',
        category: 'fever_management',
        text:
            'For fever: Take paracetamol 500-1000mg every 4-6 hours. Stay hydrated. Rest. Seek medical attention if fever persists over 3 days or exceeds 39°C.',
        source: 'fallback',
        priority: 'medium',
        keywords: ['fever', 'paracetamol', 'temperature'],
      ),
      MedicalKnowledgeEntry(
        entryId: 'fallback_wound',
        category: 'wound_care',
        text:
            'For wounds: Clean hands first. Stop bleeding with pressure. Clean wound with clean water. Apply bandage. Monitor for infection signs.',
        source: 'fallback',
        priority: 'high',
        keywords: ['wound', 'bleeding', 'infection'],
      ),
    ];

    for (final entry in fallbackEntries) {
      await db.insert(_knowledgeTable, entry.toMap());
    }

    print('Fallback knowledge base created');
  }

  Future<void> updateEmbedding(String entryId, List<double> embedding) async {
    final db = await database;

    await db.update(
      _knowledgeTable,
      {'embedding': MedicalKnowledgeEntry._encodeEmbedding(embedding)},
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  Future<List<MedicalKnowledgeEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query(
      _knowledgeTable,
      orderBy: 'priority DESC, category ASC',
    );

    return maps.map((map) => MedicalKnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<MedicalKnowledgeEntry>> getEntriesByCategory(
    String category,
  ) async {
    final db = await database;
    final maps = await db.query(
      _knowledgeTable,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'priority DESC',
    );

    return maps.map((map) => MedicalKnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<MedicalKnowledgeEntry>> searchByKeywords(
    List<String> keywords,
  ) async {
    final db = await database;

    // Create a query that searches for any of the keywords in the text or keywords field
    final keywordConditions = keywords
        .map(
          (keyword) => "(text LIKE '%$keyword%' OR keywords LIKE '%$keyword%')",
        )
        .join(' OR ');

    final maps = await db.query(
      _knowledgeTable,
      where: keywordConditions,
      orderBy: 'priority DESC, category ASC',
      limit: 10,
    );

    return maps.map((map) => MedicalKnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<MedicalKnowledgeEntry>> getEntriesWithEmbeddings() async {
    final db = await database;
    final maps = await db.query(
      _knowledgeTable,
      where: 'embedding IS NOT NULL',
      orderBy: 'id ASC',
    );

    return maps.map((map) => MedicalKnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<MedicalKnowledgeEntry>> getEntriesWithoutEmbeddings() async {
    final db = await database;
    final maps = await db.query(
      _knowledgeTable,
      where: 'embedding IS NULL',
      orderBy: 'priority DESC, id ASC',
      limit: 50, // Process in batches
    );

    return maps.map((map) => MedicalKnowledgeEntry.fromMap(map)).toList();
  }

  Future<List<MedicalKnowledgeEntry>> findSimilarEntries(
    List<double> queryEmbedding, {
    int limit = 5,
  }) async {
    // Get all entries with embeddings
    final entriesWithEmbeddings = await getEntriesWithEmbeddings();

    if (entriesWithEmbeddings.isEmpty) {
      // Fallback to keyword search if no embeddings available
      return [];
    }

    // Calculate cosine similarity for each entry
    final similarities = <MapEntry<MedicalKnowledgeEntry, double>>[];

    for (final entry in entriesWithEmbeddings) {
      if (entry.embedding != null) {
        final similarity = _cosineSimilarity(queryEmbedding, entry.embedding!);
        similarities.add(MapEntry(entry, similarity));
      }
    }

    // Sort by similarity (highest first) and return top results
    similarities.sort((a, b) => b.value.compareTo(a.value));

    return similarities.take(limit).map((entry) => entry.key).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<Map<String, int>> getCategoryStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM $_knowledgeTable 
      GROUP BY category 
      ORDER BY count DESC
    ''');

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['category'] as String] = row['count'] as int;
    }

    return stats;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_knowledgeTable);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

// Helper function for square root (since dart:math might not be available)
double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;

  double guess = x / 2;
  double prev = 0;

  while ((guess - prev).abs() > 0.0001) {
    prev = guess;
    guess = (guess + x / guess) / 2;
  }

  return guess;
}
