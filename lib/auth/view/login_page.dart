import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/auth/login/cubit/login_cubit.dart';
import 'package:campusconnect/auth/login/widgets/auth_provider_sign_in_button.dart';
import 'package:campusconnect/auth/login/widgets/forgot_password_button.dart';
import 'package:campusconnect/auth/login/widgets/login_form.dart';
import 'package:campusconnect/auth/login/widgets/sign_in_button.dart'
    show SignInButton;
import 'package:campusconnect/auth/login/widgets/sign_up_new_account_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        userRepository: context.read<UserRepository>(),
      ),
      child: LoginView(),
    );
  }
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      body: AppConstrainedScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xlg,
        ),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.xxxlg * 2),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppLogo(fit: BoxFit.fitHeight, width: double.infinity),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //login form
                  LoginForm(),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSpacing.md,
                      top: AppSpacing.md,
                      right: AppSpacing.xs,
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child:
                          ForgotPasswordButton(), // ForgotPasswordButton widget
                    ),
                  ),
                  Align(
                    child: SignInButton(), // SignInButton widget
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.xxlg,
                    ),
                    child: AppTextDivider(text: 'OR'),
                  ),
                  Align(
                    child: AuthProviderSignInButton(
                      provider: AuthProvider.google,
                      onPressed: () =>
                          context.read<LoginCubit>().loginWithGoogle(),
                    ),
                  ),
                  Align(
                    child: AuthProviderSignInButton(
                      provider: AuthProvider.github,
                      onPressed: () =>
                          context.read<LoginCubit>().loginWithGithub(),
                    ),
                  ),
                ],
              ),
            ),
            const SignUpNewAccountButton(),
           
            
          ],
        ),
      ),
    );
  }
}
