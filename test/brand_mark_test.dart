import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/about_screen.dart';
import 'package:onesend/screens/home_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:onesend/services/update_service.dart';
import 'package:onesend/widgets/brand_mark.dart';

void main() {
  testWidgets('home and about share the official brand icon asset', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _localizedApp(
        'zh-Hans',
        HomeScreen(
          store: TransferStore(),
          updates: DisabledUpdateManager.instance,
          settings: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BrandMark), findsOneWidget);
    final homeAsset = _brandAssetName(tester);
    expect(homeAsset, oneSendBrandIconAsset);
    expect(
      find.descendant(of: find.byType(BrandMark), matching: find.text('1')),
      findsNothing,
    );

    await tester.pumpWidget(
      _localizedApp('zh-Hans', AboutScreen(packageInfoLoader: _packageInfo)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BrandIcon), findsOneWidget);
    final aboutAsset = _brandAssetName(tester);
    expect(aboutAsset, oneSendBrandIconAsset);
    expect(aboutAsset, homeAsset);
    expect(
      find.descendant(of: find.byType(BrandIcon), matching: find.text('1')),
      findsNothing,
    );
  });

  testWidgets(
    'brand wording follows simplified, traditional, and English locales',
    (WidgetTester tester) async {
      const expectedTaglines = <String, String?>{
        'zh-Hans': '扫传',
        'zh-Hant': '掃傳',
        'en': null,
      };

      for (final entry in expectedTaglines.entries) {
        await tester.pumpWidget(
          _localizedApp(
            entry.key,
            AboutScreen(packageInfoLoader: _packageInfo),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(oneSendBrandName), findsOneWidget);
        if (entry.value == null) {
          expect(find.text('扫传'), findsNothing);
          expect(find.text('掃傳'), findsNothing);
        } else {
          expect(find.text(entry.value!), findsOneWidget);
        }
        expect(find.text('1'), findsNothing);
      }
    },
  );
}

Widget _localizedApp(String localeTag, Widget child) {
  return MaterialApp(
    locale: LocaleSupport.parseTag(localeTag),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: LocaleSupport.supportedLocales,
    home: child,
  );
}

Future<PackageInfo> _packageInfo() async {
  return PackageInfo(
    appName: oneSendBrandName,
    packageName: 'com.makerjackie.onesend',
    version: '2.0.0',
    buildNumber: '20',
  );
}

String _brandAssetName(WidgetTester tester) {
  final images = find.descendant(
    of: find.byType(BrandIcon),
    matching: find.byType(Image),
  );
  expect(images, findsOneWidget);

  final image = tester.widget<Image>(images);
  final provider = image.image;
  expect(provider, isA<AssetImage>());
  return (provider as AssetImage).assetName;
}
