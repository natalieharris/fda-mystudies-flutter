import 'dart:developer' as developer;
import 'package:fda_mystudies_http_client/fda_mystudies_http_client.dart';
import 'package:fda_mystudies_http_client/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:fitbitter/fitbitter.dart';

import '../../config/app_config.dart';
import '../register_and_login/auth_utils.dart';
import '../screen/fitbit_screen.dart';

class FitbitScreenController extends StatefulWidget {
  const FitbitScreenController({Key? key}) : super(key: key);

  @override
  State<FitbitScreenController> createState() =>
      _FitbitScreenControllerState();
}

class _FitbitScreenControllerState extends State<FitbitScreenController> {
  var _userId = '';
  var _accessToken = '';
  var _refreshToken = '';
  var _lastSync = DateTime.parse('2024-04-22');
  final _config = AppConfig.shared.currentConfig;

  @override
  Widget build(BuildContext context) {
    return FitbitScreen(
        appName: _config.appName,
        orgName: _config.organization,
        connectFitbit: _connectFitbit);
  }

  void _connectFitbit() async {
    if (_accessToken == '') {
      // Fetch from secure store, if exists. 
      var credentials = await AuthUtils.fetchFitbitUserFromDB();
      if (credentials.length == 3){  // userId, accessToken, refreshToken 
        developer.log('FETCHED FITBIT CREDENTIALS FROM SECURE STORAGE');
        _userId = credentials[0];
        _accessToken = credentials[1];
        _refreshToken = credentials[2];
      }
    }
    // Check token validity & refresh if needed
    _refreshCredentials();
    
    if (_accessToken == '') {
      // Fetch new credentials if none exist. 
      var authenticationService = getIt<AuthenticationService>();
      authenticationService.fitbitSignIn().then((value) {
          _saveFitbitCredentials(value);
      });
    }
    _fetchData();
  }

  void _refreshCredentials() async {
    if (_accessToken == '') {
      developer.log('No Fitbit Credentials to refresh');
      return;
    }
    developer.log('Refreshing Fitbit Credentials');
    FitbitCredentials credentials = FitbitCredentials(userID: _userId, fitbitAccessToken: _accessToken, fitbitRefreshToken: _refreshToken);
    bool valid = await FitbitConnector.isTokenValid(fitbitCredentials: credentials);
    if (!valid) {
      FitbitConnector.refreshToken(
          clientID: _config.fitbitClientId,
          clientSecret: _config.fitbitClientSecret,
          fitbitCredentials: credentials,
      ).then((value) {
        _saveFitbitCredentials(value);
      });
    }
  }

  void _saveFitbitCredentials(FitbitCredentials? credentials) {
    if (credentials != null) {
      _userId = credentials.userID;
      _accessToken = credentials.fitbitAccessToken;
      _refreshToken = credentials.fitbitRefreshToken;
      AuthUtils.saveFitbitUserToDB(_accessToken, _refreshToken, _userId);
      developer.log('Fitbit Credentials saved');
    } else {
      developer.log('No FitBit Credentials recieved');
    }  
  }

  void _fetchData() {
    var date = DateTime.now();
    //TODO(): Add Intraday data
    var daysSinceSync = date.difference(_lastSync).inDays;
    developer.log('days since sync $daysSinceSync');
    if (daysSinceSync > 0) {
      var credentials = FitbitCredentials(userID: _userId,
                                          fitbitAccessToken: _accessToken,
                                          fitbitRefreshToken: _refreshToken);
      _fetchActivityData(credentials, daysSinceSync);
      _fetchActivityTimeseriesData(credentials);
      _fetchBreathingData(credentials);
      _fetchCardioData(credentials);
      _fetchHeartRateData(credentials);
      _fetchHeartRateVariabilityData(credentials);
      _fetchSPO2Data(credentials);
      _fetchSleepData(credentials);
      _fetchTemperatureData(credentials);
      _lastSync = date;
    }
  }

