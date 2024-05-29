import 'dart:developer' as developer;
import 'package:fda_mystudies_http_client/fda_mystudies_http_client.dart';
import 'package:fda_mystudies_http_client/authentication_service.dart';
import 'package:fda_mystudies_http_client/response_datastore_service.dart';
import 'package:fda_mystudies_spec/common_specs/common_error_response.pb.dart';
import 'package:fda_mystudies_spec/response_datastore_service/process_response.pb.dart';
import 'package:flutter/material.dart';
import 'package:fitbitter/fitbitter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../register_and_login/auth_utils.dart';
import '../route/route_name.dart';
import '../screen/fitbit_screen.dart';
import '../user/user_data.dart';

class FitbitScreenController extends StatefulWidget {
  const FitbitScreenController({Key? key}) : super(key: key);

  @override
  State<FitbitScreenController> createState() => _FitbitScreenControllerState();
}

class _FitbitScreenControllerState extends State<FitbitScreenController> {
  var _userId = '';
  var _accessToken = '';
  var _refreshToken = '';
  final _config = AppConfig.shared.currentConfig;

  @override
  Widget build(BuildContext context) {
    return FitbitScreen(
        appName: _config.appName,
        orgName: _config.organization,
        connectFitbit: _connectFitbit,
        continueHome: _continueToHome);
  }

  void _connectFitbit() async {
    if (_accessToken == '') {
      // Fetch from secure store, if exists.
      var credentials = await AuthUtils.fetchFitbitUserFromDB();
      if (credentials.length == 3) {
        // userId, accessToken, refreshToken
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

  void _continueToHome() {
    context.goNamed(RouteName.studyHome);
  }

  void _refreshCredentials() async {
    if (_accessToken == '') {
      developer.log('No Fitbit Credentials to refresh');
      return;
    }
    developer.log('Refreshing Fitbit Credentials');
    FitbitCredentials credentials = FitbitCredentials(
        userID: _userId,
        fitbitAccessToken: _accessToken,
        fitbitRefreshToken: _refreshToken);
    //TODO(): Fix bug in fitbitter isTokenValid fn.
    bool valid = false;
    //    await FitbitConnector.isTokenValid(fitbitCredentials: credentials);
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
      developer.log('No FitBit Credentials received');
    }
  }

  void _fetchData() {
    var date = DateTime.now();
    // Collect data from the last week
    final end = date.subtract(const Duration(days: 1));
    final start = date.subtract(const Duration(days: 8));
    //TODO(): Add Intraday data

    developer.log('Syncing data for $start - $end');
    var credentials = FitbitCredentials(
        userID: _userId,
        fitbitAccessToken: _accessToken,
        fitbitRefreshToken: _refreshToken);
    _fetchActivityData(credentials, start, end);
    _fetchActivityTimeseriesData(credentials, start, end);
    _fetchBreathingData(credentials, start, end);
    _fetchCardioData(credentials, start, end);
    _fetchHeartRateData(credentials, start, end);
    _fetchHeartRateVariabilityData(credentials, start, end);
    _fetchSPO2Data(credentials, start, end);
    _fetchSleepData(credentials, start, end);
    _fetchTemperatureData(credentials, start, end);
  }

  Future<void> _fetchActivityData(FitbitCredentials credentials,
      DateTime startDate, DateTime endDate) async {
    for (int day in Iterable.generate(startDate.difference(endDate).inDays)) {
      FitbitActivityDataManager fitbitActivityDataManager =
          FitbitActivityDataManager(
              clientID: _config.fitbitClientId,
              clientSecret: _config.fitbitClientSecret);
      FitbitActivityAPIURL fitbitActivityAPIURL = FitbitActivityAPIURL.day(
        date: startDate.add(Duration(days: day)),
        fitbitCredentials: credentials,
      );
      _fetchAndConvertData(fitbitActivityDataManager, fitbitActivityAPIURL,
          'Activity', startDate);
    }
  }

  Future<void> _fetchActivityTimeseriesData(
      FitbitCredentials credentials, start, end) async {
    FitbitActivityTimeseriesDataManager fitbitActivityTSDataManager =
        FitbitActivityTimeseriesDataManager(
            clientID: _config.fitbitClientId,
            clientSecret: _config.fitbitClientSecret);
    for (Resource r in Resource.values) {
      FitbitActivityTimeseriesAPIURL fitbitActivityTSAPIURL =
          FitbitActivityTimeseriesAPIURL.dateRangeWithResource(
              startDate: start,
              endDate: end,
              fitbitCredentials: credentials,
              resource: r);
      _fetchAndConvertData(fitbitActivityTSDataManager, fitbitActivityTSAPIURL,
          'ActivityTimeseries-${r.toString()}', start);
    }
  }

  Future<void> _fetchBreathingData(
      FitbitCredentials credentials, start, end) async {
    FitbitBreathingRateDataManager fitbitBRDataManager =
        FitbitBreathingRateDataManager(
            clientID: _config.fitbitClientId,
            clientSecret: _config.fitbitClientSecret);
    FitbitBreathingRateAPIURL fitbitBRAPIURL =
        FitbitBreathingRateAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitBRDataManager, fitbitBRAPIURL, 'BR', start);
  }

  Future<void> _fetchCardioData(
      FitbitCredentials credentials, start, end) async {
    FitbitCardioScoreDataManager fitbitCSDataManager =
        FitbitCardioScoreDataManager(
            clientID: _config.fitbitClientId,
            clientSecret: _config.fitbitClientSecret);
    FitbitCardioScoreAPIURL fitbitCSAPIURL = FitbitCardioScoreAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitCSDataManager, fitbitCSAPIURL, 'Cardio', start);
  }

