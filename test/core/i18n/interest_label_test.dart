import 'package:flutter_test/flutter_test.dart';
import 'package:silver_fun/core/constants.dart';
import 'package:silver_fun/core/i18n/interest_label.dart';
import 'package:silver_fun/l10n/app_localizations.dart';
import 'package:silver_fun/l10n/app_localizations_en.dart';
import 'package:silver_fun/l10n/app_localizations_ko.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ko;

  setUpAll(() {
    en = AppLocalizationsEn();
    ko = AppLocalizationsKo();
  });

  group('InterestLabel.localizedInterest', () {
    test('every value in kInterestPool has an English label', () {
      for (final value in kInterestPool) {
        final label = en.localizedInterest(value);
        expect(label, isNotEmpty, reason: 'no EN label for "$value"');
        // English label should equal the canonical value because the EN ARB
        // entries are identical to the pool strings.
        expect(label, equals(value),
            reason: 'EN label for "$value" should equal the value itself');
      }
    });

    test('every value in kInterestPool has a Korean label that differs', () {
      for (final value in kInterestPool) {
        final label = ko.localizedInterest(value);
        expect(label, isNotEmpty, reason: 'no KO label for "$value"');
        expect(label, isNot(equals(value)),
            reason: 'KO label for "$value" should not equal the English value');
      }
    });

    test('Korean labels match expected senior-friendly translations', () {
      expect(ko.localizedInterest('Coffee'), '커피');
      expect(ko.localizedInterest('Reading'), '독서');
      expect(ko.localizedInterest('Gardening'), '정원 가꾸기');
      expect(ko.localizedInterest('Bird watching'), '새 관찰');
      expect(ko.localizedInterest('Cards & bridge'), '카드 게임');
      expect(ko.localizedInterest('Grandkids'), '손주');
    });

    test('unknown value falls back to the raw input', () {
      expect(en.localizedInterest('SomethingNotInPool'),
          equals('SomethingNotInPool'));
      expect(ko.localizedInterest('SomethingNotInPool'),
          equals('SomethingNotInPool'));
      expect(en.localizedInterest(''), equals(''));
    });
  });
}