  Future<void> _fetchActivityData(FitbitCredentials credentials, daysSinceSync) async {
    for (int day in Iterable.generate(daysSinceSync)) {
      FitbitActivityDataManager fitbitActivityDataManager = FitbitActivityDataManager(
        clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
      FitbitActivityAPIURL fitbitActivityAPIURL = FitbitActivityAPIURL.day(
        date: _lastSync.add(Duration(days: day)),
        fitbitCredentials: credentials,
      );
      _fetchAndConvertData(fitbitActivityDataManager, fitbitActivityAPIURL);
    }
  }

  Future<void> _fetchActivityTimeseriesData(FitbitCredentials credentials) async {
    FitbitActivityTimeseriesDataManager fitbitActivityTSDataManager = FitbitActivityTimeseriesDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    for (Resource r in Resource.values) {
      FitbitActivityTimeseriesAPIURL fitbitActivityTSAPIURL = FitbitActivityTimeseriesAPIURL.dateRangeWithResource(
        startDate: _lastSync,
        endDate: DateTime.now(),
        fitbitCredentials: credentials,
        resource: r
      );
      _fetchAndConvertData(fitbitActivityTSDataManager, fitbitActivityTSAPIURL);
    }
  }

  Future<void> _fetchBreathingData(FitbitCredentials credentials) async {
    FitbitBreathingRateDataManager fitbitBRDataManager = FitbitBreathingRateDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitBreathingRateAPIURL fitbitBRAPIURL = FitbitBreathingRateAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitBRDataManager, fitbitBRAPIURL);
  }

  Future<void> _fetchCardioData(FitbitCredentials credentials) async {
    FitbitCardioScoreDataManager fitbitCSDataManager = FitbitCardioScoreDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitCardioScoreAPIURL fitbitCSAPIURL = FitbitCardioScoreAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitCSDataManager, fitbitCSAPIURL);
  }

  Future<void> _fetchHeartRateData(FitbitCredentials credentials) async {
    FitbitHeartDataManager fitbitHeartRateDataManager = FitbitHeartDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitHeartRateAPIURL fitbitHeartRateAPIURL = FitbitHeartRateAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitHeartRateDataManager, fitbitHeartRateAPIURL);
  }

  Future<void> _fetchHeartRateVariabilityData(FitbitCredentials credentials) async {
    FitbitHeartRateVariabilityDataManager fitbitHRVDataManager = FitbitHeartRateVariabilityDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitHeartRateVariabilityAPIURL fitbitHRVAPIURL = FitbitHeartRateVariabilityAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitHRVDataManager, fitbitHRVAPIURL);
  }

  Future<void> _fetchSleepData(FitbitCredentials credentials) async {
    FitbitSleepDataManager fitbitSleepDataManager = FitbitSleepDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitSleepAPIURL fitbitSleepAPIURL = FitbitSleepAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitSleepDataManager, fitbitSleepAPIURL);
  }

  Future<void> _fetchSPO2Data(FitbitCredentials credentials) async {
    FitbitSpO2DataManager fitbitSpo2DataManager = FitbitSpO2DataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitSpO2APIURL fitbitSpo2APIURL = FitbitSpO2APIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitSpo2DataManager, fitbitSpo2APIURL);
  }
  
  Future<void> _fetchTemperatureData(FitbitCredentials credentials) async {
    FitbitTemperatureSkinDataManager fitbitTempDataManager = FitbitTemperatureSkinDataManager(
      clientID: _config.fitbitClientId, clientSecret: _config.fitbitClientSecret);
    FitbitTemperatureSkinAPIURL fitbitTempAPIURL = FitbitTemperatureSkinAPIURL.dateRange(
      startDate: _lastSync, endDate: DateTime.now(),
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitTempDataManager, fitbitTempAPIURL);
  }

  void _fetchAndConvertData(FitbitDataManager dataManager, FitbitAPIURL apiurl) {
    //TODO(): Save data to db
    dataManager.fetch(apiurl).then((value) {
      // Save and display data
      for (final i in value){
        developer.log(i.toJson().toString());
      }
    }).onError((error, stackTrace) {
      developer.log(error.toString());
      developer.log(stackTrace.toString());
    });
  }
  
}
