import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:fda_mystudies_spec/response_datastore_service/process_response.pb.dart';
import 'package:fda_mystudies_spec/study_datastore_service/activity_step.pb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../activity_response_processor.dart';
import '../activity_builder_impl.dart';
import 'unimplemented_template.dart';

class QuestionnaireTemplate extends StatelessWidget {
  static var dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final Map<String, ActivityResponse_Data_StepResult> _answers = {};

  final ActivityStep step;
  final bool allowExit;
  final String title;
  final Map<String, Widget> widgetMap;
  final List<Widget> children;
  final dynamic selectedValue;
  final String startTime;

  const QuestionnaireTemplate(this.step, this.allowExit, this.title,
      this.widgetMap, this.children, this.startTime,
      {this.selectedValue, Key? key})
      : super(key: key);

  Widget _findNextScreen() {
    if (step.destinations.isEmpty) {
      return widgetMap[''] ??
          UnimplementedTemplate(step.destinations.first.destination);
    } else if (step.destinations.length == 1) {
      return widgetMap[step.destinations.first.destination] ??
          UnimplementedTemplate(step.destinations.first.destination);
    }
    // TODO(cg2092): Implement branching
    return widgetMap[step.destinations.first.destination] ??
        UnimplementedTemplate(step.destinations.first.destination);
  }

