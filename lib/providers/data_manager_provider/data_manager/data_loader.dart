import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../data/models/hadith.dart';
import '../network_service/network_checker.dart';
import '../network_service/remote_version_fetcher.dart';
import '../network_service/remote_json_fetcher.dart';
import '../local_storage_service/local_version_handler.dart';
import '../local_storage_service/local_json_handler.dart';
import '../data_parser/data_list_parser.dart';

class DataLoader {
  final NetworkChecker _networkChecker;
  final RemoteVersionFetcher _versionFetcher;
  final RemoteJsonFetcher _jsonFetcher;
  final LocalVersionHandler _versionHandler;
  final LocalJsonHandler _jsonHandler;
  final HadithListParser _parser;
  dynamic _jsonData; // Store JSON data

  DataLoader()
      : _networkChecker = NetworkChecker(),
        _versionFetcher = RemoteVersionFetcher(),
        _jsonFetcher = RemoteJsonFetcher(),
        _versionHandler = LocalVersionHandler(),
        _jsonHandler = LocalJsonHandler(),
        _parser = HadithListParser();

  Future<List<Hadith>> loadHadiths(AsyncValue<List<Hadith>> Function(List<Hadith>?) updateState) async {
    try {
      final connected = await _networkChecker.isConnectedToInternet();
      List<Hadith> hadiths = [];
      if (connected) {
        final remoteVersion = await _versionFetcher.fetchRemoteVersion();
        final localVersion = await _versionHandler.getLocalVersion();
        final Logger _logger = Logger();
        _logger.d('remoteVersion= $remoteVersion localVersion= $localVersion');
        if (remoteVersion > localVersion) {
          final remoteJson = await _jsonFetcher.fetchRemoteJson();
          if (remoteJson != null) {
            _jsonData = remoteJson; // Store the remote JSON data
            hadiths = _parser.parseHadithList(remoteJson);
            if (hadiths.isNotEmpty) {
              await _jsonHandler.saveHadithJson(remoteJson);
              await _versionHandler.setLocalVersion(remoteVersion);
              updateState(hadiths); // Pass non-null list
              return hadiths;
            }
          }
        }
      }
      final localJson = await _jsonHandler.getLocalHadithJson();
      if (localJson != null) {
        _jsonData = json.decode(localJson); // Store the local JSON data
        hadiths = _parser.parseHadithList(_jsonData);
      }
      updateState(hadiths.isEmpty ? null : hadiths); // Pass null or non-null list
      return hadiths;
    } catch (e, st) {
      final Logger _logger = Logger();
      _logger.d('i am here');
      updateState(null); // Pass null on error
      rethrow;
    }
  }

  Future<dynamic> getJsonData() async {
    if (_jsonData == null) {
      // Call loadHadiths to populate _jsonData
      await loadHadiths((hadiths) {
        return AsyncValue.data(hadiths ?? []); // Ensure non-null list for AsyncValue.data
      });
    }
    return _jsonData;
  }
}