import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../common/widget_util.dart';
import 'donut_chart.dart';

class AdherenceCompletionView extends StatelessWidget {
  final double studyCompletionPercent;
  final double activitiesCompletionPercent;

  const AdherenceCompletionView(
      {required this.studyCompletionPercent,
      required this.activitiesCompletionPercent,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platformIsIos = (isPlatformIos(context));
    return Container(
        height: 250,
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        decoration: BoxDecoration(
            color: platformIsIos
                ? CupertinoTheme.of(context).barBackgroundColor
                : Theme.of(context).bottomAppBarColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(children: [
              DonutChart(studyCompletionPercent),
              Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text('The study is $studyCompletionPercent% complete',
                      textAlign: TextAlign.center,
                      style: _statusStyle(context)))
            ])),
            VerticalDivider(
                width: 1,
                thickness: 1,
                color: (platformIsIos
                    ? CupertinoTheme.of(context).scaffoldBackgroundColor
                    : Theme.of(context).scaffoldBackgroundColor)),
            Expanded(
                child: Column(children: [
              DonutChart(activitiesCompletionPercent),
              Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                      'You completed $activitiesCompletionPercent% of activities so far',
                      textAlign: TextAlign.center,
                      style: _statusStyle(context)))
            ]))
          ],
        ));
  }

  TextStyle? _statusStyle(BuildContext context) {
    if (isPlatformIos(context)) {
      return CupertinoTheme.of(context)
          .textTheme
          .pickerTextStyle
          .apply(fontSizeFactor: 0.6);
    }
    return Theme.of(context).textTheme.headline6?.apply(fontSizeFactor: 0.7);
  }
}