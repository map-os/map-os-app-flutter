import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapos_app/api/apiConfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapos_app/models/eventModel.dart';
import 'package:mapos_app/controllers/TokenController.dart';
import 'package:mapos_app/utils/cache_helper.dart';
import 'package:flutter/foundation.dart';

class CalendarController {
  Future<List<Event>> fetchCalendarData() async {
    await _checkAPIConfig();
    if (await hasInternetConnection()) {
      try {
        return await _fetchEventsFromAPI();
      } catch (e) {
        return await _loadEventsFromLocal();
      }
    } else {
      debugPrint('Sem acesso à internet, carregando dados locais.');
      return await _loadEventsFromLocal();
    }
  }


  Future<void> _checkAPIConfig() async {
    await APIConfig.ensureBaseURLInitialized();
    if (APIConfig.baseURL == null) {
      throw Exception('API URL não configurada. Por favor configure nas configurações.');
    }
  }

  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final result = await http.get(Uri.parse('https://www.google.com/generate_204'));
      return result.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<List<Event>> _fetchEventsFromAPI() async {
    DateTime now = DateTime.now();
    DateTime start = DateTime(now.year, now.month - 6, 1);
    String startString = start.toIso8601String().split('T').first;
    String endString = now.toIso8601String().split('T').first;

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    http.Response response = await _makeRequest(startString, endString, token);

    if (response.statusCode == 403) {
      await TokenController().regenerateToken();
      token = prefs.getString('access_token');
      response = await _makeRequest(startString, endString, token);
    }

    if (response.statusCode == 200) {
      List<Event> events = _parseEvents(response.body);
      await _saveEventsToLocal(events);
      return events;
    } else {
      throw Exception('Erro ao carregar dados do calendário: ${response.reasonPhrase}');
    }
  }

  Future<http.Response> _makeRequest(String startString, String endString, String? token) async {
    var url = Uri.parse('${APIConfig.baseURL}${APIConfig.calendarioEndpoint}?start=$startString&end=$endString');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'App-Version': APIConfig.appVersion,
        'Authorization': 'Bearer $token',
      },
    );
  }

  List<Event> _parseEvents(String responseBody) {
    var data = jsonDecode(responseBody);
    return (data['result']['allOs'] as List)
        .map((item) => Event.fromJson(item))
        .toList();
  }

  Future<void> _saveEventsToLocal(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonEvents = jsonEncode(events.map((e) => e.toJson()).toList());
    await CacheHelper.safeSetString(prefs, 'cached_events', jsonEvents);
    // print('Eventos salvos localmente.');
  }

  Future<List<Event>> _loadEventsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonEvents = prefs.getString('cached_events');
    if (jsonEvents != null) {
      Iterable data = jsonDecode(jsonEvents);
      return data.map((item) => Event.fromJson(item)).toList();
    } else {
      return [];
    }
  }
}
