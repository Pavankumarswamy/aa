import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/services/api_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';

class TipBottomSheet extends StatefulWidget {
  final String creatorId; // For analytics/logging if needed
  final String toAddress; // Algorand address
  final String creatorName;
  final Function(double amount)? onTipSent;

  const TipBottomSheet({
    super.key,
    required this.creatorId,
    required this.toAddress,
    required this.creatorName,
    this.onTipSent,
  });

  @override
  State<TipBottomSheet> createState() => _TipBottomSheetState();
}

class _TipBottomSheetState extends State<TipBottomSheet> {
  double _tipAmount = 10;
  bool _isLoading = false;

  Future<void> _processTip() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;

    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to tip.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (widget.toAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creator wallet address missing. Cannot tip.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Optimistic Update: Subtract immediately for perceived speed
    final originalBalance = authProvider.currentUser?.balance ?? 0.0;
    final tipAmountAlgo = _tipAmount / AppConstants.coinsPerAlgo;
    authProvider.updateBalance(originalBalance - tipAmountAlgo);

    try {
      // Process Tip directly - let backend handle balance check
      final result = await ApiService.tipCreator(
        fromUserId: currentUserId,
        toAddress: widget.toAddress,
        amount: tipAmountAlgo,
      );

      if (mounted) {
        // Update AuthProvider balance with final server value on success
        if (result['newBalance'] != null) {
          authProvider.updateBalance((result['newBalance'] as num).toDouble());
        }

        widget.onTipSent?.call(tipAmountAlgo);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${_tipAmount.toInt()} coins to ${widget.creatorName}!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on failure
      authProvider.updateBalance(originalBalance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tip ${widget.creatorName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LottieAnimations.showCoins(width: 50, height: 50),
              const SizedBox(width: 8),
              Text(
                '${_tipAmount.toInt()}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Slider(
            value: _tipAmount,
            min: 10,
            max: 100,
            divisions: 9, // 10, 20... 100
            label: _tipAmount.round().toString(),
            activeColor: Colors.amber,
            onChanged: (val) => setState(() => _tipAmount = val),
          ),
          const SizedBox(height: 24),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final balanceCoins =
                  (auth.currentUser?.balance ?? 0.0) *
                  AppConstants.coinsPerAlgo;
              return Text(
                'Your Balance: ${balanceCoins.toInt()} Coins',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processTip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Tip'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
