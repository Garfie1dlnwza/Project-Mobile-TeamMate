import 'package:cloud_firestore/cloud_firestore.dart';

/// This class provides utility methods to migrate existing Firestore data
/// to support comments and reactions on posts, polls, and tasks.
class FirestoreDataMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrates posts, polls, and tasks collections to add required fields
  /// for OK reactions and comments.
  Future<void> migrateDataForInteractions() async {
    try {
      // Migrate posts collection
      await _migrateCollection('posts');

      // Migrate polls collection
      await _migrateCollection('polls');

      // Migrate tasks collection
      await _migrateCollection('tasks');

      print('✅ Data migration completed successfully');
    } catch (e) {
      print('❌ Error during data migration: $e');
      rethrow;
    }
  }

  /// Migrates a specific collection by adding reaction and comment fields
  Future<void> _migrateCollection(String collectionName) async {
    try {
      // Get all documents in the collection
      final QuerySnapshot snapshot =
          await _firestore.collection(collectionName).get();

      print(
        '⏳ Migrating $collectionName collection (${snapshot.docs.length} documents)...',
      );

      // Batch write to improve performance and ensure atomic operations
      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Only update if the fields don't already exist
        bool needsUpdate = false;
        Map<String, dynamic> updateData = {};

        if (!data.containsKey('okReactions')) {
          updateData['okReactions'] = [];
          needsUpdate = true;
        }

        if (!data.containsKey('okCount')) {
          updateData['okCount'] = 0;
          needsUpdate = true;
        }

        if (!data.containsKey('commentCount')) {
          updateData['commentCount'] = 0;
          needsUpdate = true;
        }

        if (needsUpdate) {
          batch.update(doc.reference, updateData);
          count++;

          // Firestore batches have a limit of 500 operations
          if (count >= 450) {
            await batch.commit();
            print('✅ Committed batch of $count updates');
            count = 0;
            // Create a new batch
            final WriteBatch newBatch = _firestore.batch();
            batch = newBatch;
          }
        }
      }

      // Commit any remaining batch operations
      if (count > 0) {
        await batch.commit();
        print('✅ Committed final batch of $count updates');
      }

      print('✅ Migration of $collectionName completed');
    } catch (e) {
      print('❌ Error migrating $collectionName: $e');
      rethrow;
    }
  }

  /// Run this method to check the migration status
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    final Map<String, dynamic> status = {
      'posts': await _checkCollectionStatus('posts'),
      'polls': await _checkCollectionStatus('polls'),
      'tasks': await _checkCollectionStatus('tasks'),
    };

    return status;
  }

  /// Check the migration status of a specific collection
  Future<Map<String, dynamic>> _checkCollectionStatus(
    String collectionName,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection(collectionName).get();

      int total = snapshot.docs.length;
      int withOkReactions = 0;
      int withOkCount = 0;
      int withCommentCount = 0;

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('okReactions')) withOkReactions++;
        if (data.containsKey('okCount')) withOkCount++;
        if (data.containsKey('commentCount')) withCommentCount++;
      }

      return {
        'total': total,
        'withOkReactions': withOkReactions,
        'withOkCount': withOkCount,
        'withCommentCount': withCommentCount,
        'migrationComplete':
            (withOkReactions == total &&
                withOkCount == total &&
                withCommentCount == total),
      };
    } catch (e) {
      print('❌ Error checking $collectionName status: $e');
      return {'error': e.toString()};
    }
  }
}
