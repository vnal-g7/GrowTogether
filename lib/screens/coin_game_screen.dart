import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/coin_game_result.dart';
import '../services/coin_game_service.dart';

class CoinGameScreen extends StatefulWidget {
  const CoinGameScreen({super.key});

  @override
  State<CoinGameScreen> createState() => _CoinGameScreenState();
}

class _CoinGameScreenState extends State<CoinGameScreen>
    with SingleTickerProviderStateMixin {
  final CoinGameService _coinGameService = CoinGameService();
  final Random _random = Random();

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isPlaying = false;
  String _rollingText = 'Tap play and test your luck';
  CoinGameResult? _lastResult;
  String? _errorMessage;
  int _displayIconIndex = 0;

  static const List<IconData> _rollingIcons = [
    Icons.casino,
    Icons.stars,
    Icons.monetization_on,
    Icons.auto_awesome,
    Icons.local_fire_department,
  ];

  static const List<String> _rollingMessages = [
    'Rolling your luck...',
    'Checking the reward pool...',
    'Spinning the outcome...',
    'Maybe big win... maybe pain...',
    'Let the coins decide...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _lastResult = null;
      _errorMessage = null;
      _rollingText = _rollingMessages[0];
      _displayIconIndex = 0;
    });

    Timer? rollingTimer;

    try {
      int tick = 0;

      rollingTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
        if (!mounted) return;

        setState(() {
          _displayIconIndex = (_displayIconIndex + 1) % _rollingIcons.length;
          _rollingText = _rollingMessages[tick % _rollingMessages.length];
        });

        tick++;
      });

      await Future.delayed(const Duration(seconds: 2));

      final CoinGameResult result = await _coinGameService.playGame();

      await Future.delayed(const Duration(milliseconds: 500));

      rollingTimer.cancel();

      if (!mounted) return;

      setState(() {
        _lastResult = result;
        _rollingText = _buildResultHeadline(result);
      });
    } catch (e) {
      rollingTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _rollingText = 'That did not go well';
      });
    } finally {
      rollingTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _isPlaying = false;
      });
    }
  }

  String _buildResultHeadline(CoinGameResult result) {
    if (result.coinChange > 0) {
      if (result.coinChange >= 50) {
        return 'Massive win';
      }
      return 'Nice hit';
    }

    if (result.coinChange == 0) {
      return 'Neutral result';
    }

    return 'You lost coins';
  }

  Color _resultAccentColor(BuildContext context) {
    if (_errorMessage != null) {
      return Colors.red;
    }

    if (_lastResult == null) {
      return Colors.orange;
    }

    if (_lastResult!.coinChange > 0) {
      return Colors.green;
    }

    if (_lastResult!.coinChange == 0) {
      return Colors.blueGrey;
    }

    return Colors.red;
  }

  IconData _resultIcon() {
    if (_isPlaying) {
      return _rollingIcons[_displayIconIndex];
    }

    if (_errorMessage != null) {
      return Icons.error_outline;
    }

    if (_lastResult == null) {
      return Icons.casino;
    }

    if (_lastResult!.coinChange > 0) {
      return _lastResult!.coinChange >= 50
          ? Icons.workspace_premium
          : Icons.emoji_events;
    }

    if (_lastResult!.coinChange == 0) {
      return Icons.remove_circle_outline;
    }

    return Icons.sentiment_dissatisfied;
  }

  String _resultBodyText() {
    if (_isPlaying) {
      return _rollingText;
    }

    if (_errorMessage != null) {
      return _errorMessage!;
    }

    if (_lastResult == null) {
      return 'Spend coins for a random reward. No real money. No cash-out. Just risk and reward inside the app.';
    }

    final coinText =
        '${_lastResult!.coinChange >= 0 ? '+' : ''}${_lastResult!.coinChange} coins';
    final xpText =
        '${_lastResult!.xpChange >= 0 ? '+' : ''}${_lastResult!.xpChange} XP';

    return '${_lastResult!.label}\n$coinText\n$xpText';
  }

  Widget _buildTopCard(BuildContext context, bool isDark) {
    final Color accent = _resultAccentColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(0.22),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = _isPlaying ? _pulseAnimation.value : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                  ),
                  child: Icon(
                    _resultIcon(),
                    size: 48,
                    color: accent,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _rollingText,
              key: ValueKey(_rollingText),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1D2747),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _resultBodyText(),
              key: ValueKey(_resultBodyText()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.blueGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1D2747),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(double.infinity, 64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: _isPlaying ? null : _play,
      child: _isPlaying
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'ROLLING...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'PLAY LUCKY REWARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOutcomeHints(bool isDark) {
    final hints = [
      {'label': 'Bad roll', 'text': 'Lose your entry cost', 'color': Colors.red},
      {
        'label': 'Decent roll',
        'text': 'Small coin or XP gain',
        'color': Colors.orange,
      },
      {
        'label': 'Strong roll',
        'text': 'Bigger reward payout',
        'color': Colors.green,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Possible outcome vibe',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF1D2747),
            ),
          ),
          const SizedBox(height: 14),
          ...hints.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: item['color'] as Color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item['label']} — ${item['text']}',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucky Reward'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _buildTopCard(context, isDark),
                const SizedBox(height: 18),
                _buildInfoCard(
                  isDark: isDark,
                  icon: Icons.monetization_on,
                  title: 'Entry cost',
                  subtitle: 'Each play spends 20 coins. No freebies.',
                  color: Colors.orange,
                ),
                const SizedBox(height: 14),
                _buildInfoCard(
                  isDark: isDark,
                  icon: Icons.shield_outlined,
                  title: 'Safe design',
                  subtitle:
                      'No real money, no cash-out, and no purchases tied to this mechanic.',
                  color: Colors.blue,
                ),
                const SizedBox(height: 14),
                _buildInfoCard(
                  isDark: isDark,
                  icon: Icons.timer_outlined,
                  title: 'Limits matter',
                  subtitle:
                      'Daily limits stop this from becoming an abuse machine.',
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 18),
                _buildOutcomeHints(isDark),
                const SizedBox(height: 24),
                _buildPlayButton(),
                const SizedBox(height: 16),
                const Text(
                  'Win some, lose some. That is the whole point.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}