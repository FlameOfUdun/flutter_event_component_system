part of '../user_auth_feature.dart';

final class LoginCredentialsComponent extends ECSComponent<LoginCredentials?> {
  LoginCredentialsComponent([super.value]);
}

final class LoginCredentials {
  final String username;
  final String password;

  const LoginCredentials({
    required this.username,
    required this.password,
  });
}

class _LoginCredentialsModifier extends StatefulWidget {
  final LoginCredentials? value;
  final ValueChanged<LoginCredentials?> onChanged;

  const _LoginCredentialsModifier({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_LoginCredentialsModifier> createState() => _LoginCredentialsModifierState();
}

class _LoginCredentialsModifierState extends State<_LoginCredentialsModifier> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    userNameController.text = widget.value?.username ?? '';
    passwordController.text = widget.value?.password ?? '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          TextFormField(
            controller: userNameController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          TextFormField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    final value = LoginCredentials(
                      username: userNameController.text,
                      password: passwordController.text,
                    );
                    widget.onChanged(value);
                  },
                  child: Text('Submit'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    userNameController.clear();
                    passwordController.clear();
                    widget.onChanged(null);
                  },
                  child: Text('Clear'),
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }
}
