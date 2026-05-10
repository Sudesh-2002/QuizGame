import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/ad_constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;

  // ── Initialize ───────────────────────────────────────────────
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // ── Interstitial Ad ──────────────────────────────────────────
  void loadInterstitialAd() {
    // Prevent multiple simultaneous load requests
    if (_interstitialLoading || _isInterstitialReady) return;
    _interstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdConstants.interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialLoading = false;
          debugPrint('✅ Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialReady = false;
          _interstitialLoading = false;
          debugPrint('❌ Interstitial failed: ${error.message}');
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (!_isInterstitialReady || _interstitialAd == null) {
      debugPrint('⚠️ Interstitial not ready');
      onDismissed?.call();
      loadInterstitialAd(); // try to load for next time
      return;
    }

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Interstitial showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Interstitial dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        onDismissed?.call();
        loadInterstitialAd(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Interstitial show failed: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
        onDismissed?.call();
        loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // ── Rewarded Ad ──────────────────────────────────────────────
  void loadRewardedAd() {
    // Prevent multiple simultaneous load requests
    if (_rewardedLoading || _isRewardedReady) return;
    _rewardedLoading = true;

    RewardedAd.load(
      adUnitId: AdConstants.rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _rewardedLoading = false;
          debugPrint('✅ Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedReady = false;
          _rewardedLoading = false;
          debugPrint('❌ Rewarded failed: ${error.message}');
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onDismissed,
  }) {
    if (!_isRewardedReady || _rewardedAd == null) {
      debugPrint('⚠️ Rewarded ad not ready');
      onDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Rewarded ad showing');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('✅ Rewarded dismissed');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        onDismissed?.call();
        loadRewardedAd(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Rewarded show failed: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
        onDismissed?.call();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎉 Reward earned: ${reward.amount}');
        onRewarded();
      },
    );
  }

  // ── Getters ──────────────────────────────────────────────────
  bool get isRewardedReady => _isRewardedReady;
  bool get isInterstitialReady => _isInterstitialReady;

  // ── Dispose ──────────────────────────────────────────────────
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
    _interstitialLoading = false;
    _rewardedLoading = false;
  }
}