  Future<void> _fetchHeartRateData(
      FitbitCredentials credentials, start, end) async {
    FitbitHeartDataManager fitbitHeartRateDataManager = FitbitHeartDataManager(
        clientID: _config.fitbitClientId,
        clientSecret: _config.fitbitClientSecret);
    FitbitHeartRateAPIURL fitbitHeartRateAPIURL =
        FitbitHeartRateAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(
        fitbitHeartRateDataManager, fitbitHeartRateAPIURL, 'HeartRate', start);
  }

  Future<void> _fetchHeartRateVariabilityData(
      FitbitCredentials credentials, start, end) async {
    FitbitHeartRateVariabilityDataManager fitbitHRVDataManager =
        FitbitHeartRateVariabilityDataManager(
            clientID: _config.fitbitClientId,
            clientSecret: _config.fitbitClientSecret);
    FitbitHeartRateVariabilityAPIURL fitbitHRVAPIURL =
        FitbitHeartRateVariabilityAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(fitbitHRVDataManager, fitbitHRVAPIURL, 'HRV', start);
  }

  Future<void> _fetchSleepData(
      FitbitCredentials credentials, start, end) async {
    FitbitSleepDataManager fitbitSleepDataManager = FitbitSleepDataManager(
        clientID: _config.fitbitClientId,
        clientSecret: _config.fitbitClientSecret);
    FitbitSleepAPIURL fitbitSleepAPIURL = FitbitSleepAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(
        fitbitSleepDataManager, fitbitSleepAPIURL, 'Sleep', start);
  }

  Future<void> _fetchSPO2Data(FitbitCredentials credentials, start, end) async {
    FitbitSpO2DataManager fitbitSpo2DataManager = FitbitSpO2DataManager(
        clientID: _config.fitbitClientId,
        clientSecret: _config.fitbitClientSecret);
    FitbitSpO2APIURL fitbitSpo2APIURL = FitbitSpO2APIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(
        fitbitSpo2DataManager, fitbitSpo2APIURL, 'SpO2', start);
  }

  Future<void> _fetchTemperatureData(
      FitbitCredentials credentials, start, end) async {
    FitbitTemperatureSkinDataManager fitbitTempDataManager =
        FitbitTemperatureSkinDataManager(
            clientID: _config.fitbitClientId,
            clientSecret: _config.fitbitClientSecret);
    FitbitTemperatureSkinAPIURL fitbitTempAPIURL =
        FitbitTemperatureSkinAPIURL.dateRange(
      startDate: start,
      endDate: end,
      fitbitCredentials: credentials,
    );
    _fetchAndConvertData(
        fitbitTempDataManager, fitbitTempAPIURL, 'Temp', start);
  }

  void _fetchAndConvertData(FitbitDataManager dataManager, FitbitAPIURL apiurl,
      String type, startTime) {
    //TODO(): Save data to db
    dataManager.fetch(apiurl).then((value) {
      // Save and display data
      for (final i in value) {
        developer.log(i.toString());
        _saveFitbitData(i.toJson().toString(), type, startTime);
      }
    }).onError((error, stackTrace) {
      developer.log(error.toString());
      developer.log(stackTrace.toString());
    });
  }

  void _saveFitbitData(String data, String type, startTime) {
    var responseDatastoreService = getIt<ResponseDatastoreService>();
    final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final start = dateFormat.format(startTime).toString();
    final end =
        dateFormat.format(startTime.add(const Duration(days: 1))).toString();
    final dataType = "FitbitData-$type";
    var stepResult = ActivityResponse_Data_StepResult()..listValues.add(data);
    var respo = ActivityResponse()
      ..type = dataType
      ..tokenIdentifier = UserData.shared.currentStudyTokenIdentifier
      ..participantId = UserData.shared.curParticipantId
      ..metadata = (ActivityResponse_Metadata()
        ..name = UserData.shared.curStudyName
        ..studyId = UserData.shared.curStudyId
        ..activityRunId = ''
        ..version = UserData.shared.activityVersion
        ..activityId = UserData.shared.activityId
        ..studyVersion = UserData.shared.curStudyVersion)
      ..applicationId = AppConfig.shared.currentConfig.appId
      ..data = (ActivityResponse_Data()
        ..resultType = dataType
        ..startTime = start
        ..endTime = end
        ..results.add(stepResult))
      ..siteId = UserData.shared.curSiteId;
    developer.log(respo.toString());

    responseDatastoreService
        .processFitbitData(UserData.shared.userId, respo)
        .then((value) {
      if (value is CommonErrorResponse) {
        developer.log('RESPONSE PROCESSES ERROR: ${value.errorDescription}');
        return null;
      } else {
        developer.log('RESPONSE PROCESSES: $value');
        return value;
      }
    });
  }
}
