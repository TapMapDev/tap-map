import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_map/ui/theme/OLD_app_text_styles.dart';
import 'package:tap_map/router/routes.dart';
import 'package:tap_map/src/features/registration/bloc/registration_bloc.dart';
import 'package:tap_map/src/widget/custom_elevated_button.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool showPassword = true;
  bool showRepeatPassword = true;
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordRepeatController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state is RegistarationStatenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is RegistarationStateSuccess) {
            context.go(AppRoutes.authorization);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 93,
                      width: 151,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Tap Map',
                            style: TextStyle(
                              fontFamily: 'regular',
                              color: Color(0xFF000000),
                              fontWeight: FontWeight.bold,
                              height: 1,
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: StyleManager.mainColor,
                              borderRadius: BorderRadius.circular(70),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              child: Text(
                                'Пхукет',
                                style: TextStyle(
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: StyleManager.bgColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Юзернэйм',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 16.24 / 14,
                    color: StyleManager.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: StyleManager.blocColor,
                      hintText: 'Юзернэйм',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Эмэил',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 16.24 / 14,
                    color: StyleManager.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: StyleManager.blocColor,
                      hintText: 'Эмэил',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Пароль',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 16.24 / 14,
                    color: StyleManager.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: TextField(
                    obscureText: showPassword,
                    controller: passwordController,
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(
                            top: 15, bottom: 15, right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          child: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: StyleManager.blocColor,
                      hintText: 'Новый пароль',
                      hintStyle: TextStylesManager.standartMain,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Повторите пароль',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 16.24 / 14,
                    color: StyleManager.grayColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 50,
                  child: TextField(
                    obscureText: showRepeatPassword,
                    controller: passwordRepeatController,
                    decoration: InputDecoration(
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(
                            top: 15, bottom: 15, right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              showRepeatPassword = !showRepeatPassword;
                            });
                          },
                          child: Icon(
                            showRepeatPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      filled: true,
                      fillColor: StyleManager.blocColor,
                      hintText: 'Повторите пароль',
                      hintStyle: TextStylesManager.standartMain,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (state is RegistarationStateInProccess)
                  const Center(
                    child: CircularProgressIndicator(
                      color: StyleManager.mainColor,
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BackButton(),
                      CustomElevatedButton(
                        onPressed: () {
                          if (passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('"Пароль" не может быть пустым'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          if (passwordRepeatController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    '"Повтор Пароля" не может быть пустым'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          if (passwordController.text ==
                              passwordRepeatController.text) {
                            context.read<RegistrationBloc>().add(
                                  RegistrationCreateAccountEvent(
                                    username: usernameController.text,
                                    email: emailController.text,
                                    password1: passwordController.text,
                                    password2: passwordRepeatController.text,
                                  ),
                                );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Пароли должны совпадать'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        text: 'Создайте аккаунт',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
