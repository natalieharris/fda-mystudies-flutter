import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/widget_util.dart';
import 'recorded_value.dart';

class ChartTile extends StatelessWidget {
  final String chartId;
  final String chartDisplayName;
  final List<RecordedValue> records;

  const ChartTile(this.chartId, this.chartDisplayName, this.records, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platformIsIos = (isPlatformIos(context));
    final isDarkModeEnabled =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    var scale = MediaQuery.of(context).textScaleFactor;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          decoration: BoxDecoration(
              color: platformIsIos
                  ? CupertinoTheme.of(context).barBackgroundColor
                  : Theme.of(context).bottomAppBarColor),
          padding: const EdgeInsets.all(8),
          child: Text(chartDisplayName, style: _titleStyle(context))),
      Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 30),
          height: 200,
          width: MediaQuery.of(context).size.width,
          child: charts.TimeSeriesChart(
            [
              charts.Series<RecordedValue, DateTime>(
                id: chartId,
                colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
                domainFn: (RecordedValue response, _) => response.recordedAt,
                measureFn: (RecordedValue response, _) =>
                    double.parse(response.value),
                data: records,
              )
            ],
            primaryMeasureAxis: charts.NumericAxisSpec(
                renderSpec: charts.GridlineRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                      fontSize: min(18, (10 * scale).ceil()),
                      color: (isDarkModeEnabled
                          ? charts.MaterialPalette.white
                          : charts.MaterialPalette.black)),
                ),
                tickProviderSpec: const charts.BasicNumericTickProviderSpec(
                    desiredTickCount: 6)),
            domainAxis: charts.DateTimeAxisSpec(
              renderSpec: charts.GridlineRendererSpec(
                labelStyle: charts.TextStyleSpec(
                    fontSize: min(18, (10 * scale).ceil()),
                    color: (isDarkModeEnabled
                        ? charts.MaterialPalette.white
                        : charts.MaterialPalette.black)),
              ),
              tickProviderSpec:
                  const charts.AutoDateTimeTickProviderSpec(includeTime: false),
              tickFormatterSpec: const charts.AutoDateTimeTickFormatterSpec(
                  year: null,
                  month: null,
                  day: charts.TimeFormatterSpec(
                    format: 'dd',
                    transitionFormat: 'dd MMM',
                  ),
                  hour: null,
                  minute: null),
            ),
            animate: true,
            defaultRenderer: charts.BarRendererConfig<DateTime>(),
            defaultInteractions: false,
            behaviors: [charts.SelectNearest(), charts.DomainHighlighter()],
          ))
    ]);
  }

  TextStyle? _titleStyle(BuildContext context) {
    if (isPlatformIos(context)) {
      return CupertinoTheme.of(context)
          .textTheme
          .textStyle
          .apply(fontSizeFactor: 0.9);
    }
    return Theme.of(context).textTheme.subtitle1;
  }
}
