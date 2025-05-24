import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final loginFormProvider = StateNotifierProvider<LoginFormNotifier, LoginFormState>((ref) {
  return LoginFormNotifier();
});

// State class for the login form
class LoginFormState {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool emailFocused;
  final bool passwordFocused;

  LoginFormState({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    this.emailFocused = false,
    this.passwordFocused = false,
  });

  LoginFormState copyWith({
    bool? emailFocused,
    bool? passwordFocused,
  }) {
    return LoginFormState(
      emailController: emailController,
      passwordController: passwordController,
      emailFocusNode: emailFocusNode,
      passwordFocusNode: passwordFocusNode,
      emailFocused: emailFocused ?? this.emailFocused,
      passwordFocused: passwordFocused ?? this.passwordFocused,
    );
  }
}

// Notifier for managing login form state
class LoginFormNotifier extends StateNotifier<LoginFormState> {
  LoginFormNotifier()
      : super(
          LoginFormState(
            emailController: TextEditingController(),
            passwordController: TextEditingController(),
            emailFocusNode: FocusNode(),
            passwordFocusNode: FocusNode(),
          ),
        ) {
    // Add listeners to focus nodes
    state.emailFocusNode.addListener(() {
      state = state.copyWith(emailFocused: state.emailFocusNode.hasFocus);
    });
    state.passwordFocusNode.addListener(() {
      state = state.copyWith(passwordFocused: state.passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    state.emailController.dispose();
    state.passwordController.dispose();
    state.emailFocusNode.dispose();
    state.passwordFocusNode.dispose();
    super.dispose();
  }
}
