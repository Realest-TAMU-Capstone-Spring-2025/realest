// File: test/services/user_provider_test.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:realest/user_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('UserProvider defaults and setters', () {
    test('☀️ default values are correct', () {
      final provider = UserProvider();
      expect(provider.isLoading, isFalse);
      expect(provider.uid, isNull);
      expect(provider.userRole, isNull);
      expect(provider.clients, isEmpty);
      expect(provider.tags, isEmpty);
    });

    test('☀️ setting uid and userRole fires notifications', () {
      final provider = UserProvider();
      int notified = 0;
      provider.addListener(() => notified++);

      provider.uid = 'abc123';
      provider.userRole = 'realtor';

      expect(provider.uid, equals('abc123'));
      expect(provider.userRole, equals('realtor'));
      expect(notified, equals(2));
    });
  });

  group('UserProvider.loadUserData()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('☀️ loads fields and clients/tags when prefs exist', () async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'realtor',
        'uid': 'u1',
        'firstName': 'Jane',
        'clients': ['c1','c2'],
        'tags': ['t1','t2'],
      });
      final provider = UserProvider();
      int notified = 0;
      provider.addListener(() => notified++);

      await provider.loadUserData();

      expect(provider.userRole, 'realtor');
      expect(provider.uid, 'u1');
      expect(provider.firstName, 'Jane');
      expect(provider.clients.map((c) => c['id']), ['c1','c2']);
      expect(provider.tags.map((t) => t['id']), ['t1','t2']);
      expect(notified, equals(1));
    });

    test('🌧 handles missing client/tag lists gracefully', () async {
      SharedPreferences.setMockInitialValues({
        'userRole': 'investor',
        'uid': 'u2',
        'firstName': 'Bob',
      });
      final provider = UserProvider();
      int notified = 0;
      provider.addListener(() => notified++);

      await provider.loadUserData();

      expect(provider.userRole, 'investor');
      expect(provider.uid, 'u2');
      expect(provider.firstName, 'Bob');
      expect(provider.clients, isEmpty);
      expect(provider.tags, isEmpty);
      expect(notified, equals(1));
    });
  });

  group('UserProvider.saveUserData()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('☀️ realtor role saves clients & tags', () async {
      final provider = UserProvider();
      provider.userRole = 'realtor';
      provider.uid = 'u1';
      // manually add clients/tags
      provider.clients.addAll([{'id':'c1'},{'id':'c2'}]);
      provider.tags.addAll([{'id':'t1'},{'id':'t2'}]);

      int notified = 0;
      provider.addListener(() => notified++);

      await provider.saveUserData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userRole'), 'realtor');
      expect(prefs.getString('uid'), 'u1');
      expect(prefs.getStringList('clients'), ['c1','c2']);
      expect(prefs.getStringList('tags'),    ['t1','t2']);
      expect(notified, equals(1));
    });

    test('🌧 investor role skips clients & tags', () async {
      final provider = UserProvider();
      provider.userRole = 'investor';
      provider.uid = 'u2';
      provider.clients.add({'id':'x'});
      provider.tags.add({'id':'y'});

      await provider.saveUserData();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('userRole'), 'investor');
      expect(prefs.getStringList('clients'), isNull);
      expect(prefs.getStringList('tags'),    isNull);
    });
  });

  group('UserProvider.clearUserData()', () {
    test('☀️ clears prefs and resets all fields', () async {
      SharedPreferences.setMockInitialValues({
        'userRole':'r','uid':'u','firstName':'F','clients':['c']
      });
      final provider = UserProvider();
      provider.clients.add({'id':'c1'});
      provider.tags.add({'id':'t1'});

      // act
      provider.clearUserData();
      // wait for async clear
      await Future.delayed(Duration(milliseconds: 10));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);

      expect(provider.userRole, isNull);
      expect(provider.uid,      isNull);
      expect(provider.clients,   isEmpty);
      expect(provider.tags,      isEmpty);
    });
  });
}
