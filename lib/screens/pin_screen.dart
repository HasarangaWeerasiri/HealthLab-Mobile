import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum PinMode {
  create,
  confirm,
  verify,
  remove,
}

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final String? title;
  final String? subtitle;
  final String? initialPin; // For confirm mode
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PinScreen({
    super.key,
    required this.mode,
    this.title,
    this.subtitle,
    this.initialPin,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  List<String> _enteredPin = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _attempts = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  void _resetState() {
    setState(() {
      _enteredPin.clear();
      _isLoading = false;
      _errorMessage = null;
    });
  }

  String get _title {
    if (widget.title != null) return widget.title!;
    
    switch (widget.mode) {
      case PinMode.create:
        return 'Create PIN';
      case PinMode.confirm:
        return 'Confirm PIN';
      case PinMode.verify:
        return 'Enter PIN';
      case PinMode.remove:
        return 'Remove PIN';
    }
  }

  String get _subtitle {
    if (widget.subtitle != null) return widget.subtitle!;
    
    switch (widget.mode) {
      case PinMode.create:
        return 'Enter a 4-digit PIN for secure access';
      case PinMode.confirm:
        return 'Re-enter your PIN to confirm';
      case PinMode.verify:
        return 'Enter your PIN to continue';
      case PinMode.remove:
        return 'Enter your current PIN to remove it';
    }
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < 4 && !_isLoading) {
      setState(() {
        _enteredPin.add(digit);
        _errorMessage = null;
      });

      // Auto-submit when 4 digits are entered
      if (_enteredPin.length == 4) {
        _submitPin();
      }
    }
  }

  void _removeDigit() {
    if (_enteredPin.isNotEmpty && !_isLoading) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = null;
      });
    }
  }

  Future<void> _submitPin() async {
    if (_enteredPin.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      final pin = _enteredPin.join();

      switch (widget.mode) {
        case PinMode.create:
          await authService.setPin(pin);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            Navigator.of(context).pop(true);
          }
          break;

        case PinMode.confirm:
          if (pin == widget.initialPin) {
            await authService.setPin(pin);
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pop(true);
            }
          } else {
            _showError('PINs do not match. Please try again.');
          }
          break;

        case PinMode.verify:
          final isValid = await authService.verifyPin(pin);
          if (isValid) {
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pop(true);
            }
          } else {
            _handleFailedAttempt();
          }
          break;

        case PinMode.remove:
          final isValid = await authService.verifyPin(pin);
          if (isValid) {
            await authService.removePin();
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              Navigator.of(context).pop(true);
            }
          } else {
            _handleFailedAttempt();
          }
          break;
      }
    } catch (e) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleFailedAttempt() {
    _attempts++;
    if (_attempts >= _maxAttempts) {
      _showError('Too many failed attempts. Please try again later.');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      });
    } else {
      _showError('Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _enteredPin.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00432D),
        title: Text(
          _title,
          style: const TextStyle(
            color: Color(0xFFE6FDD8),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE6FDD8)),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Title and Subtitle
              Text(
                _title,
                style: const TextStyle(
                  color: Color(0xFFE6FDD8),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _subtitle,
                style: TextStyle(
                  color: const Color(0xFFE6FDD8).withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _enteredPin.length
                            ? const Color(0xFFE6FDD8)
                            : const Color(0xFFE6FDD8).withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Spacer(),

              // Loading Indicator
              if (_isLoading) ...[
                const CircularProgressIndicator(
                  color: Color(0xFFE6FDD8),
                ),
                const SizedBox(height: 20),
              ],

              // Numeric Keypad
              _buildKeypad(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00432D).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 16),
          
          // Row 2: 4, 5, 6
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 16),
          
          // Row 3: 7, 8, 9
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 16),
          
          // Row 4: Empty, 0, Backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80), // Empty space
              _buildKeypadButton('0'),
              _buildKeypadButton(
                '',
                icon: Icons.backspace_outlined,
                onTap: _removeDigit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildKeypadButton(number)).toList(),
    );
  }

  Widget _buildKeypadButton(
    String number, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => _addDigit(number),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF00432D),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFE6FDD8).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: const Color(0xFFE6FDD8),
                  size: 24,
                )
              : Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFFE6FDD8),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
