import 'dart:io';

import 'package:fda_mystudies/config/config_mapping.dart';
import 'package:fda_mystudies/src/demo_config_services_view.dart';
import 'package:fda_mystudies_activity_ui_kit/fda_mystudies_activity_ui_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Environment extends StatefulWidget {
  const Environment({Key? key}) : super(key: key);

  @override
  _EnvironmentState createState() => _EnvironmentState();
}

class _EnvironmentState extends State<Environment> {
  String _selectedEnvironment = ConfigMapping.defaultEnvironment;

  @override
  Widget build(BuildContext context) {
    var environments = ConfigMapping.configMap.keys;
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
          navigationBar:
              const CupertinoNavigationBar(middle: Text('Environment')),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: ListView(
                  children: environments
                          .map((e) => CupertinoRadioListTile(
                                  e, '', e, _selectedEnvironment == e, true,
                                  onChanged: (value) {
                                setState(() {
                                  _selectedEnvironment = value;
                                });
                              }))
                          .toList()
                          .cast<Widget>() +
                      (_selectedEnvironment == ConfigMapping.demoEnv
                          ? [
                              const SizedBox(height: 48),
                              Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CupertinoButton.filled(
                                      child: const Text('Configure Demo',
                                          style: TextStyle(
                                              color: CupertinoColors.white)),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                            CupertinoPageRoute<void>(
                                                builder: (BuildContext
                                                        context) =>
                                                    const DemoConfigServicesView()));
                                      }))
                            ]
                          : []))));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Environment')),
        body: ListView(
            children: environments
                    .map((e) => RadioListTile(
                        title: Text(e),
                        value: e,
                        selected: e == _selectedEnvironment,
                        groupValue: _selectedEnvironment,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedEnvironment = value;
                            });
                          }
                        }))
                    .toList()
                    .cast<Widget>() +
                (_selectedEnvironment == ConfigMapping.demoEnv
                    ? [
                        const SizedBox(height: 48),
                        Padding(
                            padding: const EdgeInsets.all(24),
                            child: ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                        builder: (BuildContext context) =>
                                            const DemoConfigServicesView())),
                                child: const Text('Configure Demo')))
                      ]
                    : [])));
  }
}
