import 'package:flutter/material.dart';
import 'package:battery_optimization_helper/battery_optimization_helper.dart';
import '../../data/services/vpn_service.dart';
import 'main_navigation.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _vpnService = VpnService();
  bool _isVpnActive = false;
  bool _isBatteryOptimized = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final vpnStatus = await _vpnService.getStatus();
    final batteryStatus = await BatteryOptimizationHelper.isBatteryOptimizationEnabled();
    if (mounted) {
      setState(() {
        _isVpnActive = vpnStatus;
        _isBatteryOptimized = batteryStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _activateVpn() async {
    await _vpnService.startVpn();
    _checkStatus();
  }

  Future<void> _disableBatteryOptimization() async {
    await BatteryOptimizationHelper.requestDisableBatteryOptimization();
    _checkStatus();
  }

  void _proceed() {
    if (_isVpnActive) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please activate the VPN to continue.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1C),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Setup Protection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Complete these steps to secure your device.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),

              _buildSetupCard(
                title: 'Activate VPN',
                description: 'Required to intercept and filter traffic locally.',
                isDone: _isVpnActive,
                onTap: _activateVpn,
              ),
              const SizedBox(height: 16),

              _buildSetupCard(
                title: 'Disable Battery Optimization',
                description: 'Prevents the system from killing the VPN service.',
                isDone: !_isBatteryOptimized,
                onTap: _disableBatteryOptimization,
                isWarning: _isVpnActive && _isBatteryOptimized,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVpnActive ? _proceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ENTER DASHBOARD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupCard({
    required String title,
    required String description,
    required bool isDone,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    final borderColor = isDone
        ? Colors.cyanAccent.withOpacity(0.5)
        : (isWarning ? Colors.orangeAccent : Colors.white24);

    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.cyanAccent : Colors.white38,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!isDone)
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
