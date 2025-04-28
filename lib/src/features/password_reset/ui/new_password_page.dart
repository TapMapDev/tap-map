import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_event.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_state.dart';
import 'package:tap_map/src/widget/custom_elevated_button.dart';

class NewPasswordPage extends StatefulWidget {
  final String? uid;
  final String? token;

  const NewPasswordPage({super.key, this.uid, this.token});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();
  bool showPassword = true;
  bool showRepeatPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔗 NewPasswordPage initialized with:');
      print(
          'Current route: ${GoRouter.of(context).routeInformationProvider.value.location}');
      print('UID: ${widget.uid}');
      print('Token: ${widget.token}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
          listener: (context, state) {
            print('🔄 Current state: ${state.runtimeType}');

            if (state is SetNewPassworduccess) {
              print('✅ Password reset success, navigating to authorization');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Пароль успешно изменён! 🎉'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              Future.delayed(const Duration(seconds: 2), () {
                print('🔄 Executing navigation to authorization');
                context.go(AppRoutes.authorization);
              });
            } else if (state is SetNewPasswordError) {
              print('❌ Password reset error: ${state.error}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'Не удалось изменить пароль'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                TextField(
                  controller: passwordController,
                  obscureText: showPassword,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    hintText: 'Минимум 8 символов',
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: repeatPasswordController,
                  obscureText: showRepeatPassword,
                  decoration: InputDecoration(
                    labelText: 'Повторите пароль',
                    suffixIcon: IconButton(
                      icon: Icon(showRepeatPassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () {
                        setState(
                            () => showRepeatPassword = !showRepeatPassword);
                      },
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomElevatedButton(
                        text: 'Отмена',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomElevatedButton(
                        text: 'Сохранить',
                        onPressed: _submitNewPassword,
                      ),
                    ),
                  ],
                ),
                if (state is SetNewPasswordInProgress)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submitNewPassword() {
    final password = passwordController.text;
    final repeat = repeatPasswordController.text;

    print('🔐 Submitting new password:');
    print('UID from widget: ${widget.uid}');
    print('Token from widget: ${widget.token}');

    if (password != repeat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароли не совпадают'),
        ),
      );
      return;
    }

    // Проверяем наличие uid и token
    if (widget.uid == null || widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка: отсутствуют параметры для сброса пароля'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Минимальная длина пароля
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Пароль должен содержать минимум 8 символов',
          ),
        ),
      );
      return;
    }
    context.read<ResetPasswordBloc>().add(
          SetNewPassword(
            uid: widget.uid,
            token: widget.token,
            newPassword: password,
          ),
        );
  }
}
