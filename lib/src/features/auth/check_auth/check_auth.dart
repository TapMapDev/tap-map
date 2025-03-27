import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tap_map/core/common/styles.dart';
import 'package:tap_map/src/features/auth/bloc/authorization_bloc.dart';
import 'package:go_router/go_router.dart';

class CheckAuthPage extends StatefulWidget {
  const CheckAuthPage({super.key});

  @override
  State<CheckAuthPage> createState() => _CheckAuthPageState();
}

class _CheckAuthPageState extends State<CheckAuthPage> {
  @override
  Widget build(BuildContext context) {
    context.read<AuthorizationBloc>().add(CheckAuthorizationEvent());
    return BlocListener<AuthorizationBloc, AuthorizationState>(
      listener: (context, state) {
        if (state is AuthorizedState) {
          context.go('/homepage');
        } else if (state is UnAuthorizedState) {
          context.go('/authorization');
        }
      },
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: StyleManager.mainColor,
          ),
        ),
      ),
    );
  }
}