  void _navigateToNextScreen(BuildContext context, bool skipped) {
    if (!skipped) {
      _saveTemporaryResult()
          .then((value) => developer.log('TEMPORARY RESULT SAVED'));
    } else {
      _discardTemporaryResult()
          .then((value) => developer.log('TEMPORARY RESULT DISCARDED'));
    }
    var nextScreen = _findNextScreen();
    if (step.type == 'question') {
      var stepResult = _createStepResult(skipped);
      _answers[step.key] = stepResult;
    }
    if (nextScreen is ActivityResponseProcessor) {
      List<ActivityResponse_Data_StepResult> stepResultList = [];
      for (String key in ActivityBuilderImpl.stepKeys) {
        if (_answers.containsKey(key)) {
          stepResultList.add(_answers[key]!);
        }
      }
      _savePastResult()
          .then((value) => nextScreen.processResponses(stepResultList));
    }
    if (Platform.isIOS) {
      Navigator.of(context).push(CupertinoPageRoute<void>(
          builder: (BuildContext context) => nextScreen));
    } else if (Platform.isAndroid) {
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
          builder: (BuildContext context) => nextScreen));
    }
  }

  static String _generateStepKey(bool temporary, String stepKey) {
    return ActivityBuilderImpl.prefixUniqueActivityStepId +
        (temporary ? 'temp' : '') +
        stepKey;
  }

  Future<void> _saveTemporaryResult() {
    var securedStorage = const FlutterSecureStorage();
    var tempKey = _generateStepKey(true, step.key);
    return securedStorage.write(
        key: tempKey,
        value: jsonEncode(_createStepResult(false).toProto3Json()));
  }

  Future<void> _discardTemporaryResult() {
    var securedStorage = const FlutterSecureStorage();
    var tempKey = _generateStepKey(true, step.key);
    return securedStorage.delete(key: tempKey);
  }

  Future<void> _discardAllTemporaryResults() {
    var securedStorage = const FlutterSecureStorage();
    return Future.wait(ActivityBuilderImpl.stepKeys.map((curStepKey) {
      var tempKey = _generateStepKey(true, curStepKey);
      return securedStorage.delete(key: tempKey);
    })).then((value) => developer.log('DISCARDED'));
  }

  Future<void> _savePastResult() {
    var securedStorage = const FlutterSecureStorage();
    return Future.wait(ActivityBuilderImpl.stepKeys.map((curStepKey) {
      var tempKey = _generateStepKey(true, curStepKey);
      return securedStorage.containsKey(key: tempKey).then((hasTemporaryValue) {
        if (hasTemporaryValue) {
          var permanentKey = _generateStepKey(false, curStepKey);
          return securedStorage.read(key: tempKey).then((tempValue) =>
              securedStorage.write(key: permanentKey, value: tempValue));
        }
      });
    })).then((value) => developer.log('SAVED'));
  }

  static Future<dynamic> readSavedResult(String curKey) {
    var securedStorage = const FlutterSecureStorage();
    String tempKey = _generateStepKey(true, curKey);
    return securedStorage.containsKey(key: tempKey).then((containsKey) {
      if (containsKey) {
        return securedStorage
            .read(key: tempKey)
            .then((jsonStr) => _valueFromStepResult(jsonStr));
      }
      String permKey = _generateStepKey(false, curKey);
      return securedStorage
          .read(key: permKey)
          .then((jsonStr) => _valueFromStepResult(jsonStr));
    });
  }

  static String currentTimeToString() {
    var currentTime = DateTime.now();
    return '${dateFormat.format(currentTime)}.${currentTime.millisecond}';
  }

  static dynamic _valueFromStepResult(String? jsonStr) {
    if (jsonStr != null) {
      var stepResult = ActivityResponse_Data_StepResult.create()
        ..mergeFromProto3Json(jsonDecode(jsonStr));
      if (stepResult.hasIntValue()) {
        return stepResult.intValue;
      } else if (stepResult.hasDoubleValue()) {
        return stepResult.doubleValue;
      } else if (stepResult.hasBoolValue()) {
        return stepResult.boolValue;
      } else if (stepResult.hasStringValue()) {
        return stepResult.stringValue;
      } else if (stepResult.listValues.isNotEmpty) {
        return stepResult.listValues;
      }
    }
    return null;
  }

  ActivityResponse_Data_StepResult _createStepResult(bool skipped) {
    var stepResult = ActivityResponse_Data_StepResult()
      ..key = step.key
      ..skipped = skipped
      ..resultType = step.resultType
      ..startTime = startTime
      ..endTime = currentTimeToString();
    if (!skipped) {
      if (selectedValue is int) {
        stepResult.intValue = selectedValue;
      } else if (selectedValue is double) {
        stepResult.doubleValue = selectedValue;
      } else if (selectedValue is bool) {
        stepResult.boolValue = selectedValue;
      } else if (selectedValue is String) {
        stepResult.stringValue = selectedValue;
      } else if (selectedValue is List<String>) {
        stepResult.listValues.addAll(selectedValue);
      }
    }
    return stepResult;
  }

  @override
  Widget build(BuildContext context) {
    var stepTitle = step.title;
    var subTitle = step.text;
    if (Platform.isIOS) {
      var titleStyle =
          CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle;
      var subTitleStyle = CupertinoTheme.of(context).textTheme.textStyle;
      return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(children: [
            CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                    middle: Text(title,
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey)),
                    trailing: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          showCupertinoModalPopup<void>(
                            context: context,
                            builder: (BuildContext context) =>
                                CupertinoActionSheet(
                              actions: <CupertinoActionSheetAction>[
                                CupertinoActionSheetAction(
                                  child: const Text('Save for Later'),
                                  onPressed: () {
                                    Navigator.of(context).popUntil(
                                        ModalRoute.withName(
                                            ActivityBuilderImpl.exitRoute));
                                  },
                                ),
                                CupertinoActionSheetAction(
                                  child: const Text('Discard Results'),
                                  isDestructiveAction: true,
                                  onPressed: () {
                                    _discardAllTemporaryResults();
                                    Navigator.of(context).popUntil(
                                        ModalRoute.withName(
                                            ActivityBuilderImpl.exitRoute));
                                  },
                                )
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  isDefaultAction: true,
                                  child: const Text('Cancel')),
                            ),
                          );
                        },
                        child: allowExit
                            ? const Icon(Icons.exit_to_app,
                                color: CupertinoColors.destructiveRed)
                            : const SizedBox(width: 0))),
                child: SafeArea(
                  bottom: false,
                  maintainBottomViewPadding: true,
                  child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                            Text(stepTitle, style: titleStyle),
                            SizedBox(height: subTitle.isEmpty ? 0 : 12),
                          ] +
                          (step.type == 'instruction'
                              ? []
                              : [
                                  Text(subTitle, style: subTitleStyle),
                                  SizedBox(height: subTitle.isEmpty ? 12 : 36)
                                ]) +
                          children +
                          [
                            // This sized box is to add padding to the bottom of
                            // the scaffold view to allow it to scroll over the
                            // view that holds the NEXT and SKIP buttons i.e. BOTTOM_VIEW.
                            // We are using bottom viewInset to detect if keyboard is
                            // showing. If keyboard is showing remove the extra padding
                            // meant for scrolling over the BOTTOM_VIEW.
                            //
                            // 20 - Default padding so that widgets from this component
                            //      doesn't stick to the BOTTOM_VIEW.
                            // 142 + 40 x textScaleFactor - This Padding is to match the
                            //      height of the BOTTOM_VIEW. Hacky solution, but it works
                            //      at all textScaleFactors.
                            SizedBox(
                                height: 20 +
                                    (MediaQuery.of(context).viewInsets.bottom ==
                                            0
                                        ? 142 +
                                            40 *
                                                MediaQuery.of(context)
                                                    .textScaleFactor
                                        : 0))
                          ]),
                )),
            Positioned(
                bottom: 0,
                width: MediaQuery.of(context).size.width,
                child: Container(
                    decoration: BoxDecoration(
                        color: CupertinoTheme.of(context).barBackgroundColor),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                  CupertinoButton.filled(
                                      child: const Text('NEXT',
                                          style: TextStyle(
                                              color: CupertinoColors.white)),
                                      onPressed: selectedValue == null &&
                                              step.type == 'question'
                                          ? null
                                          : () => _navigateToNextScreen(
                                              context, false))
                                ].cast<Widget>() +
                                (step.skippable
                                    ? [
                                        const SizedBox(height: 20),
                                        Container(
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: CupertinoColors
                                                        .activeBlue),
                                                borderRadius:
                                                    const BorderRadius.all(
                                                        Radius.circular(8.0))),
                                            child: CupertinoButton(
                                                child: const Text('SKIP',
                                                    style: TextStyle(
                                                        color: CupertinoColors
                                                            .activeBlue)),
                                                onPressed: () =>
                                                    _navigateToNextScreen(
                                                        context, true)))
                                      ]
                                    : [])))))
          ]));
    }
    return GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(title),
                actions: allowExit
                    ? [
                        TextButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext buildContext) {
                                    return AlertDialog(
                                      content: const Text(
                                          'Your responses are stored on the app if you `Save for Later` (unless you sign out) so you can resume and complete the activity before it expires.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).popUntil(
                                                  ModalRoute.withName(
                                                      ActivityBuilderImpl
                                                          .exitRoute));
                                            },
                                            child:
                                                const Text('Save for Later')),
                                        TextButton(
                                            onPressed: () {
                                              _discardAllTemporaryResults();
                                              Navigator.of(context).popUntil(
                                                  ModalRoute.withName(
                                                      ActivityBuilderImpl
                                                          .exitRoute));
                                            },
                                            child: const Text('Discard Results',
                                                style: TextStyle(
                                                    color: Colors.red))),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Cancel'))
                                      ],
                                    );
                                  });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              primary: Colors.red,
                            ),
                            child: const Icon(Icons.exit_to_app))
                      ]
                    : [],
                backgroundColor: Theme.of(context).colorScheme.surface),
            body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                      Text(stepTitle,
                          style: Theme.of(context).textTheme.headline4),
                      SizedBox(height: subTitle.isEmpty ? 0 : 12),
                    ] +
                    (step.type == 'instruction'
                        ? []
                        : [
                            Text(subTitle,
                                style: Theme.of(context).textTheme.headline6),
                            const SizedBox(height: 24)
                          ]) +
                    children),
            bottomNavigationBar: BottomAppBar(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: (step.skippable
                                ? [
                                    OutlinedButton(
                                        onPressed: () => _navigateToNextScreen(
                                            context, true),
                                        child: const Text('SKIP'),
                                        style: Theme.of(context)
                                            .textButtonTheme
                                            .style)
                                  ].cast<Widget>()
                                : [].cast<Widget>()) +
                            [
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: selectedValue == null &&
                                        step.type == 'question'
                                    ? null
                                    : () =>
                                        _navigateToNextScreen(context, false),
                                child: const Text('NEXT'),
                              )
                            ])))));
  }
}
