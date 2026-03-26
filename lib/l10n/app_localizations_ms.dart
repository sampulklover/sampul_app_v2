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
  String get welcomeToSampul => 'Selamat datang ke Sampul';

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
  String get appleSignInCancelled => 'Log masuk Apple dibatalkan atau gagal';

  @override
  String appleSignInFailed(String error) {
    return 'Log masuk Apple gagal: $error';
  }

  @override
  String get signingIn => 'Sedang log masuk…';

  @override
  String get continueWithGoogle => 'Teruskan dengan Google';

  @override
  String get continueWithApple => 'Teruskan dengan Apple';

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
  String get letsListYourDigitalAssets => 'Susun aset anda';

  @override
  String get assetsDescription =>
      'Sertakan aset penting anda—baik akaun digital mahupun barang fizikal—supaya arahan anda jelas dan boleh diakses apabila diperlukan.';

  @override
  String get letsSetUpYourFamilyAccount => 'Sediakan akaun keluarga anda';

  @override
  String get trustDescription =>
      'Hasrat anda, disusun dengan jelas untuk orang yang anda sayangi.';

  @override
  String get letsPlanYourHibahGifts => 'Rancangkan Property Trust anda';

  @override
  String get hibahDescription =>
      'Tentukan siapa menerima apa—rumah, simpanan atau pelaburan anda—dalam satu tempat yang jelas.';

  @override
  String get aboutPropertyTrust => 'Mengenai Property Trust';

  @override
  String get propertyTrustWhatIs => 'Apakah Property Trust?';

  @override
  String get propertyTrustAboutCopy =>
      'Property Trust membolehkan anda menamakan siapa yang menerima aset tertentu semasa anda masih hidup. Ia berdasarkan hibah dan berfungsi bersama wasiat dan pelan harta pusaka anda.';

  @override
  String get propertyTrustBenefit1 =>
      'Pilih siapa yang menerima aset mana—contohnya rumah, simpanan atau pelaburan.';

  @override
  String get propertyTrustBenefit2 =>
      'Dokumenkan hasrat anda dengan jelas supaya semua orang tahu niat anda.';

  @override
  String get propertyTrustBenefit3 =>
      'Berfungsi bersama wasiat dan pelan harta pusaka anda—hadiah seumur hidup dan pelan masa hadapan bersama.';

  @override
  String get startPropertyTrust => 'Mula menyediakan';

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
      'Pusaka profesional memastikan wasiat anda diikuti—tiada drama keluarga, tiada kekacauan undang-undang, hanya penyerahan yang lancar.';

  @override
  String get next => 'Seterusnya';

  @override
  String get getStarted => 'Mula';

  @override
  String get skip => 'Langkau';

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

  @override
  String get assalamualaikum => 'Assalamualaikum...';

  @override
  String assalamualaikumWithName(String name) {
    return 'Assalamualaikum, $name';
  }

  @override
  String get referrals => 'Rujukan';

  @override
  String get myAssets => 'Aset Saya';

  @override
  String get seeAll => 'Lihat Semua →';

  @override
  String get myFamily => 'Keluarga Saya';

  @override
  String get submitted => 'Dihantar';

  @override
  String get approved => 'Diluluskan';

  @override
  String get rejected => 'Ditolak';

  @override
  String get draft => 'Draf';

  @override
  String get yourPlanIsActive => 'Pelan anda aktif';

  @override
  String get familyAccount => 'Akaun Keluarga';

  @override
  String get createYourFirstTrustFund => 'Tambah akaun keluarga pertama anda';

  @override
  String get addNewTrustFund => 'Tambah akaun keluarga pertama anda';

  @override
  String get tapToGetStarted => 'Ketik untuk mula';

  @override
  String get will => 'Wasiat';

  @override
  String get hibah => 'Property';

  @override
  String get trust => 'Amanah';

  @override
  String get others => 'Lain-lain';

  @override
  String get assets => 'Aset';

  @override
  String get family => 'Keluarga';

  @override
  String get checklist => 'Senarai Semak';

  @override
  String get execution => 'Pusaka';

  @override
  String get pusaka => 'Pusaka';

  @override
  String get aftercare => 'Penjagaan Selepas';

  @override
  String get informDeathTitle => 'Maklumkan Kematian';

  @override
  String get informDeathStartCta => 'Mula Maklumkan Kematian';

  @override
  String get informDeathMenuLabel => 'Maklumkan Kematian';

  @override
  String get informDeathDeleteDialogTitle => 'Padam rekod Maklumkan Kematian';

  @override
  String get informDeathDeleteSuccess => 'Rekod Maklumkan Kematian dipadam';

  @override
  String get informDeathHeroTitle => 'Maklumkan Sampul tentang kematian';

  @override
  String get informDeathHeroBody =>
      'Jika seseorang pengguna Sampul telah meninggal dunia, halaman ini membantu anda memaklumkan kami dengan cara yang tenang dan teratur.';

  @override
  String get informDeathWhatYoullShareTitle => 'Maklumat yang akan dikongsi';

  @override
  String get informDeathWhatYoullShareBody =>
      'Kami akan meminta butiran pemilik Sampul dan salinan sijil kematian. Ini membantu kami mengesahkan orang yang betul dan menyokong keluarga mereka dengan sewajarnya.';

  @override
  String get informDeathFeatureOwner =>
      'Nama penuh dan nombor NRIC pemilik (seperti dalam NRIC).';

  @override
  String get informDeathFeatureCertNumber =>
      'Nombor sijil kematian supaya kami boleh memadankan dokumen.';

  @override
  String get informDeathFeatureCertImage =>
      'Gambar atau imbasan yang jelas bagi sijil kematian.';

  @override
  String get informDeathOwnerSectionTitle => 'Butiran pemilik Sampul';

  @override
  String get informDeathOwnerNameLabel => 'Nama penuh (seperti dalam NRIC)';

  @override
  String get informDeathOwnerNricLabel => 'Nombor NRIC';

  @override
  String get informDeathSupportingDocsSectionTitle => 'Dokumen sokongan';

  @override
  String get informDeathSupportingDocsBody =>
      'Lampirkan sijil kematian supaya pasukan kami boleh mengesahkan maklumat.';

  @override
  String get informDeathNoFileChosen => 'Tiada fail dipilih';

  @override
  String get informDeathUploadHint =>
      'Muat naik gambar atau imbasan yang jelas bagi sijil kematian.';

  @override
  String get informDeathChooseFile => 'Pilih fail';

  @override
  String get informDeathCertificateIdLabel => 'ID sijil kematian';

  @override
  String get informDeathRequiredField => 'Wajib diisi';

  @override
  String get informDeathSubmitCta => 'Hantar kepada Sampul';

  @override
  String get informDeathStatusDraft => 'Draf';

  @override
  String get informDeathStatusSubmitted => 'Dihantar';

  @override
  String get informDeathStatusUnderReview => 'Sedang disemak';

  @override
  String get informDeathStatusApproved => 'Diluluskan';

  @override
  String get informDeathStatusRejected => 'Ditolak';

  @override
  String get informDeathStatusUnknown => 'Dihantar';

  @override
  String informDeathListNric(String nric) {
    return 'NRIC: $nric';
  }

  @override
  String informDeathListCertificateId(String certId) {
    return 'ID sijil: $certId';
  }

  @override
  String informDeathListSubmittedOn(String date) {
    return 'Dihantar pada: $date';
  }

  @override
  String get informDeathInfoBannerBody =>
      'Perlu maklumkan Sampul tentang kematian?';

  @override
  String get informDeathInfoBannerCta => 'Permintaan baharu';

  @override
  String get informDeathOpenFile => 'Buka fail';

  @override
  String get informDeathUnableToOpenFile => 'Tidak dapat membuka fail';

  @override
  String get informDeathRemoveFile => 'Buang fail';

  @override
  String get informDeathRemoveFileTitle => 'Buang fail yang dimuat naik?';

  @override
  String get informDeathRemoveFileBody =>
      'Ini akan memadam fail yang dimuat naik daripada permintaan ini.';

  @override
  String get add => 'Tambah';

  @override
  String get loading => 'Memuatkan...';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get faraid => 'Faraid';

  @override
  String get terminateSubscriptions => 'Tamatkan Langganan';

  @override
  String get transferAsGift => 'Pindahkan sebagai Hadiah';

  @override
  String get settleDebts => 'Selesaikan Hutang';

  @override
  String get coSampul => 'Co-sampul';

  @override
  String get beneficiary => 'Penerima Manfaat';

  @override
  String get guardian => 'Penjaga';

  @override
  String get account => 'Akaun';

  @override
  String get user => 'Pengguna';

  @override
  String get noEmail => 'Tiada e-mel';

  @override
  String get edit => 'Edit';

  @override
  String get identityVerification => 'Pengesahan Identiti';

  @override
  String get checkingStatus => 'Menyemak status...';

  @override
  String get yourIdentityIsVerified => 'Identiti anda telah disahkan';

  @override
  String get verificationInProgress => 'Pengesahan sedang dijalankan';

  @override
  String get verificationWasDeclined => 'Pengesahan telah ditolak';

  @override
  String get verificationWasRejected => 'Pengesahan telah ditolak';

  @override
  String get verifyYourIdentity => 'Sahkan identiti anda';

  @override
  String get verified => 'Disahkan';

  @override
  String get pending => 'Menunggu';

  @override
  String get declined => 'Ditolak';

  @override
  String get changePassword => 'Tukar kata laluan';

  @override
  String get logOut => 'Log keluar';

  @override
  String get billing => 'Bil';

  @override
  String get plansAndSubscription => 'Pelan & langganan';

  @override
  String get manageYourSampulPlan => 'Urus pelan Sampul anda';

  @override
  String get preferences => 'Pilihan';

  @override
  String get yourCodeAndReferrals => 'Kod dan rujukan anda';

  @override
  String get aiChatSettings => 'Tetapan AI Chat';

  @override
  String get manageSampulAiResponses => 'Urus respons AI Sampul';

  @override
  String get darkMode => 'Mod gelap';

  @override
  String get restartOnboarding => 'Mulakan semula onboarding';

  @override
  String get runTheSetupFlowAgain => 'Jalankan aliran persediaan semula';

  @override
  String get onboardingHasBeenReset => 'Onboarding telah ditetapkan semula';

  @override
  String failedToResetOnboarding(String error) {
    return 'Gagal menetapkan semula onboarding: $error';
  }

  @override
  String get sendFeedback => 'Hantar maklum balas';

  @override
  String get reportBugsOrRequestFeatures =>
      'Laporkan pepijat atau cadangkan ciri baharu';

  @override
  String get about => 'Mengenai';

  @override
  String get appVersion => 'Versi aplikasi';

  @override
  String get appVersionDemo => '1.0.0 (demo)';

  @override
  String get termsOfService => 'Terma Perkhidmatan';

  @override
  String get termsTappedDemo => 'Terma diketuk (demo)';

  @override
  String get privacyPolicy => 'Dasar Privasi';

  @override
  String get privacyTappedDemo => 'Privasi diketuk (demo)';

  @override
  String get deleteAccount => 'Padam Akaun';

  @override
  String get changePasswordTitle => 'Tukar Kata Laluan';

  @override
  String get enterCurrentPasswordAndChooseNew =>
      'Masukkan kata laluan semasa anda dan pilih yang baru';

  @override
  String get currentPassword => 'Kata Laluan Semasa';

  @override
  String get pleaseEnterCurrentPassword =>
      'Sila masukkan kata laluan semasa anda';

  @override
  String get newPassword => 'Kata Laluan Baru';

  @override
  String get pleaseEnterNewPassword => 'Sila masukkan kata laluan baru';

  @override
  String get confirmNewPassword => 'Sahkan Kata Laluan Baru';

  @override
  String get pleaseConfirmNewPassword => 'Sila sahkan kata laluan baru anda';

  @override
  String get passwordsDoNotMatch => 'Kata laluan tidak sepadan';

  @override
  String get updatingPassword => 'Mengemas kini kata laluan...';

  @override
  String get cancel => 'Batal';

  @override
  String get change => 'Tukar';

  @override
  String get optional => 'Pilihan';

  @override
  String get assetAdded => 'Aset ditambah';

  @override
  String get copy => 'Salin';

  @override
  String get passwordChangedSuccessfully => 'Kata laluan berjaya ditukar!';

  @override
  String get deleteAccountTitle => 'Padam Akaun';

  @override
  String get areYouSureDeleteAccount =>
      'Adakah anda pasti mahu memadam akaun anda? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get areYouSureYouWantToLogOut => 'Adakah anda pasti mahu log keluar?';

  @override
  String get toConfirmTypeDelete =>
      'Untuk mengesahkan, sila taip \"DELETE\" dalam kotak di bawah:';

  @override
  String get typeDeleteToConfirm => 'Taip DELETE untuk mengesahkan';

  @override
  String get delete => 'Padam';

  @override
  String get deleteAccountFeatureComingSoon =>
      'Ciri padam akaun akan datang tidak lama lagi';

  @override
  String get creatingVerificationSession => 'Membuat sesi pengesahan...';

  @override
  String get couldNotOpenVerificationLink =>
      'Tidak dapat membuka pautan pengesahan';

  @override
  String failedToStartVerification(String error) {
    return 'Gagal memulakan pengesahan: $error';
  }

  @override
  String get diditNotConfigured =>
      'Didit tidak dikonfigurasi. Sila tetapkan DIDIT_CLIENT_ID (kunci API) dan DIDIT_WORKFLOW_ID dalam fail .env anda.';

  @override
  String get identityVerificationRequired =>
      'Pengesahan identiti diperlukan untuk mewujudkan kepercayaan dan memastikan kesahan undang-undang wasiat anda.';

  @override
  String get legalValidity => 'Kesahan Undang-undang';

  @override
  String get establishesLegalValidity =>
      'Mewujudkan kesahan undang-undang wasiat anda';

  @override
  String get buildsTrust => 'Membina Kepercayaan';

  @override
  String get providesAssurance =>
      'Memberi jaminan kepada benefisiari dan Pusaka';

  @override
  String get regulatoryCompliance => 'Pematuhan Peraturan';

  @override
  String get ensuresCompliance =>
      'Memastikan pematuhan dengan keperluan peraturan';

  @override
  String get fraudProtection => 'Perlindungan Penipuan';

  @override
  String get protectsAgainstFraud =>
      'Melindungi daripada penipuan dan kecurian identiti';

  @override
  String get yourInformationIsEncrypted =>
      'Maklumat anda disulitkan dan selamat';

  @override
  String get startVerification => 'Mula Pengesahan';

  @override
  String get notificationsTitle => 'Notifikasi';

  @override
  String get noNotifications => 'Tiada notifikasi';

  @override
  String get youAreAllCaughtUp => 'Semua sudah dikemas kini.';

  @override
  String get markAllAsRead => 'Tanda semua sebagai dibaca';

  @override
  String get clearAll => 'Buang semua';

  @override
  String get removeNotificationTitle => 'Buang notifikasi?';

  @override
  String get removeNotificationDescription =>
      'Ini akan membuang notifikasi daripada senarai anda.';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get save => 'Simpan';

  @override
  String get invalidImage =>
      'Imej tidak sah. Sila pilih fail imej yang sah (maks 5MB)';

  @override
  String get imageUploadedSuccessfully => 'Imej berjaya dimuat naik';

  @override
  String failedToUploadImage(String error) {
    return 'Gagal memuat naik imej: $error';
  }

  @override
  String get selectImageSource => 'Pilih Sumber Imej';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get profileUpdatedSuccessfully => 'Profil berjaya dikemas kini';

  @override
  String failedToUpdateProfile(String error) {
    return 'Gagal mengemas kini profil: $error';
  }

  @override
  String get uploading => 'Memuat naik...';

  @override
  String get changePhoto => 'Tukar Foto';

  @override
  String get personalInformation => 'Maklumat Peribadi';

  @override
  String get username => 'Nama pengguna';

  @override
  String get enterYourUsername => 'Masukkan nama pengguna anda';

  @override
  String get fullNameNric => 'Nama Penuh (NRIC)';

  @override
  String get enterYourFullNameAsPerNric =>
      'Masukkan nama penuh anda seperti dalam NRIC';

  @override
  String get phoneNumber => 'Nombor Telefon';

  @override
  String get enterYourPhoneNumber => 'Masukkan nombor telefon anda';

  @override
  String get gender => 'Jantina';

  @override
  String get religion => 'Agama';

  @override
  String get enterYourEmail => 'Masukkan e-mel anda';

  @override
  String get emailCannotBeChanged => 'E-mel tidak boleh ditukar';

  @override
  String get addressInformation => 'Maklumat Alamat';

  @override
  String get addressLine1 => 'Baris Alamat 1';

  @override
  String get enterYourAddress => 'Masukkan alamat anda';

  @override
  String get addressLine2 => 'Baris Alamat 2';

  @override
  String get enterAdditionalAddressDetails =>
      'Masukkan butiran alamat tambahan';

  @override
  String get city => 'Bandar';

  @override
  String get enterCity => 'Masukkan bandar';

  @override
  String get state => 'Negeri';

  @override
  String get enterState => 'Negeri';

  @override
  String get postcode => 'Poskod';

  @override
  String get enterPostcode => 'Masukkan poskod';

  @override
  String get country => 'Negara';

  @override
  String get myWill => 'Wasiat Saya';

  @override
  String get shareWill => 'Kongsi Wasiat';

  @override
  String get whyCreateYourWillInSampul => 'Mengapa buat wasiat anda di Sampul?';

  @override
  String get yourWillPullsFromProfile =>
      'Wasiat anda mengambil maklumat daripada profil, senarai keluarga, aset digital, dan hasrat tambahan supaya semuanya kekal bersambung.';

  @override
  String get keepAllKeyInformation =>
      'Simpan semua maklumat penting (profil, keluarga, aset) di satu tempat.';

  @override
  String get generateStructuredWillDocument =>
      'Hasilkan dokumen wasiat berstruktur yang boleh anda baca, eksport, dan kongsi.';

  @override
  String get updateWillLater =>
      'Kemas kini wasiat anda kemudian apabila kehidupan atau aset anda berubah.';

  @override
  String get startMyWill => 'Mula wasiat saya';

  @override
  String get deleting => 'Memadam...';

  @override
  String get publish => 'Terbitkan';

  @override
  String get unpublish => 'Nyahterbit';

  @override
  String get publishWill => 'Terbitkan Wasiat';

  @override
  String publishWillConfirmation(String url) {
    return 'Adakah anda pasti mahu menerbitkan wasiat ini?\n\nSetelah diterbitkan, wasiat ini akan boleh diakses oleh sesiapa yang mempunyai pautan kongsi:\n$url\n\nPastikan anda hanya berkongsi pautan ini dengan ahli keluarga atau Pusaka yang dipercayai.';
  }

  @override
  String get shareLinkCopiedToClipboard =>
      'Pautan kongsi disalin ke papan klip';

  @override
  String get willPublishedSuccessfully => 'Wasiat berjaya diterbitkan';

  @override
  String get willUnpublishedSuccessfully => 'Wasiat berjaya dinyahterbit';

  @override
  String failedToPublishWill(String error) {
    return 'Gagal menerbitkan wasiat: $error';
  }

  @override
  String failedToUnpublishWill(String error) {
    return 'Gagal menyahterbit wasiat: $error';
  }

  @override
  String failedToDeleteWill(String error) {
    return 'Gagal memadam wasiat: $error';
  }

  @override
  String failedToLoadWillData(String error) {
    return 'Gagal memuatkan data wasiat: $error';
  }

  @override
  String get code => 'Kod';

  @override
  String warningsReviewRecommended(int count) {
    return '$count amaran - Semakan disyorkan';
  }

  @override
  String issuesActionRequired(int count) {
    return '$count isu - Tindakan diperlukan';
  }

  @override
  String get published => 'Diterbitkan';

  @override
  String get deleteWill => 'Padam Wasiat';

  @override
  String get areYouSureDeleteWill =>
      'Adakah anda pasti mahu memadam wasiat anda? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get createWill => 'Cipta Wasiat';

  @override
  String get editWill => 'Edit Wasiat';

  @override
  String get updateWill => 'Kemas Kini Wasiat';

  @override
  String get executors => 'Pusaka';

  @override
  String get aboutPusaka => 'Tentang Pusaka';

  @override
  String get noPusakaYet => 'Tiada Pusaka lagi';

  @override
  String get newToPusaka => 'Baru kepada Pusaka?';

  @override
  String get submitPusaka => 'Hantar Pusaka';

  @override
  String get guardians => 'Penjaga';

  @override
  String get extraWishes => 'Hasrat Tambahan';

  @override
  String get reviewSave => 'Semak & Simpan';

  @override
  String get primaryExecutor => 'Pusaka Utama';

  @override
  String get selectPrimaryExecutor =>
      'Pilih Pusaka utama untuk melaksanakan wasiat anda';

  @override
  String get secondaryExecutor => 'Pusaka Sekunder';

  @override
  String get selectSecondaryExecutor => 'Pilihan: Pilih Pusaka sekunder';

  @override
  String get primaryGuardian => 'Penjaga Utama';

  @override
  String get selectPrimaryGuardian =>
      'Pilih penjaga untuk kanak-kanak bawah umur (jika berkenaan)';

  @override
  String get secondaryGuardian => 'Penjaga Sekunder';

  @override
  String get selectSecondaryGuardian => 'Pilihan: Pilih penjaga sekunder';

  @override
  String get selectFamilyMember => 'Pilih ahli keluarga';

  @override
  String get noneSelected => 'Tiada dipilih';

  @override
  String get notFound => 'Tidak dijumpai';

  @override
  String get yourAssets => 'Aset Anda';

  @override
  String get manageAll => 'Urus Semua';

  @override
  String get noAssetsYet =>
      'Tiada aset lagi. Tambah satu apabila anda sudah bersedia.';

  @override
  String showMore(int count) {
    return 'Tunjukkan lebih banyak ($count)';
  }

  @override
  String get yourExtraWishes => 'Hasrat Tambahan Anda';

  @override
  String get noWishesYet =>
      'Tiada hasrat lagi. Tambah nazar, fidyah, ikrar penderma organ, dan peruntukan amal anda.';

  @override
  String get nazarWishes => 'Hasrat nazar';

  @override
  String get nazarCost => 'Kos nazar';

  @override
  String get fidyahDays => 'Hari fidyah';

  @override
  String get fidyahAmount => 'Jumlah fidyah';

  @override
  String get organDonorPledge => 'Ikrar penderma organ';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'Tidak';

  @override
  String waqf(int count, String total) {
    return 'Wakaf: $count badan • RM $total';
  }

  @override
  String charity(int count, String total) {
    return 'Amal';
  }

  @override
  String get name => 'Nama';

  @override
  String get nric => 'NRIC';

  @override
  String get phone => 'Telefon';

  @override
  String get address => 'Alamat';

  @override
  String get notProvided => 'Tidak disediakan';

  @override
  String totalAssets(String total) {
    return 'Jumlah aset: RM $total';
  }

  @override
  String get yourWillUpdatesAutomatically =>
      'Wasiat anda dikemas kini secara automatik dengan perubahan profil, aset, dan keluarga anda.';

  @override
  String get willCreatedSuccessfully => 'Wasiat berjaya dicipta!';

  @override
  String get willUpdatedSuccessfully => 'Wasiat berjaya dikemas kini!';

  @override
  String failedToSaveWill(String error) {
    return 'Gagal menyimpan wasiat: $error';
  }

  @override
  String failedToLoadInitialData(String error) {
    return 'Gagal memuatkan data awal: $error';
  }

  @override
  String get addAsset => 'Tambah Aset';

  @override
  String get aboutAssets => 'Mengenai Aset';

  @override
  String get platformService => 'Platform / Perkhidmatan';

  @override
  String get selectPlatform => 'Pilih platform';

  @override
  String get chooseDigitalAccountToInclude =>
      'Pilih akaun digital yang anda ingin sertakan.';

  @override
  String get enterPhysicalAssetName => 'Masukkan nama aset fizikal anda';

  @override
  String get physicalAssetName => 'Nama aset';

  @override
  String get assetInfo => 'Maklumat aset';

  @override
  String get physicalAssetNameHint =>
      'cth., Rumah Saya, Kereta, Koleksi Barang Kemas';

  @override
  String get details => 'Butiran';

  @override
  String get review => 'Semak';

  @override
  String get reviewThisDigitalAsset => 'Semak aset digital ini';

  @override
  String get reviewThisAsset => 'Semak aset ini';

  @override
  String get searchForPlatformOrService => 'Cari platform atau perkhidmatan';

  @override
  String get searchPlatformHint => 'cth., Facebook, Google Drive, Maybank';

  @override
  String get addYourOwnAsset => 'Tambah aset anda sendiri';

  @override
  String useAsAssetName(String text) {
    return 'Gunakan \"$text\" sebagai nama aset';
  }

  @override
  String cantFindItAddAsCustom(String text) {
    return 'Tidak jumpa? Tambah \"$text\" sebagai tersuai';
  }

  @override
  String get addCustomAsset => 'Tambah Aset Tersuai';

  @override
  String get assetName => 'Nama Aset *';

  @override
  String get assetNameHint => 'cth., Platform Tersuai Saya';

  @override
  String get websiteUrlOptional => 'URL Laman Web (pilihan)';

  @override
  String get websiteUrlHint => 'https://example.com';

  @override
  String get required => 'Diperlukan';

  @override
  String get declaredValueMyr => 'Nilai Dinyatakan (MYR)';

  @override
  String get estimatedCurrentValue => 'Anggaran nilai semasa aset ini';

  @override
  String get enterValidAmountMaxDecimals =>
      'Masukkan jumlah yang sah (maks 2 perpuluhan)';

  @override
  String get enterValidAmount => 'Masukkan jumlah yang sah';

  @override
  String get instructionsAfterDeath => 'Arahan Selepas Kematian';

  @override
  String get instructionUponActivation => 'Arahan semasa pengaktifan';

  @override
  String get whatShouldHappenToThisAccount =>
      'Apa yang harus berlaku pada aset ini?';

  @override
  String get defineHowThisAccountShouldBeHandled =>
      'Tentukan bagaimana aset ini harus dikendalikan.';

  @override
  String get closeThisAccount => 'Tutup akaun ini';

  @override
  String get transferAccessToExecutor => 'Pindahkan akses kepada Pusaka saya';

  @override
  String get memorialiseIfApplicable => 'Peringati (jika berkenaan)';

  @override
  String get leaveSpecificInstructions => 'Tinggalkan arahan khusus';

  @override
  String get provideDetailsBelow => 'Berikan butiran di bawah.';

  @override
  String get thisInformationOnlyAccessible =>
      'Maklumat ini hanya boleh diakses mengikut arahan harta pusaka anda.';

  @override
  String get loadingRecipients => 'Memuatkan penerima...';

  @override
  String get giftRecipient => 'Penerima Hadiah';

  @override
  String get giftRecipientRequired => 'Penerima Hadiah diperlukan';

  @override
  String get estimatedValue => 'Nilai anggaran (RM)';

  @override
  String get estimatedValueDescription =>
      'Nilai anggaran membantu Pusaka anda memahami nilai aset.';

  @override
  String get enterEstimatedValue => 'Masukkan nilai anggaran (RM)';

  @override
  String get estimatedValueHint => 'cth., 5000.00';

  @override
  String get remarksOptional => 'Catatan tambahan';

  @override
  String get remarksHint =>
      'cth., Lokasi akaun, arahan khas, atau butiran penting';

  @override
  String get additionalNotes => 'Catatan tambahan';

  @override
  String get additionalNotesDescription =>
      'Tambah sebarang butiran tambahan yang akan membantu Pusaka anda menguruskan aset ini.';

  @override
  String get youMightWantToInclude => 'Anda mungkin ingin sertakan:';

  @override
  String get remarksSuggestion1 =>
      'Lokasi akaun atau di mana untuk mencari butiran log masuk';

  @override
  String get remarksSuggestion2 => 'Arahan khas atau butiran penting';

  @override
  String get remarksSuggestion3 => 'Maklumat hubungan untuk pemulihan akaun';

  @override
  String get remarksSuggestionPhysical1 => 'Lokasi atau di mana aset disimpan';

  @override
  String get remarksSuggestionPhysical2 => 'Arahan khas atau butiran penting';

  @override
  String get remarksSuggestionPhysical3 =>
      'Lokasi dokumentasi atau kertas pemilikan';

  @override
  String get assetWillBeIncludedInWill =>
      'Aset ini akan dimasukkan dalam wasiat anda. Sebarang perubahan yang anda buat akan disegerakkan secara automatik.';

  @override
  String get website => 'Laman Web';

  @override
  String get instruction => 'Arahan';

  @override
  String get remarks => 'Catatan';

  @override
  String get pleaseSelectPlatformService => 'Sila pilih platform/perkhidmatan';

  @override
  String get pleaseSelectAssetType => 'Sila pilih jenis aset';

  @override
  String get pleaseSelectInstruction => 'Sila pilih arahan';

  @override
  String get pleaseSelectGiftRecipient => 'Sila pilih penerima hadiah';

  @override
  String get assetAddedSuccessfully => 'Aset ditambah';

  @override
  String failedToAddAsset(String error) {
    return 'Sesuatu tidak kena. Sila cuba lagi.';
  }

  @override
  String searchFailed(String error) {
    return 'Carian gagal: $error';
  }

  @override
  String get youMustBeSignedIn => 'Anda mesti log masuk';

  @override
  String get unnamed => 'Tanpa nama';

  @override
  String get editAsset => 'Edit Aset';

  @override
  String get changesHereUpdateWillAutomatically =>
      'Perubahan di sini mengemas kini wasiat anda secara automatik.';

  @override
  String get assetUpdated => 'Aset dikemas kini';

  @override
  String failedToUpdate(String error) {
    return 'Gagal mengemas kini: $error';
  }

  @override
  String get deleteAsset => 'Padam Aset';

  @override
  String get areYouSureDeleteAsset =>
      'Adakah anda pasti mahu memadam aset ini? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get assetDeleted => 'Aset dipadam';

  @override
  String failedToDelete(String error) {
    return 'Gagal memadam: $error';
  }

  @override
  String get whyAddYourAssets => 'Mengapa ini penting';

  @override
  String get assetListConnectsToWill =>
      'Senarai aset anda bersambung dengan wasiat dan perancangan harta pusaka. Tambah aset digital dan fizikal supaya Pusaka anda tahu apa yang perlu diuruskan.';

  @override
  String get assetType => 'Jenis aset';

  @override
  String get digitalAsset => 'Aset digital';

  @override
  String get physicalAsset => 'Aset fizikal';

  @override
  String get selectAssetType => 'Pilih jenis aset';

  @override
  String get selectAssetCategory => 'Apakah jenis aset ini?';

  @override
  String get whatTypeOfPhysicalAsset => 'Apakah jenis aset fizikal ini?';

  @override
  String get land => 'Tanah (hakmilik individu atau bersama)';

  @override
  String get housesBuildings => 'Rumah / bangunan';

  @override
  String get farmsPlantations => 'Ladang, estet';

  @override
  String get cash => 'Wang tunai';

  @override
  String get vehicles => 'Kenderaan (kereta, motosikal)';

  @override
  String get jewellery => 'Barang kemas';

  @override
  String get furnitureHousehold => 'Perabot & barangan rumah';

  @override
  String get financialInstruments =>
      'Instrumen kewangan (KWSP, ASNB, Tabung Haji)';

  @override
  String get propertyOrLand => 'Harta atau tanah';

  @override
  String get propertyOrLandDescription =>
      'Tanah, rumah, bangunan, ladang, estet';

  @override
  String get vehicle => 'Kenderaan';

  @override
  String get vehicleDescription => 'Kereta, motosikal, bot, kenderaan lain';

  @override
  String get jewelleryOrValuables => 'Barang kemas atau berharga';

  @override
  String get jewelleryOrValuablesDescription =>
      'Barang kemas, jam tangan, seni, koleksi, perabot, barangan rumah';

  @override
  String get cashOrInvestments => 'Wang tunai atau pelaburan';

  @override
  String get cashOrInvestmentsDescription =>
      'Wang tunai, KWSP, ASNB, Tabung Haji, saham, bon, instrumen kewangan lain';

  @override
  String get otherPhysicalAsset => 'Aset fizikal lain';

  @override
  String get otherPhysicalAssetDescription => 'Mana-mana aset ketara lain';

  @override
  String get immovableAssetNote => 'Jenis aset: Harta (Harta tak alih)';

  @override
  String get selectLegalClassification =>
      'Adakah ini harta alih atau harta tak alih?';

  @override
  String get pleaseSelectLegalClassification =>
      'Sila pilih sama ada ini harta alih atau harta tak alih';

  @override
  String get legalClassificationExplanation =>
      'Ini membantu kami memproses aset anda mengikut undang-undang pusaka Malaysia.';

  @override
  String get movableAsset => 'Harta alih';

  @override
  String get movableAssetExplanation =>
      'Barang yang boleh dipindahkan dengan mudah, seperti kenderaan, wang tunai, barang kemas, perabot, atau instrumen kewangan.';

  @override
  String get immovableAsset => 'Harta tak alih';

  @override
  String get immovableAssetExplanation =>
      'Harta yang kekal di tempat, seperti tanah, rumah, bangunan, ladang, atau estet.';

  @override
  String get movableAssetDescription =>
      'Barang yang boleh dipindahkan\n• Kenderaan\n• Barang kemas dan berharga\n• Wang tunai dan pelaburan\n• Seni dan koleksi';

  @override
  String get immovableAssetDescription =>
      'Harta yang kekal di tempat\n• Tanah dan harta\n• Bangunan dan struktur\n• Hartanah';

  @override
  String get pleaseSelectAssetCategory => 'Sila pilih jenis aset';

  @override
  String get makeItEasyForExecutors => 'Elakkan akaun daripada hilang';

  @override
  String get linkEachAssetToInstructions =>
      'Pastikan penutupan atau pemindahan yang betul';

  @override
  String get keepWillUpToDate => 'Elakkan langganan yang tidak dibayar';

  @override
  String get provideClearInstructionsToExecutor =>
      'Berikan arahan yang jelas kepada Pusaka anda';

  @override
  String get weDoNotStorePasswords =>
      'Kami tidak menyimpan kata laluan atau kelayakan log masuk.';

  @override
  String get addAssetButton => 'Tambah aset';

  @override
  String get saveDigitalAsset => 'Simpan aset digital';

  @override
  String get saveAsset => 'Simpan aset';

  @override
  String get savePhysicalAsset => 'Simpan aset fizikal';

  @override
  String get returnToDashboard => 'Kembali ke papan pemuka';

  @override
  String get addAnotherDigitalAsset => 'Tambah aset digital lain';

  @override
  String get addAnotherAsset => 'Tambah aset lain';

  @override
  String get yourInstructionRecordedSecurely =>
      'Arahan anda telah direkodkan dengan selamat.';

  @override
  String get youCanReviewOrUpdateAnytime =>
      'Anda boleh menyemak atau mengemas kini pada bila-bila masa.';

  @override
  String get passwordsNotStoredInSampul =>
      'Kata laluan tidak disimpan dalam Sampul.';

  @override
  String get cantFindYourPlatform => 'Tidak jumpa platform anda?';

  @override
  String get addCustomPlatform => 'Tambah platform tersuai';

  @override
  String get youllProvideInstructionsNextStep =>
      'Anda akan memberikan arahan dalam langkah seterusnya. Kami tidak menyimpan kata laluan';

  @override
  String get aboutFamilyMembers => 'Mengenai Ahli Keluarga';

  @override
  String get letsAddYourFamily => 'Mari kita tambah keluarga anda';

  @override
  String get addPeopleWhoMatterMost =>
      'Tambah orang yang paling penting — Pusaka, penerima manfaat, dan penjaga — supaya wasiat anda kekal jelas dan bersambung.';

  @override
  String get whyAddFamilyMembers => 'Mengapa tambah ahli keluarga?';

  @override
  String get familyListConnectsToWill =>
      'Senarai keluarga anda bersambung dengan wasiat, amanah, dan perancangan Property Trust anda. Tambah Pusaka (Co-Sampul), penerima manfaat, dan penjaga.';

  @override
  String get assignExecutorsCoSampul =>
      'Tugaskan Pusaka (Co-Sampul) yang akan melaksanakan wasiat anda.';

  @override
  String get listBeneficiariesWhoReceive =>
      'Senaraikan penerima manfaat yang akan menerima aset anda.';

  @override
  String get designateGuardiansForMinors =>
      'Tentukan penjaga untuk kanak-kanak bawah umur jika diperlukan.';

  @override
  String get addFamilyMember => 'Tambah ahli keluarga';

  @override
  String get waris => 'Waris';

  @override
  String get nonWaris => 'Bukan Waris';

  @override
  String get legacy => 'Warisan';

  @override
  String get addFamilyMemberTitle => 'Tambah Ahli Keluarga';

  @override
  String get basicInfo => 'Maklumat Asas';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String get fullName => 'Nama Penuh';

  @override
  String get nameRequired => 'Nama diperlukan';

  @override
  String get pleaseEnterValidName => 'Sila masukkan nama yang sah';

  @override
  String get relationship => 'Hubungan';

  @override
  String get relationshipRequired => 'Hubungan diperlukan';

  @override
  String get category => 'Kategori';

  @override
  String get coSampulExecutor => 'Co-sampul (Pusaka)';

  @override
  String get coSampulExecutorHelp =>
      'Co-sampul (Pusaka): Orang yang dipercayai yang melaksanakan wasiat anda bersama-sama dengan anda.';

  @override
  String get beneficiaryHelp =>
      'Penerima Manfaat: Orang yang akan mewarisi aset yang anda pilih.';

  @override
  String get guardianHelp =>
      'Penjaga: Orang yang bertanggungjawab menjaga tanggungan atau kanak-kanak bawah umur anda.';

  @override
  String get percentage0To100 => 'Peratusan (0 - 100)';

  @override
  String get otherInfoOptional => 'Maklumat Lain (pilihan)';

  @override
  String get icNricNumber => 'Nombor IC/NRIC';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Sila masukkan alamat e-mel yang sah';

  @override
  String get pleaseProvidePercentageForBeneficiary =>
      'Sila berikan peratusan untuk penerima manfaat';

  @override
  String get percentageMustBeBetween0And100 =>
      'Peratusan mestilah antara 0 dan 100';

  @override
  String get contactId => 'Hubungan & ID';

  @override
  String get ifPersonPartOfWillSync =>
      'Jika orang ini adalah sebahagian daripada wasiat anda, sebarang kemas kini yang anda buat di sini akan disegerakkan secara automatik ke wasiat anda.';

  @override
  String get familyMemberAdded => 'Ahli keluarga ditambah';

  @override
  String failedToAdd(String error) {
    return 'Gagal menambah: $error';
  }

  @override
  String get invalidImageUseJpgPngWebp =>
      'Imej tidak sah. Gunakan JPG/PNG/WebP di bawah 5MB.';

  @override
  String imageSelectionFailed(String error) {
    return 'Pemilihan imej gagal: $error';
  }

  @override
  String get editFamilyMember => 'Edit Ahli Keluarga';

  @override
  String get deleteFamilyMember => 'Padam Ahli Keluarga';

  @override
  String get areYouSureDeleteFamilyMember =>
      'Adakah anda pasti mahu memadam ahli keluarga ini? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get familyMemberDeleted => 'Ahli keluarga dipadam';

  @override
  String failedToDeleteFamilyMember(String error) {
    return 'Gagal memadam: $error';
  }

  @override
  String failedToSaveFamilyMember(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get basicInfoSection => 'Maklumat Asas';

  @override
  String get contactIdSection => 'Hubungan & ID';

  @override
  String get addressSection => 'Alamat';

  @override
  String get addTask => 'Tambah Tugas';

  @override
  String get editTask => 'Edit Tugas';

  @override
  String get task => 'Tugas';

  @override
  String get deleteTask => 'Padam tugas?';

  @override
  String get thisActionCannotBeUndone => 'Tindakan ini tidak boleh dibatalkan.';

  @override
  String get deleteAllTasks => 'Padam semua tugas?';

  @override
  String get thisWillRemoveAllTasksPermanently =>
      'Ini akan membuang semua tugas secara kekal.';

  @override
  String get deleteAll => 'Padam semua';

  @override
  String get createYourChecklist => 'Cipta senarai semak anda';

  @override
  String get organiseYourAftercareTasks =>
      'Susun tugas penjagaan selepas anda dan pantau langkah penting.';

  @override
  String get whyUseAChecklist => 'Mengapa gunakan senarai semak?';

  @override
  String get structuredChecklistHelps =>
      'Senarai semak berstruktur membantu anda dan keluarga anda mengikuti tugas penting selepas kematian, langkah demi langkah.';

  @override
  String get startQuicklyWithRecommended =>
      'Mula dengan cepat dengan set tugas penjagaan selepas penting yang disyorkan.';

  @override
  String get addYourOwnCustomTasks =>
      'Tambah tugas tersuai anda sendiri yang sesuai dengan situasi dan budaya anda.';

  @override
  String get trackProgressSoNothingForgotten =>
      'Pantau kemajuan supaya tiada perkara penting yang dilupakan semasa masa sukar.';

  @override
  String get aboutChecklists => 'Mengenai senarai semak';

  @override
  String get defaultChecklistIncludes =>
      'Senarai semak lalai termasuk langkah penjagaan selepas penting seperti:\n\n• Memaklumkan ahli keluarga\n• Menguruskan akaun bank dan aset\n• Mengendalikan hal undang-undang dan dokumen\n• Menyusun barang peribadi\n• Mengemas kini penerima manfaat dan kenalan\n\nAnda juga boleh mencipta tugas tersuai khusus untuk keperluan anda.';

  @override
  String get gotIt => 'Faham';

  @override
  String get learnMoreAboutChecklists =>
      'Ketahui lebih lanjut tentang senarai semak';

  @override
  String get useDefaultChecklist => 'Gunakan senarai semak lalai';

  @override
  String get createCustomTask => 'Cipta tugas tersuai';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Nyahpin';

  @override
  String get getStartedTitle => 'Mula';

  @override
  String get completeYourProfile => 'Lengkapkan Profil Anda';

  @override
  String get setUpYourBasicInformation => 'Sediakan maklumat asas anda';

  @override
  String get addYourFirstFamilyMember => 'Tambah Ahli Keluarga Pertama Anda';

  @override
  String get addSomeoneImportantToYourWill =>
      'Tambah seseorang yang penting dalam wasiat anda';

  @override
  String get addYourFirstAsset => 'Tambah aset pertama anda';

  @override
  String get startTrackingYourDigitalAssets => 'Senaraikan aset digital anda';

  @override
  String get createYourWill => 'Cipta Wasiat Anda';

  @override
  String get createYourWillWithSampul => 'Cipta wasiat anda dengan Sampul';

  @override
  String get referralCode => 'Kod rujukan';

  @override
  String get addReferralCodeOptional => 'Tambah kod rujukan (pilihan)';

  @override
  String get haveReferralCode => 'Ada kod rujukan?';

  @override
  String get enterReferralCodeBelow =>
      'Masukkan kod rujukan anda di bawah untuk membuka kunci faedah';

  @override
  String get referralCodeLabel => 'Kod rujukan';

  @override
  String get codeLooksTooShort => 'Kod kelihatan terlalu pendek';

  @override
  String get clear => 'Kosongkan';

  @override
  String get apply => 'Guna';

  @override
  String get referralCodeApplied => 'Kod rujukan telah digunakan';

  @override
  String get setUpYourFamilyTrustAccount =>
      'Sediakan Akaun Amanah Keluarga Anda';

  @override
  String get createFamilyAccountForLongTermSupport =>
      'Cipta akaun keluarga untuk mengurus sokongan jangka panjang (pilihan).';

  @override
  String get pleaseCompleteAllStepsBeforeFinishing =>
      'Sila lengkapkan semua langkah sebelum selesai';

  @override
  String failedToCompleteOnboarding(String error) {
    return 'Gagal melengkapkan onboarding: $error';
  }

  @override
  String pleaseComplete(String nextTitle) {
    return 'Sila lengkapkan: $nextTitle';
  }

  @override
  String get completeSetup => 'Lengkapkan persediaan';

  @override
  String get theRemainingSteps => 'langkah yang tinggal';

  @override
  String get familyTrustFund => 'Amanah Keluarga';

  @override
  String get aboutFamilyTrustFund => 'Mengenai Amanah Keluarga';

  @override
  String get noTrustFundsYet => 'Tiada amanah keluarga lagi';

  @override
  String get createNew => 'Cipta Baru';

  @override
  String get createTrust => 'Cipta amanah';

  @override
  String get trustCodeUnique => 'Kod amanah (unik)';

  @override
  String get all => 'Semua';

  @override
  String get aboutTrustFund => 'Mengenai Amanah';

  @override
  String get newToTrusts => 'Baru kepada amanah?';

  @override
  String get learnMore => 'Ketahui lebih lanjut';

  @override
  String get startSettingUp => 'Mula menyediakan';

  @override
  String get whySetUpFamilyTrustFund =>
      'Apa yang Amanah Keluarga lakukan untuk anda';

  @override
  String get familyTrustFundDescription =>
      'Amanah Keluarga membolehkan anda memutuskan bagaimana wang anda menyokong keluarga anda—penjagaan kesihatan, pendidikan, perbelanjaan hidup. Anda boleh mengemas kininya bila-bila masa.';

  @override
  String get chooseHowMoneySpent =>
      'Anda memilih bagaimana dana digunakan—penjagaan kesihatan, pendidikan, derma dan lain-lain';

  @override
  String get changePlansAnytime => 'Kemas kini pelan anda bila-bila masa';

  @override
  String get familyKnowsExactly =>
      'Keluarga anda mempunyai panduan yang jelas apabila diperlukan';

  @override
  String get sampulPartnerWithRakyat =>
      'Sampul bekerjasama dengan Rakyat Trustee dan Halogen Capital untuk mengurus dana anda. ';

  @override
  String get learnMoreAboutPartners =>
      'Ketahui lebih lanjut tentang rakan kongsi kami';

  @override
  String get trustFundDetails => 'Butiran Amanah Keluarga';

  @override
  String get deleteTrustFund => 'Padam Amanah Keluarga';

  @override
  String get areYouSureDeleteTrustFund =>
      'Adakah anda pasti mahu memadam amanah keluarga ini? Tindakan ini tidak boleh dibatalkan.';

  @override
  String get trustFundDeleted => 'Amanah Keluarga dipadam';

  @override
  String failedToDeleteTrustFund(String error) {
    return 'Gagal memadam amanah keluarga: $error';
  }

  @override
  String get trustIdNotAvailable => 'ID Amanah tidak tersedia';

  @override
  String get trustIdCopiedToClipboard => 'ID Amanah disalin ke papan klip';

  @override
  String get beneficiaries => 'Penerima Manfaat';

  @override
  String get whoFundWillBeDistributedTo => 'Siapa yang akan menerima dana ini';

  @override
  String get pleaseSaveTrustFirst =>
      'Sila simpan amanah terlebih dahulu sebelum menambah penerima manfaat';

  @override
  String get beneficiaryAddedSuccessfully =>
      'Penerima manfaat berjaya ditambah';

  @override
  String failedToAddBeneficiary(String error) {
    return 'Gagal menambah penerima manfaat: $error';
  }

  @override
  String get beneficiaryUpdatedSuccessfully =>
      'Penerima manfaat berjaya dikemas kini';

  @override
  String failedToUpdateBeneficiary(String error) {
    return 'Gagal mengemas kini penerima manfaat: $error';
  }

  @override
  String get instructions => 'Arahan';

  @override
  String get allocateWhatTrustFundWillCover =>
      'Peruntukkan apa yang akan dilindungi oleh amanah keluarga ini';

  @override
  String get education => 'Pendidikan';

  @override
  String get livingExpenses => 'Perbelanjaan Hidup';

  @override
  String get healthcare => 'Penjagaan Kesihatan';

  @override
  String get charitable => 'Amal';

  @override
  String get debt => 'Hutang';

  @override
  String get tapToSetUp => 'Ketik untuk menyediakan';

  @override
  String get settingsSaved => 'Tetapan disimpan';

  @override
  String failedToSave(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get familyAccountCreated => 'Akaun keluarga dicipta';

  @override
  String get yourFamilyNowHasClearGuidance =>
      'Keluarga anda kini mempunyai panduan yang jelas, walaupun anda tidak berada di sekeliling untuk menerangkan.';

  @override
  String get whatHappensNow => 'Apa yang berlaku sekarang';

  @override
  String get familyAccountSavedAndFollowed =>
      'Akaun keluarga ini disimpan dan akan diikuti mengikut peraturan yang telah anda tetapkan.';

  @override
  String get nextSteps => 'Langkah seterusnya';

  @override
  String get youMayReceiveConfirmationEmail =>
      'Anda mungkin menerima e-mel pengesahan untuk rekod anda (jika didayakan).';

  @override
  String get youCanAlwaysReturnHere =>
      'Anda sentiasa boleh kembali ke sini untuk mengemas kini kategori atau jumlah.';

  @override
  String get viewInstructions => 'Lihat arahan';

  @override
  String get openTrust => 'Buka amanah';

  @override
  String get createTrustFund => 'Cipta Amanah Keluarga';

  @override
  String get weCouldNotLoadYourProfile =>
      'Kami tidak dapat memuatkan profil anda secara automatik. Sila isi butiran secara manual.';

  @override
  String get dismiss => 'TUTUP';

  @override
  String get fundSupport => 'Sokongan Dana';

  @override
  String get executorSelection => 'Pemilihan Pusaka';

  @override
  String get financialInformation => 'Maklumat Kewangan';

  @override
  String get employmentBusinessInformation => 'Maklumat Pekerjaan/Perniagaan';

  @override
  String get reviewSubmit => 'Semak & Hantar';

  @override
  String get livingExpensesSubtitle =>
      'Perumahan, makanan, utiliti, keperluan harian';

  @override
  String get healthcareSubtitle => 'Bil perubatan, rawatan';

  @override
  String get charitableSubtitle => 'Zakat, wakaf, sedekah, derma';

  @override
  String get debtSubtitle => 'Bayaran balik pinjaman, obligasi tertunggak';

  @override
  String get youCanSelectMoreThanOne =>
      'Anda boleh memilih lebih daripada satu. Anda boleh menukar ini pada bila-bila masa. Ini menetapkan peraturan. Dana bergerak hanya apabila syarat dipenuhi.';

  @override
  String get forLabel => 'Untuk';

  @override
  String untilTheyTurn(int age) {
    return 'Sehingga mereka berumur $age';
  }

  @override
  String get forTheirWholeLife => 'Sepanjang hayat mereka';

  @override
  String get everyMonth => 'setiap bulan';

  @override
  String get every3Months => 'setiap 3 bulan';

  @override
  String get everyYear => 'setiap tahun';

  @override
  String get whenConditionsAreMet => 'apabila syarat dipenuhi';

  @override
  String get whenNeeded => 'Apabila diperlukan';

  @override
  String get allAtOnceAtTheEnd => 'Semua sekaligus pada akhir';

  @override
  String get someoneIKnow => 'Seseorang yang Saya Kenali';

  @override
  String get familyMemberCloseFriendOrTrustedAdvisor =>
      'Ahli keluarga, rakan rapat, atau penasihat yang dipercayai';

  @override
  String get freeUsually => 'Percuma (biasanya)';

  @override
  String get basicReportingAndAnalytics => 'Laporan dan analitik asas';

  @override
  String get personalConflict => 'Konflik peribadi';

  @override
  String get administrativeBurden => 'Beban pentadbiran';

  @override
  String get whosThisFamilyTrustAccountFor =>
      'Akaun amanah keluarga ini untuk siapa?';

  @override
  String get noFamilyMembersFound =>
      'Tiada ahli keluarga dijumpai. Tambah ahli keluarga dalam profil anda.';

  @override
  String get sampulsProfessionalExecutor => 'Pusaka Profesional Sampul';

  @override
  String get expertManagement => 'Pengurusan pakar';

  @override
  String get neutralParty => 'Pihak neutral';

  @override
  String get estFeeR4320yr =>
      'Anggaran Yuran: RM4,320/tahun (Dibayar daripada dana amanah)';

  @override
  String get executorGoodToKnow =>
      'Pusaka anda bertindak sebagai perlindungan — bukan pembuat keputusan. Pilih seseorang yang teratur dan boleh dipercayai. Mereka mestilah sekurang-kurangnya berumur 21 tahun. Sekurang-kurangnya 2 Pusaka diperlukan apabila salah satu penerima manfaat adalah bawah umur. Jika salah satu penerima manfaat anda berumur di bawah 18 tahun, anda memerlukan sekurang-kurangnya dua Pusaka yang bekerjasama. Kami akan mengingatkan anda tentang perkara ini kemudian.';

  @override
  String get estimatedNetWorth => 'Anggaran Nilai Bersih';

  @override
  String get sourceOfFund => 'Sumber Dana';

  @override
  String get purposeOfTransaction => 'Tujuan Transaksi';

  @override
  String get employerName => 'Nama Majikan';

  @override
  String get businessNature => 'Sifat Perniagaan';

  @override
  String get businessAddressLine1 => 'Baris Alamat Perniagaan 1';

  @override
  String get businessAddressLine2 => 'Baris Alamat Perniagaan 2';

  @override
  String get accountFor => 'Akaun untuk';

  @override
  String get duration => 'Tempoh';

  @override
  String untilAge(int age) {
    return 'Sehingga umur $age';
  }

  @override
  String get theirEntireLifetime => 'Sepanjang hayat mereka';

  @override
  String get paymentType => 'Jenis Pembayaran';

  @override
  String get regularPayments => 'Pembayaran Tetap';

  @override
  String get amount => 'Jumlah';

  @override
  String get frequency => 'Kekerapan';

  @override
  String get monthly => 'Bulanan';

  @override
  String get quarterly => 'Suku Tahunan';

  @override
  String get yearly => 'Tahunan';

  @override
  String get whenConditions => 'Apabila syarat';

  @override
  String get asNeededTrusteeDecides =>
      'Mengikut keperluan (pemegang amanah memutuskan)';

  @override
  String get lumpSumAtTheEnd => 'Jumlah sekaligus pada akhir';

  @override
  String get executorType => 'Jenis Pusaka';

  @override
  String get selectedExecutors => 'Pusaka Terpilih';

  @override
  String familyMembersSelected(int count) {
    return '$count ahli keluarga dipilih';
  }

  @override
  String get businessInformation => 'Maklumat Perniagaan';

  @override
  String get employerCompanyName => 'Nama Majikan/Syarikat';

  @override
  String get natureOfBusiness => 'Sifat Perniagaan';

  @override
  String get businessAddress => 'Alamat Perniagaan';

  @override
  String charitiesDonations(int count) {
    return 'Amal/Derma ($count)';
  }

  @override
  String get pleaseSelectAtLeastOneFundSupport =>
      'Sila pilih sekurang-kurangnya satu kategori sokongan dana dan sediakan butirannya';

  @override
  String get pleaseSelectAtLeastOneExecutor =>
      'Sila pilih sekurang-kurangnya satu Pusaka';

  @override
  String get pleaseCompleteYourProfileFirst =>
      'Sila lengkapkan profil anda terlebih dahulu';

  @override
  String get trustFundCreatedSuccessfully => 'Amanah Keluarga berjaya dicipta';

  @override
  String failedToCreateTrustFund(String error) {
    return 'Gagal mencipta amanah keluarga: $error';
  }

  @override
  String charitiesSelected(int count) {
    return '$count badan amal dipilih';
  }

  @override
  String get charitySelected => '1 badan amal dipilih';

  @override
  String get pickOneMainPersonForCategory =>
      'Pilih satu orang utama untuk kategori ini. Anda masih boleh menyokong orang lain dalam kategori lain.';

  @override
  String get noFamilyMembersYet =>
      'Tiada ahli keluarga lagi.\nKetik \"Tambah Baru\" di bawah untuk menambah orang pertama untuk akaun ini.';

  @override
  String get addNew => 'Tambah Baru';

  @override
  String get saveYourChanges => 'Simpan perubahan anda?';

  @override
  String get youHaveUnsavedChanges =>
      'Anda mempunyai perubahan yang tidak disimpan pada halaman ini. Adakah anda ingin menyimpan persediaan ini sebelum anda kembali?';

  @override
  String get discardChanges => 'Buang perubahan';

  @override
  String get saveExit => 'Simpan & keluar';

  @override
  String get supportForTuitionFees =>
      'Sokongan untuk yuran tuisyen, buku, dan perbelanjaan pendidikan';

  @override
  String get coverDailyLivingExpenses =>
      'Melindungi perbelanjaan hidup harian dan keperluan asas';

  @override
  String get medicalExpensesTreatments =>
      'Perbelanjaan perubatan, rawatan, dan perkhidmatan penjagaan kesihatan';

  @override
  String get donationsContributions =>
      'Derma dan sumbangan kepada organisasi amal';

  @override
  String get paymentsOutstandingDebts =>
      'Pembayaran untuk hutang tertunggak dan obligasi kewangan';

  @override
  String get fundSupportConfiguration =>
      'Konfigurasi sokongan dana untuk amanah anda';

  @override
  String get requestPending => 'Permintaan Menunggu';

  @override
  String get paused => 'Dijeda';

  @override
  String get totalDonations => 'Jumlah Derma';

  @override
  String get noCharitiesDonationsAddedYet => 'Tiada amal/derma ditambah lagi';

  @override
  String get addCharitableOrganizations =>
      'Tambah organisasi amal untuk mula membuat perbezaan';

  @override
  String get unnamedOrganization => 'Organisasi Tanpa Nama';

  @override
  String get donationAmount => 'Jumlah Derma';

  @override
  String get annualTotal => 'Jumlah Tahunan';

  @override
  String get monthlyAverage => 'Purata Bulanan';

  @override
  String get na => 'T/A';

  @override
  String get supportDuration => 'Tempoh Sokongan';

  @override
  String endsInYear(int year, int years) {
    return 'Berakhir pada Tahun $year ($years tahun dari sekarang)';
  }

  @override
  String get continuousSupportLifetime =>
      'Sokongan berterusan sepanjang hayat mereka';

  @override
  String get paymentMethod => 'Kaedah Pembayaran';

  @override
  String get asNeeded => 'Mengikut Keperluan';

  @override
  String get trusteeDecidesRelease =>
      'Pemegang amanah memutuskan bila untuk melepaskan dana berdasarkan tujuan yang diluluskan';

  @override
  String get lumpSum => 'Jumlah Sekaligus';

  @override
  String get allFundsReleasedEnd =>
      'Semua dana dilepaskan apabila tempoh amanah berakhir';

  @override
  String get cancelRequest => 'Batal Permintaan';

  @override
  String get requestFund => 'Minta Dana';

  @override
  String get areYouSureRequestFunds =>
      'Adakah anda pasti mahu meminta dana? Ini akan memberitahu pemegang amanah anda untuk memproses permintaan dana.';

  @override
  String get fundRequestSubmittedSuccessfully =>
      'Permintaan dana berjaya dihantar';

  @override
  String get areYouSureCancelRequest =>
      'Adakah anda pasti mahu membatalkan permintaan dana ini?';

  @override
  String get noKeepIt => 'Tidak, Simpan';

  @override
  String get fundRequestCancelledSuccessfully =>
      'Permintaan dana berjaya dibatalkan';

  @override
  String get resumeInstruction => 'Sambung Semula Arahan';

  @override
  String get pauseInstruction => 'Jeda Arahan';

  @override
  String areYouSureResumeInstruction(String category) {
    return 'Adakah anda pasti mahu menyambung semula arahan $category? Pembayaran akan diteruskan mengikut jadual.';
  }

  @override
  String areYouSurePauseInstruction(String category) {
    return 'Adakah anda pasti mahu menjeda arahan $category? Ini akan menghentikan sementara semua pembayaran sehingga anda menyambung semula.';
  }

  @override
  String get resume => 'Sambung Semula';

  @override
  String get pause => 'Jeda';

  @override
  String instructionResumedSuccessfully(String category) {
    return 'Arahan $category berjaya disambung semula';
  }

  @override
  String instructionPausedSuccessfully(String category) {
    return 'Arahan $category berjaya dijeda';
  }

  @override
  String get howLongShouldThisLast => 'Berapa lama ini harus bertahan?';

  @override
  String get untilSpecificAge => 'Sehingga umur tertentu';

  @override
  String get age => 'Umur';

  @override
  String thatsYearsFromNow(int years, int year) {
    return 'Itu $years tahun dari sekarang (Tahun $year)';
  }

  @override
  String get paymentConfiguration => 'Konfigurasi Pembayaran';

  @override
  String get howOftenContribution =>
      'Berapa kerap sumbangan ini harus dijalankan?';

  @override
  String get yourTrusteeReleasesMoney =>
      'Pemegang amanah anda melepaskan wang apabila diperlukan untuk tujuan yang diluluskan';

  @override
  String get everythingReleasedEnd =>
      'Semuanya dilepaskan apabila tempoh amanah berakhir';

  @override
  String get thisIsAGuide =>
      'Ini adalah panduan. Pusaka anda boleh menyesuaikan berdasarkan keperluan sebenar.';

  @override
  String get addCharitableOrganizationsDonate =>
      'Tambah organisasi amal yang anda ingin dermakan';

  @override
  String get addCharity => 'Tambah Amal/Derma';

  @override
  String get updatePassword => 'Kemas Kini Kata Laluan';

  @override
  String get setYourNewPassword => 'Tetapkan kata laluan baru anda';

  @override
  String get enterNewPasswordBelow =>
      'Masukkan kata laluan baru anda di bawah untuk melengkapkan proses tetapan semula.';

  @override
  String get passwordUpdatedSuccessfully => 'Kata laluan berjaya dikemas kini!';

  @override
  String failedToUpdatePasswordWithError(String error) {
    return 'Gagal mengemas kini kata laluan: $error';
  }

  @override
  String get forgotPasswordTitle => 'Lupa kata laluan';

  @override
  String get enterEmailForResetLink =>
      'Masukkan e-mel anda dan kami akan hantar pautan tetapan semula.';

  @override
  String get sendResetLink => 'Hantar pautan tetapan semula';

  @override
  String get passwordResetEmailSent =>
      'E-mel tetapan semula kata laluan dihantar! Sila semak e-mel anda.';

  @override
  String failedToSendResetEmail(String error) {
    return 'Gagal menghantar e-mel tetapan semula: $error';
  }

  @override
  String get resetLinkExpired => 'Pautan tetapan semula tamat tempoh';

  @override
  String get resetLinkExpiredDescription =>
      'Pautan tetapan semula kata laluan ini telah tamat tempoh atau telah digunakan. Sila minta pautan tetapan semula yang baru.';

  @override
  String get backToLogin => 'Kembali ke log masuk';

  @override
  String get whatWouldYouLikeToOrganise =>
      'Apa yang anda ingin uruskan hari ini?';

  @override
  String get chooseWhatToTakeCareFirst =>
      'Pilih apa yang anda ingin uruskan dahulu.';

  @override
  String get openFamilyAccount => 'Buka Akaun Keluarga';

  @override
  String get openFamilyAccountDescription =>
      'Susun keluarga, aset, dan arahan anda di satu tempat.';

  @override
  String get protectProperty => 'Lindungi Hartanah';

  @override
  String get protectPropertyDescription =>
      'Sediakan arahan untuk melindungi hartanah anda.';

  @override
  String get managePusaka => 'Urus Pusaka';

  @override
  String get managePusakaDescription =>
      'Panduan untuk menguruskan hal-hal pusaka.';

  @override
  String get writeWasiat => 'Tulis Wasiat';

  @override
  String get writeWasiatDescription =>
      'Dokumentasikan bagaimana aset anda harus diagihkan.';

  @override
  String get getGuidanceTitle => 'Dapatkan panduan';

  @override
  String get getGuidanceDescription =>
      'Tanya Sampul AI atau bercakap dengan perunding profesional.';

  @override
  String get notSureWhereToStart => 'Tidak pasti dari mana nak mula?';

  @override
  String get notSureDescription =>
      'Kami akan membimbing anda melalui beberapa soalan mudah.';

  @override
  String get setUpPropertyTrustHibah => 'Sediakan Amanah Hartanah';

  @override
  String get setUpHibahInstructionsForProperty =>
      'Lindungi hartanah anda dengan amanah';

  @override
  String get setUpExecution => 'Sediakan Pusaka';

  @override
  String get setUpExecutionDescription =>
      'Lantik seseorang untuk menguruskan harta pusaka anda';

  @override
  String get readyForGuidance => 'Sedia untuk panduan!';

  @override
  String get profileSetUpChatReady =>
      'Profil anda telah ditetapkan. Anda kini boleh berbual dengan Sampul AI atau bercakap dengan perunding profesional.';

  @override
  String get chatWithSampulAI => 'Berbual dengan Sampul AI';

  @override
  String get sampulAIDescription =>
      'Dapatkan panduan peribadi dari pembantu Sampul AI';

  @override
  String get setUpAftercare => 'Tetapkan Penjagaan Selepas';

  @override
  String get aftercareDescription =>
      'Teroka sumber sokongan dan perkhidmatan pasukan penjagaan';

  @override
  String get completeStepsFamilyAccount =>
      'Lengkapkan langkah-langkah ini untuk menyediakan akaun keluarga anda.';

  @override
  String get completeStepsProtectProperty =>
      'Lengkapkan langkah-langkah ini untuk melindungi hartanah anda.';

  @override
  String get completeStepsManagePusaka =>
      'Lengkapkan langkah-langkah ini untuk menguruskan hal pusaka anda.';

  @override
  String get completeStepsWriteWasiat =>
      'Lengkapkan langkah-langkah ini untuk mencipta wasiat anda.';

  @override
  String get completeStepsGetGuidance =>
      'Lengkapkan langkah ini untuk mendapatkan panduan peribadi.';

  @override
  String get completeStepsNotSure =>
      'Lengkapkan langkah-langkah ini untuk menyediakan akaun Sampul anda.';

  @override
  String get accountSetup => 'Persediaan Akaun';

  @override
  String continueWithFeature(String feature) {
    return 'Teruskan dengan $feature';
  }

  @override
  String get profile => 'Profil';

  @override
  String get propertyTrust => 'Amanah Hartanah';
}
