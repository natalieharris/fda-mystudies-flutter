import 'package:fda_mystudies_spec/common_specs/common_error_response.pb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'common_error_widget.dart';

class FutureLoadingPage extends StatelessWidget {
  final String scaffoldTitle;
  final Future<Object>? future;
  final Widget Function(BuildContext, AsyncSnapshot<Object>) builder;
  final bool wrapInScaffold;

  const FutureLoadingPage(this.scaffoldTitle, this.future, this.builder,
      {this.wrapInScaffold = true, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return _wrapWidgetInScaffold(
          context,
          SafeArea(
              child: FutureBuilder<Object>(
                  future: future,
                  builder: (BuildContext buildContext,
                      AsyncSnapshot<Object> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const Center(
                            child: CupertinoActivityIndicator());
                      default:
                        if (snapshot.hasError) {
                          return CommonErrorWidget(snapshot.error.toString());
                        } else if (snapshot.data is CommonErrorResponse) {
                          var errorResponse =
                              (snapshot.data as CommonErrorResponse)
                                  .errorDescription;
                          return CommonErrorWidget(errorResponse);
                        } else {
                          return builder(buildContext, snapshot);
                        }
                    }
                  })),
          wrapInScaffold);
    }
    return _wrapWidgetInScaffold(
        context,
        FutureBuilder<Object>(
            future: future,
            builder:
                (BuildContext buildContext, AsyncSnapshot<Object> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const Center(child: CircularProgressIndicator());
                default:
                  if (snapshot.hasError) {
                    return CommonErrorWidget(snapshot.error.toString());
                  } else if (snapshot.data is CommonErrorResponse) {
                    var errorResponse =
                        (snapshot.data as CommonErrorResponse).errorDescription;
                    return CommonErrorWidget(errorResponse);
                  } else {
                    return builder(buildContext, snapshot);
                  }
              }
            }),
        wrapInScaffold);
  }

  Widget _wrapWidgetInScaffold(
      BuildContext context, Widget widget, bool shouldWrap) {
    if (shouldWrap) {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(middle: Text(scaffoldTitle)),
            child: widget);
      }
      return Scaffold(appBar: AppBar(title: Text(scaffoldTitle)), body: widget);
    }
    return widget;
  }
}
