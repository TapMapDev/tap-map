import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tap_map/core/common/styles.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_bloc.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_event.dart';
import 'package:tap_map/src/features/password_reset/bloc/password_resert_state.dart';
import 'package:tap_map/src/widget/back_button.dart';
import 'package:tap_map/src/widget/custom_elevated_button.dart';

enum StageOfReset {
  firstStep,
  secondStep,
  thirdStep,
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  StageOfReset stage = StageOfReset.firstStep;
  TextEditingController emailController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordRepeatController = TextEditingController();
  bool showPassword = true;
  bool showRepeatPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          if (state is SendCodeSuccess) {
            setState(() {
              stage = StageOfReset.secondStep;
            });
          } else if (state is ConfirmCodeSuccess) {
            setState(() {
              stage = StageOfReset.thirdStep;
            });
          } else if (state is SetNewPassworduccess) {
            Navigator.pop(context);
            Get.snackbar('Success', 'Your password has been reset',
                backgroundColor: Colors.greenAccent, colorText: Colors.white);
          }
          if (state is SendCodeError) {
            Get.snackbar('Error', 'Email : ${state.error}');
          } else if (state is ConfirmCodeError) {
            Get.snackbar('Error', state.error ?? 'Something went wrong');
          } else if (state is SetNewPasswordError) {
            Get.snackbar('Error', state.error ?? 'Something went wrong');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 50.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 50),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildContent(),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state is SendCodeInProgress ||
                  state is ConfirmCodeInProgress ||
                  state is SetNewPasswordInProgress)
                Container(
                  color: Colors.black
                      .withOpacity(0.3), // Semi-transparent background
                  child: const Center(
                    child: CircularProgressIndicator(
                        // color: StyleManager.mainColor,
                        ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Метод для отображения заголовка
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Tap Map',
              style: TextStylesManager.headerMain,
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: StyleManager.mainColor,
                borderRadius: BorderRadius.circular(70),
              ),
              child: const Padding(
                padding:
                    EdgeInsets.only(right: 10, left: 10, top: 6, bottom: 6),
                child: Text(
                  'Пхукет',
                  style: TextStyle(
                    height: 1,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Метод для отображения основного контента
  Widget _buildContent() {
    return BlocBuilder<ResetPasswordBloc, ResetPasswordState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTitle(stage),
              style: TextStylesManager.headerMain.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 30,
                height: 1,
              ),
            ),
            SizedBox(height: 20),
            Text(
              _getDescriptionForStage(stage),
              // style: TextStylesManager.descriptionMain,
            ),
            SizedBox(height: 20),
            _buildTextFields(),
            SizedBox(height: 20),
            stage == StageOfReset.firstStep
                ? GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        // SvgPicture.asset('assets/icons/arrow_back.svg'),
                         SizedBox(width: 8),
                        // Text(
                        //   'Вы забыли пароль?',
                        //   // style: TextStylesManager.descriptionMainGray,
                        // ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()
          ],
        );
      },
    );
  }

  Widget _buildTextFields() {
    switch (stage) {
      case StageOfReset.firstStep:
        return TextField(
          controller: emailController,
          decoration: InputDecoration(
            filled: true,
            // fillColor: StyleManager.blocColor,
            hintText: _getHintForStage(stage),
            hintStyle: TextStylesManager.standartMain,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      case StageOfReset.secondStep:
        return TextField(
          controller: codeController,
          decoration: InputDecoration(
            filled: true,
            // fillColor: StyleManager.blocColor,
            hintText: _getHintForStage(stage),
            hintStyle: TextStylesManager.standartMain,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      case StageOfReset.thirdStep:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Новый пароль',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 16.24 / 14,
              ),
              // color: StyleManager.grayColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 6,
            ),
            TextField(
              controller: passwordController,
              obscureText: showPassword,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding:
                      const EdgeInsets.only(top: 15, bottom: 15, right: 16),
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                      child: showPassword
                          ? SvgPicture.asset(
                              'assets/icons/eye.svg',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              // color: StyleManager.grayColor,
                            )
                          : Image.asset(
                              'assets/icons/eye_locked.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              // color: StyleManager.grayColor,
                            )),
                ),
                filled: true,
                // fillColor: StyleManager.blocColor,
                hintText: _getHintForStage(stage),
                hintStyle: TextStylesManager.standartMain,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            const Text(
              'Повторите пароль',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                height: 16.24 / 14,
              ),
              // color: StyleManager.grayColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 6,
            ),
            TextField(
              controller: passwordRepeatController,
              obscureText: showRepeatPassword,
              decoration: InputDecoration(
                suffixIcon: Padding(
                  padding:
                      const EdgeInsets.only(top: 15, bottom: 15, right: 16),
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showRepeatPassword = !showRepeatPassword;
                        });
                      },
                      child: showRepeatPassword
                          ? SvgPicture.asset(
                              'assets/icons/eye.svg',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              // color: StyleManager.grayColor,
                            )
                          : Image.asset(
                              'assets/icons/eye_locked.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              // color: StyleManager.grayColor,
                            )),
                ),
                filled: true,
                // fillColor: StyleManager.blocColor,
                hintText: 'Повторите пароль',
                hintStyle: TextStylesManager.standartMain,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        );
    }
  }

  /// Метод для отображения кнопок внизу экрана
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CustomBackButton(),
        CustomElevatedButton(
          onPressed: _handleNextStep,
          text: _getButtonTitle(stage),
        ),
      ],
    );
  }

  String _getTitle(StageOfReset stage) {
    switch (stage) {
      case StageOfReset.firstStep:
        return 'Сброс пароля';
      case StageOfReset.secondStep:
        return 'Сброс пароля';
      case StageOfReset.thirdStep:
        return 'Новый пароль';
    }
  }

  String _getButtonTitle(StageOfReset stage) {
    switch (stage) {
      case StageOfReset.firstStep:
        return 'Отправить код';
      case StageOfReset.secondStep:
        return 'Продолжить';
      case StageOfReset.thirdStep:
        return 'Готово';
    }
  }

  String _getDescriptionForStage(StageOfReset stage) {
    switch (stage) {
      case StageOfReset.firstStep:
        return 'Чтобы сбросить пароль, введите ваш email';
      case StageOfReset.secondStep:
        return 'Мы отправили письмо на ваш email.';
      case StageOfReset.thirdStep:
        return 'Придумайте новый пароль.';
    }
  }

  String _getHintForStage(StageOfReset stage) {
    switch (stage) {
      case StageOfReset.firstStep:
        return 'Email';
      case StageOfReset.secondStep:
        return 'Код';
      case StageOfReset.thirdStep:
        return 'Новый пароль';
    }
  }

  void _handleNextStep() {
    final bloc = context.read<ResetPasswordBloc>();
    switch (stage) {
      case StageOfReset.firstStep:
        bloc.add(SendConfirmationCode(email: emailController.text));
        break;
      case StageOfReset.secondStep:
        bloc.add(ConfirmCode(
            code: codeController.text, email: emailController.text));
        break;
      case StageOfReset.thirdStep:
        bloc.add(SetNewPassword(
            email: emailController.text,
            newPassword: passwordController.text,
            confirmPassword: passwordRepeatController.text));
        break;
    }
  }
}
