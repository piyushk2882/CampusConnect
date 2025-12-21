import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/signup/sign_up.dart';
import 'package:campusconnect/auth/signup/widgets/sign_up_button.dart';
import 'package:campusconnect/auth/signup/widgets/widgets.dart';
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(
        userRepository: context.read<UserRepository>(),
      ),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  File? _avatarFile;
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      body: AppConstrainedScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xxxlg * 2),
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppLogo(fit: BoxFit.fitHeight, width: double.infinity),
            ),

            Expanded(
              child: Column(
                children: [
                  Align(
                    child: AvatarImagePicker(
                      onUpload: (_, avatarFlie) {
                        setState(() => _avatarFile = avatarFlie);
                      },
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.md,
                  ),
                  SignUpForm(),
                  SizedBox(
                    height: AppSpacing.xlg,
                  ),
                  SignUpButton(
                    avatarFile: _avatarFile,
                  ),
                ],
              ),
            ),
            SignInIntoAccountButton(),
          ],
        ),
      ),
    );
  }
}
