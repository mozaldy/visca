import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visca/screens/main_screen.dart';
import '../providers/user_provider.dart';
import '../components/bottom_waves.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final userNotifier = ref.read(userProvider.notifier);
      final bool success = await userNotifier.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );
      debugPrint("Sampek sini 1");
      if (success && mounted) {
        debugPrint("Sampek sini 2");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: Stack(
        children: [
          // wave 1
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: ClipPath(
                clipper: BottomWaveClipper1(),
                child: Container(
                  height: 150,
                  color: Color.fromARGB(255, 134, 185, 176),
                ),
              ),
            ),
          ),

          // wave 2
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: ClipPath(
                clipper: BottomWaveClipper2(),
                child: Container(
                  height: 150,
                  color: Color.fromARGB(255, 76, 114, 115),
                ),
              ),
            ),
          ),

          // wave 3
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.5,
              child: ClipPath(
                clipper: BottomWaveClipper3(),
                child: Container(
                  height: 150,
                  color: Color.fromARGB(255, 1, 49, 60),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'VISCA - Register',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      _buildInputField(
                        _fullNameController,
                        'Full Name',
                        Icons.person,
                      ),
                      const SizedBox(height: 20.0),
                      _buildInputField(_emailController, 'Email', Icons.email),
                      const SizedBox(height: 20.0),
                      _buildInputField(
                        _passwordController,
                        'Password',
                        Icons.lock,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20.0),
                      _buildInputField(
                        _confirmPasswordController,
                        'Confirm Password',
                        Icons.lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(height: 20.0),
                      if (userState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Registrasi gagal. Coba lagi.",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),

                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: userState.isLoading ? null : _register,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            height: 50,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child:
                                userState.isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                      ),
                                    ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20.0),
                      TextButton(
                        onPressed: () {
                          ref.read(userProvider.notifier).clearError();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (label == 'Email' &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        if ((label == 'Password' || label == 'Confirm Password') &&
            value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (label == 'Confirm Password' && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
