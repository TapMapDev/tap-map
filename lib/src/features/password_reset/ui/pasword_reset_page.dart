import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_event.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_state.dart';
import 'package:tap_map/src/widget/custom_elevated_button.dart';

class PasswordRequestPage extends StatefulWidget {
  const PasswordRequestPage({super.key});

  @override
  State<PasswordRequestPage> createState() => _PasswordRequestPageState();
}

class _PasswordRequestPageState extends State<PasswordRequestPage> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сброс пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
          listener: (context, state) {
            if (state is SendCodeSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Письмо отправлено на почту ✉️'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SendCodeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error ?? 'Не удалось отправить письмо'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Введите email, на который придет ссылка для сброса пароля',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                CustomElevatedButton(
                  text: 'Отправить',
                  onPressed: () {
                    context.read<ResetPasswordBloc>().add(
                          SendConfirmationCode(email: emailController.text),
                        );
                  },
                ),
                if (state is SendCodeInProgress)
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
}
