// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Sampul';

  @override
  String get login => 'Log Masuk';

  @override
  String get welcomeBack => 'Selamat kembali';

  @override
  String get signInToContinue => 'Log masuk untuk terus ke Sampul';

  @override
  String get email => 'E-mel';

  @override
  String get emailHint => 'anda@contoh.com';

  @override
  String get password => 'Kata laluan';

  @override
  String get forgotPassword => 'Lupa kata laluan?';

  @override
  String get signInFailed => 'Log masuk gagal. Sila cuba lagi.';

  @override
  String signInFailedWithError(String error) {
    return 'Log masuk gagal: $error';
  }

  @override
  String unexpectedError(String error) {
    return 'Ralat tidak dijangka berlaku: $error';
  }

  @override
  String get googleSignInCancelled => 'Log masuk Google dibatalkan atau gagal';

  @override
  String googleSignInFailed(String error) {
    return 'Log masuk Google gagal: $error';
  }

  @override
  String get signingIn => 'Sedang log masuk…';

  @override
  String get continueWithGoogle => 'Teruskan dengan Google';

  @override
  String get dontHaveAccount => 'Tiada akaun?';

  @override
  String get signUp => 'Daftar';

  @override
  String get or => 'ATAU';

  @override
  String get emailRequired => 'E-mel diperlukan';

  @override
  String get emailInvalid => 'Masukkan e-mel yang sah';

  @override
  String get passwordRequired => 'Kata laluan diperlukan';

  @override
  String get passwordMinLength =>
      'Kata laluan mestilah sekurang-kurangnya 6 aksara';

  @override
  String get aboutYourWill => 'Mengenai Wasiat Anda';

  @override
  String get letsCreateYourWill => 'Mari kita buat wasiat anda';

  @override
  String get willDescription =>
      'Satukan profil, keluarga, aset, dan hasrat anda dalam satu dokumen yang jelas.';

  @override
  String get letsListYourDigitalAssets =>
      'Mari kita senaraikan aset digital anda';

  @override
  String get assetsDescription =>
      'Simpan akaun dan platform dalam talian yang penting di satu tempat supaya wasiat anda kekal jelas dan terkini.';

  @override
  String get letsSetUpYourFamilyAccount =>
      'Mari kita sediakan akaun keluarga anda';

  @override
  String get trustDescription =>
      'Hasrat yang jelas, untuk orang yang anda sayangi.';

  @override
  String get letsPlanYourHibahGifts => 'Mari kita rancangkan hadiah Hibah anda';

  @override
  String get hibahDescription =>
      'Tentukan dengan jelas siapa yang harus menerima aset anda sebagai hadiah seumur hidup.';

  @override
  String get onboardingTitle1 => 'Letakkan kekayaan anda\ndalam tulisan';

  @override
  String get onboardingSubtitle1 =>
      'Tanpa Wasiat, kekayaan anda mungkin jatuh ke tangan yang salah. Selesaikannya hari ini—pantas, sah, dan bebas pertikaian.';

  @override
  String get onboardingTitle2 => 'Lakukan lebih banyak dengan\nSampul Trust';

  @override
  String get onboardingSubtitle2 =>
      'Kunci aset anda, labur untuk masa depan, dan pastikan orang tersayang mendapat apa yang menjadi hak mereka.';

  @override
  String get onboardingTitle3 => 'Jangan biarkan emosi\nmenentukan.';

  @override
  String get onboardingSubtitle3 =>
      'Pelaksana profesional memastikan wasiat anda diikuti—tiada drama keluarga, tiada kekacauan undang-undang, hanya penyerahan yang lancar.';

  @override
  String get settings => 'Tetapan';

  @override
  String get language => 'Bahasa';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get english => 'Bahasa Inggeris';

  @override
  String get malay => 'Bahasa Melayu';

  @override
  String get languageChanged => 'Bahasa telah ditukar';
}
