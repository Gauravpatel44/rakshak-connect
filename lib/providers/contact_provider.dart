import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../services/firestore_service.dart';
import '../services/widget_service.dart';

/// Manages emergency contacts with Firestore sync and offline caching
class ContactProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ContactModel> _contacts = [];
  List<ContactModel> _filteredContacts = [];
  // Bug #2 fix: changed from 'final' to mutable
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Bug #3 fix: store the stream subscription so it can be cancelled
  StreamSubscription<List<ContactModel>>? _contactsSub;

  // ── Getters ───────────────────────────────────────
  List<ContactModel> get contacts =>
      _searchQuery.isEmpty ? _contacts : _filteredContacts;
  List<ContactModel> get favoriteContacts =>
      _contacts.where((c) => c.isFavorite).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _contacts.length;

  // ── Load Contacts ─────────────────────────────────

  /// Start streaming contacts from Firestore for a user
  void loadContacts(String userId) {
    // Bug #3 fix: cancel any previous subscription before opening a new one
    _contactsSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _contactsSub = _firestoreService.streamContacts(userId).listen(
      (contacts) {
        _contacts = contacts;
        _isLoading = false;
        _applySearch();
        _cacheContacts(); // Offline cache
        WidgetService().updateWidgetData(contactCount: contacts.length);
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        _loadFromCache(); // Fallback to cache
        notifyListeners();
      },
    );
  }

  // ── Add Contact ───────────────────────────────────

  Future<bool> addContact(ContactModel contact) async {
    try {
      await _firestoreService.addContact(contact);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Update Contact ────────────────────────────────

  Future<bool> updateContact(ContactModel contact) async {
    try {
      await _firestoreService.updateContact(contact);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Delete Contact ────────────────────────────────

  Future<bool> deleteContact(String contactId) async {
    try {
      await _firestoreService.deleteContact(contactId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Toggle Favorite ───────────────────────────────

  Future<void> toggleFavorite(ContactModel contact) async {
    final updated = contact.copyWith(isFavorite: !contact.isFavorite);
    await updateContact(updated);
  }

  // ── Search ────────────────────────────────────────

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = _contacts;
    } else {
      _filteredContacts = _contacts
          .where((c) =>
              c.name.toLowerCase().contains(_searchQuery) ||
              c.phone.contains(_searchQuery) ||
              c.relationship.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  // ── Offline Cache ─────────────────────────────────

  static const String _cacheKey = 'cached_contacts';

  Future<void> _cacheContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Bug #20 fix: store contactId in the JSON so it's restored correctly
      final json = _contacts.map((c) {
        final map = c.toMap();
        map['contactId'] = c.contactId; // persist the ID
        return jsonEncode(map);
      }).toList();
      await prefs.setStringList(_cacheKey, json);
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cacheKey) ?? [];
      // Bug #20 fix: restore contactId from JSON instead of passing empty ''
      _contacts = cached.map((s) {
        final map = jsonDecode(s) as Map<String, dynamic>;
        final id = map['contactId'] as String? ?? '';
        return ContactModel.fromMap(map, id);
      }).toList();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _contacts = [];
    _filteredContacts = [];
    _searchQuery = '';
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Bug #3 fix: cancel stream subscription to prevent memory leaks
    _contactsSub?.cancel();
    super.dispose();
  }
}
