import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/providers/wallet_provider.dart';
import 'package:smartlearn/models/transaction_model.dart';
import 'package:smartlearn/screens/user/creators_screen.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWallet();
    });
  }

  Future<void> _loadWallet() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await walletProvider.loadWallet(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (authProvider.currentUser != null) {
                walletProvider.refreshBalance(
                  authProvider.currentUser!.uid,
                  authProvider,
                );
              }
            },
          ),
        ],
      ),
      body: walletProvider.isLoading
          ? Center(child: LottieAnimations.showLoading(width: 200, height: 200))
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Balance Card (Algorand "Creator Coins")
                    // Use AuthProvider balance as primary source
                    _buildCreatorCoinsCard(
                      authProvider.currentUser?.balance != null
                          ? (authProvider.currentUser!.balance *
                                    AppConstants.coinsPerAlgo)
                                .toInt()
                          : walletProvider.balance,
                    ),
                    const SizedBox(height: 16),

                    // Support Creators button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreatorsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.favorite),
                        label: const Text('View Social Feed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /* 
                    // Hide Legacy "Earn" & "Spend" sections until on-chain implementation is ready
                    
                    // Premium Upgrade Card (if not premium)
                    if (authProvider.currentUser?.isPremium != true) ...[
                      _buildPremiumCard(),
                       const SizedBox(height: 24),
                    ],

                    // Earn Points Section
                    _buildEarnPointsSection(),
                    const SizedBox(height: 24),
                    */

                    // Transaction History (Legacy for now)
                    if (walletProvider.transactions.isNotEmpty)
                      _buildTransactionHistory(walletProvider.transactions),
                  ],
                ),
              ),
            ),
    );
  }

  /// Card showing on-chain balance as "Creator Coins"
  Widget _buildCreatorCoinsCard(int balance) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Creator Coins',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blueAccent,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Text(
                  '$balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Coins',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<TransactionModel> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(transaction.icon, style: const TextStyle(fontSize: 24)),
        title: Text(transaction.description),
        subtitle: Text(dateFormat.format(transaction.timestamp)),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: transaction.isEarning ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
