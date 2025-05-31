import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visca/providers/user_provider.dart';

class UserState {
  final String fullName;
  final String email;

  UserState({required this.fullName, required this.email});
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3C7D7E), Color(0xFFA9D5C5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                  ),
                ),
              ),
    
              Positioned(
                top: 110,
                left: MediaQuery.of(context).size.width / 2 - 45,
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFF3C7D7E),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Display Name & Email
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LabelText(text: 'Name'),
                InfoCard(text: userState.user!.fullName),
                const SizedBox(height: 16),
                const LabelText(text: 'Email'),
                InfoCard(text: userState.user!.email),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LabelText extends StatelessWidget {
  final String text;
  const LabelText({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  const InfoCard({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
