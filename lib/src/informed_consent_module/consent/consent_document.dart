import 'dart:math';

import 'package:fda_mystudies_design_system/block/page_html_text_block.dart';
import 'package:fda_mystudies_design_system/block/primary_button_block.dart';
import 'package:fda_mystudies_design_system/block/text_button_block.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../provider/eligibility_consent_provider.dart';
import '../../route/route_name.dart';

class ConsentDocument extends StatelessWidget {
  const ConsentDocument({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var scaleFactor = MediaQuery.of(context).textScaleFactor;
    double bottomPadding = max(150, 90 * scaleFactor);
    final visualScreens =
        Provider.of<EligibilityConsentProvider>(context, listen: false)
            .consent
            .visualScreens;
    var contentFromVisualScreens = '''
      <div>
        <h1>Review</h1>
        <p>Review the form below, and tap agree if you are ready to continue</p>
      </div>
      ${visualScreens.map((e) => '''
        <b><h3>${e.title}</h3></b>
        <p>${e.html}</p>
        ''').join('<br/><br/>')}
      <br/><br/><br/><br/><br/><br/><br/><br/>
    ''';
    return Scaffold(
        body: Stack(children: [
      CustomScrollView(slivers: [
        const SliverAppBar(title: Text('Consent'), floating: true),
        SliverList(
            delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                    padding: EdgeInsets.fromLTRB(0, 16, 0, bottomPadding),
                    child: PageHtmlTextBlock(
                        text: contentFromVisualScreens,
                        textAlign: TextAlign.left)),
                childCount: 1)),
      ]),
      Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.1, 0.2, 0.6],
                    colors: [
                      Theme.of(context).colorScheme.surface.withOpacity(0.7),
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      Theme.of(context).colorScheme.surface
                    ],
                  )),
                  height: max(150, 90 * scaleFactor),
                  child: Column(children: [
                    PrimaryButtonBlock(
                        title: 'Agree',
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Review'),
                                  content: const Text(
                                      'By tapping on Agree, you confirm that you have reviewed the consent document and agree to participating in the study.'),
                                  actions: <Widget>[
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        }),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        child: const Text('Agree'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          context.pushNamed(
                                              RouteName.consentAgreement);
                                        }),
                                  ],
                                );
                              });
                        }),
                    TextButtonBlock(
                        title: 'Disagree',
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Review'),
                                  content: const Text(
                                      'By disagreeing to consent you\'ll not be allowed to proceed further. You\'ll quit to home page and you\'ll be allowed to re-enroll in the study.'),
                                  actions: <Widget>[
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        }),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        child: const Text('Continue'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          context.goNamed(RouteName.root);
                                        }),
                                  ],
                                );
                              });
                        })
                  ]))))
    ]));
  }
}
