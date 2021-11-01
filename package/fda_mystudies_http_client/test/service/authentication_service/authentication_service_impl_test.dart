import 'package:fda_mystudies_http_client/injection/injection.dart';
import 'package:fda_mystudies_http_client/mock/demo_config.dart';
import 'package:fda_mystudies_http_client/service/authentication_service/authentication_service.dart';
import 'package:fda_mystudies_spec/authentication_service/change_password.pb.dart';
import 'package:fda_mystudies_spec/authentication_service/logout.pb.dart';
import 'package:fda_mystudies_spec/authentication_service/refresh_token.pbserver.dart';
import 'package:fda_mystudies_spec/common_specs/common_error_response.pb.dart';
import 'package:fda_mystudies_spec/common_specs/common_response.pbserver.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../common/common_test_object.dart';

void main() {
  AuthenticationService? authenticationService;
  final config = DemoConfig();

  setUpAll(() {
    configureDependencies(config);
    authenticationService = getIt<AuthenticationService>();
  });
  group('change password tests', () {
    test('test default scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.change_password': 'default'
      };
      var response = await authenticationService!
          .changePassword('userId', 'current', 'new');
      expect(
          response,
          ChangePasswordResponse.create()
            ..status = 200
            ..code = '200'
            ..message = 'success');
    });

    test('test invalid_json scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.change_password': 'common.invalid_json'
      };
      var response = await authenticationService!
          .changePassword('userId', 'current', 'new');
      expect(
          response,
          CommonErrorResponse.create()
            ..errorDescription =
                'Invalid json received while making the change_password call!');
    });

    test('test common error scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.change_password': 'common.common_error'
      };
      var response = await authenticationService!
          .changePassword('userId', 'current', 'new');
      expect(response, CommonTestObject.forbiddenError);
    });
  });

  group('grant verified user tests', () {
    test('test default scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.grant_verified_user': 'default'
      };
      var response =
          await authenticationService!.grantVerifiedUser('userId', 'code');
      expect(
          response,
          RefreshTokenResponse.create()
            ..accessToken = 'test_access_token'
            ..expiresIn = 3600
            ..idToken = 'test_id_token'
            ..refreshToken = 'test_refresh_token'
            ..scope = 'offline'
            ..tokenType = 'basic');
    });
  });

  group('refresh token tests', () {
    test('test default scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.grant_verified_user': 'default'
      };
      var response = await authenticationService!.refreshToken('userId');
      expect(
          response,
          RefreshTokenResponse.create()
            ..accessToken = 'test_access_token'
            ..expiresIn = 3600
            ..idToken = 'test_id_token'
            ..refreshToken = 'test_refresh_token'
            ..scope = 'offline'
            ..tokenType = 'basic');
    });
  });

  group('reset password tests', () {
    test('test default scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.reset_password': 'default'
      };
      var response =
          await authenticationService!.resetPassword('tester@domain.com');
      expect(
          response,
          CommonResponse.create()
            ..code = 200
            ..message = 'success');
    });
  });

  group('logout tests', () {
    test('test default scenario', () async {
      config.serviceMethodScenarioMap = {
        'authentication_service.logout': 'default'
      };
      var response = await authenticationService!.logout('userId', 'authToken');
      expect(
          response,
          LogoutResponse.create()
            ..userId = 'userId'
            ..tempRegId = 'tempRegId'
            ..status = 200);
    });
  });

  group('sign-in uri tests', () {
    test('test default scenario', () {
      var signInUri = authenticationService!.getSignInPageURI();

      expect(signInUri.authority, config.baseParticipantUrl);
      expect(signInUri.path, '/oauth2/auth');
    });
  });
}