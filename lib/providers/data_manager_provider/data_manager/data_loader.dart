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
import 'data_grouper.dart'; 

class DataLoader {
  final NetworkChecker _networkChecker;
  final RemoteVersionFetcher _versionFetcher;
  final RemoteJsonFetcher _jsonFetcher;
  final LocalVersionHandler _versionHandler;
  final LocalJsonHandler _jsonHandler;
  final HadithListParser _parser;
  dynamic _jsonData;
  final Logger _logger;

  DataLoader()
    : _networkChecker = NetworkChecker(),
      _versionFetcher = RemoteVersionFetcher(),
      _jsonFetcher = RemoteJsonFetcher(),
      _versionHandler = LocalVersionHandler(),
      _jsonHandler = LocalJsonHandler(),
      _parser = HadithListParser(),
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );

  

  Future<List<Hadith>> loadHadiths(
    AsyncValue<List<Hadith>> Function(List<Hadith>?) updateState,
  ) async {
    _logger.i('Starting to load hadiths...');
    try {
      final connected = await _networkChecker.isConnectedToInternet();
      List<Hadith> hadiths = [];

      if (connected) {
        _logger.d('Internet connection available. Checking versions...');
        try {
        
          final remoteVersion = await _versionFetcher.fetchRemoteVersion();
          final localVersion = await _versionHandler.getLocalVersion();
          _logger.d('remoteVersion=$remoteVersion, localVersion=$localVersion');

          if (remoteVersion > localVersion) {
            _logger.i('Remote version is newer. Fetching remote JSON...');
            final remoteJson = await _jsonFetcher.fetchRemoteJson();
            if (remoteJson != null) {
              _jsonData = remoteJson;
              hadiths = _parser.parseHadithList(remoteJson);
              if (hadiths.isNotEmpty) {
                _logger.i(
                  'Successfully parsed ${hadiths.length} hadiths from remote JSON.',
                );
                await _jsonHandler.saveHadithJson(remoteJson);
                await _versionHandler.setLocalVersion(remoteVersion);
                updateState(hadiths);
                return hadiths;
              }
            }
          }
        } catch (e) {
         
          _logger.w(
            'Failed to fetch remote data due to weak internet. Falling back to local data. Error: $e',
          );
          
        }
      }

      
      final localJson = await _jsonHandler.getLocalHadithJson();
      if (localJson != null) {
        _logger.i('Loading hadiths from local JSON.');
        _jsonData = json.decode(localJson);
        hadiths = _parser.parseHadithList(_jsonData);
      }

     
      if (hadiths.isNotEmpty) {
        updateState(hadiths);
      } else {
        updateState(null); 
      }
      return hadiths;
    } catch (e, st) {
      _logger.e('Error loading hadiths', error: e, stackTrace: st);
      updateState(null); 
      rethrow;
    }
  }

  Future<dynamic> getJsonData() async {
    _logger.i('Fetching JSON data...');
    if (_jsonData == null) {
      _logger.d('JSON data not available. Loading hadiths to populate it...');
      await loadHadiths((hadiths) => AsyncValue.data(hadiths ?? []));
    }
    return _jsonData;
  }

  Future<void> updateJsonData(List<Hadith> hadiths, dataVersion) async {
    _logger.i('Updating JSON data with new hadiths...');
    try {
      final grouped = HadithGrouper().groupHadithsByStructure(hadiths);
      final version = dataVersion;
      _jsonData = {'version': version, 'chapters': grouped};
      await _jsonHandler.saveHadithJson(_jsonData);
      await _versionHandler.setLocalVersion(version);
      _logger.i('JSON data updated successfully.');
    } catch (e, st) {
      _logger.e('Error updating JSON data', error: e, stackTrace: st);
      rethrow;
    }
  }
}
