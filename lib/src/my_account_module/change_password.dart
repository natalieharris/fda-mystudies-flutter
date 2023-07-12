import 'package:fda_mystudies_http_client/authentication_service.dart';
import 'package:fda_mystudies_http_client/fda_mystudies_http_client.dart';
import 'package:flutter/material.dart';

import '../common/home_scaffold.dart';
import '../common/string_extension.dart';
import '../common/widget_util.dart';
import '../user/user_data.dart';

class ChangePassword extends StatefulWidget {
  final bool isChangingTemporaryPassword;
  const ChangePassword({this.isChangingTemporaryPassword = false, Key? key})
      : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  var _currentPassword = '';
  var _newPassword = '';
  var _confirmNewPassword = '';
  var _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var currentPasswordPlaceholder =
        '${widget.isChangingTemporaryPassword ? 'Temporary' : 'Current'} Password';
    const newPasswordPlaceholder = 'New Password';
    const confirmNewPasswordPlaceholder = 'Confirm New Password';
    return Stack(children: <Widget>[
      GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: HomeScaffold(
              title: 'Change Password',
              showDrawer: false,
              bottomNavigationBar: BottomAppBar(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                                onPressed: _changePassword(),
                                style: Theme.of(context).textButtonTheme.style,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator())
                                    : const Text('Submit'))
                          ]))),
              child: SafeArea(
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                TextField(
                    controller: _currentPasswordController,
                    autocorrect: false,
                    onChanged: (value) {
                      setState(() {
                        _currentPassword = value;
                      });
                    },
                    readOnly: _isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: currentPasswordPlaceholder)),
                const SizedBox(height: 16),
                TextField(
                    controller: _newPasswordController,
                    autocorrect: false,
                    onChanged: (value) {
                      setState(() {
                        _newPassword = value;
                      });
                    },
                    readOnly: _isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: newPasswordPlaceholder)),
                const SizedBox(height: 16),
                TextField(
                    controller: _confirmNewPasswordController,
                    autocorrect: false,
                    onChanged: (value) {
                      setState(() {
                        _confirmNewPassword = value;
                      });
                    },
                    readOnly: _isLoading,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: confirmNewPasswordPlaceholder)),
              ]))))
    ]);
  }

  void Function()? _changePassword() {
    return _isLoading
        ? null
        : () {
            var alertMessage = _alertMessage();
            if (alertMessage != null) {
              showUserMessage(context, alertMessage);
              return;
            }
            setState(() {
              _isLoading = true;
            });
            var authenticationService = getIt<AuthenticationService>();
            authenticationService
                .changePassword(UserData.shared.authToken,
                    UserData.shared.userId, _currentPassword, _newPassword)
                .then((value) {
              const successfulResponse = 'Password Successfully changed!';
              var response = processResponse(value, successfulResponse);
              setState(() {
                _isLoading = false;
                if (response == successfulResponse) {
                  _currentPassword = '';
                  _newPassword = '';
                  _confirmNewPassword = '';
                  _currentPasswordController.text = '';
                  _newPasswordController.text = '';
                  _confirmNewPasswordController.text = '';
                }
              });
              if (response == successfulResponse) {
                Navigator.of(context).pop();
              }
              showUserMessage(context, response);
            });
          };
  }

  String? _alertMessage() {
    if (_currentPassword.isEmpty &&
        _newPassword.isEmpty &&
        _confirmNewPassword.isEmpty) {
      return 'Please fill in all the fields';
    } else if (_currentPassword.isEmpty) {
      return 'Please enter your ${widget.isChangingTemporaryPassword ? 'temporary' : 'current'} password.';
    } else if (_newPassword.isEmpty) {
      return 'Please enter your new password.';
    } else if (_confirmNewPassword.isEmpty) {
      return 'Please confirm your new password';
    } else if (!_newPassword.isAValidPassword()) {
      return 'Your password must be at least 8 characters long and contain lower case and upper case letters, and numeric and special characters.';
    } else if (_newPassword != _confirmNewPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
