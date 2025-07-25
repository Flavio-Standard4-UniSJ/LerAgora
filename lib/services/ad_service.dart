// 📁 lib/services/ad_service.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static InterstitialAd? _interstitialAd;

  /// Inicializa o Google Mobile Ads
  static Future<void> initializeAdMob() async {
    await MobileAds.instance.initialize();
  }

  /// Carrega um anúncio intersticial
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7484139098650501/3832489058',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          print('❌ Falha ao carregar interstitial: $error');
        },
      ),
    );
  }

  /// Exibe o anúncio intersticial, depois chama [onAdComplete]
  static Future<void> showInterstitialAd(Function onAdComplete) async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // pré-carrega outro
          onAdComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          onAdComplete(); // continua mesmo com erro
        },
      );

      await _interstitialAd!.show();
    } else {
      onAdComplete(); // Sem anúncio, prossegue
    }
  }
}
