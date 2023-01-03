import 'package:fda_mystudies/src/route/route_name.dart';
import 'package:fda_mystudies_http_client/authentication_service.dart';
import 'package:fda_mystudies_http_client/fda_mystudies_http_client.dart';
import 'package:fda_mystudies_spec/authentication_service/refresh_token.pbserver.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../user/user_data.dart';

enum AccountStatus {
  verified, // 0
  pending, // 1
  accountLocked, // 2
  tempPassword, // 3
  unknown // 4
}

extension AccountStatusExtension on AccountStatus {
  void nextScreen(BuildContext context) {
    switch (this) {
      case AccountStatus.verified:
        _verifiedScreen(context);
        break;
      case AccountStatus.pending:
        context.pushNamed(RouteName.verificationStep);
        break;
      case AccountStatus.accountLocked:
      // Follows same procedure as tempPassword
      // [here](https://github.com/GoogleCloudPlatform/fda-mystudies/blob/master/iOS/MyStudies/MyStudies/Controllers/LoginRegisterUI/LoginUI/SignInViewController.swift#L198)
      case AccountStatus.tempPassword:
        context.pushNamed(RouteName.updateTemporaryPassword);
        break;
      case AccountStatus.unknown:
        context.pushNamed(RouteName.unknownAccountStatus);
        break;
    }
  }

  void _verifiedScreen(BuildContext context) {
    var authenticationService = getIt<AuthenticationService>();
    authenticationService
        .grantVerifiedUser(UserData.shared.userId, UserData.shared.code)
        .then((value) {
      if (value is RefreshTokenResponse) {
        switch (curConfig.appType) {
          case AppType.gateway:
            context.goNamed(RouteName.gatewayHome);
            break;
          case AppType.standalone:
            UserData.shared.curStudyId = curConfig.studyId;
            context.goNamed(RouteName.standaloneHome);
            break;
        }
      } else {
        context.goNamed(RouteName.unknownAccountStatus);
      }
    });
  }
}
