import 'package:flutter/material.dart';
import 'main.dart'; // Importamos el themeNotifier

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSoundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, ThemeMode currentMode, __) {
              bool isDark = currentMode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Alternar entre modo claro y oscuro'),
                secondary: const Icon(Icons.brightness_4),
                value: isDark,
                onChanged: (bool value) {
                  themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          SwitchListTile(
            title: const Text('Sonido'),
            subtitle: const Text('Activar o desactivar efectos de sonido'),
            secondary: const Icon(Icons.volume_up),
            value: _isSoundEnabled,
            onChanged: (bool value) {
              setState(() {
                _isSoundEnabled = value;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.manage_accounts, color: Colors.blue),
            title: const Text('Ajustes de cuenta'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de cuenta'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Cambiar correo electrónico'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangeEmailPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Cambiar nombre de usuario'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangeUsernamePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChangeEmailPage extends StatelessWidget {
  const ChangeEmailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar correo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Nuevo correo electrónico')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Actualizar Correo'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Contraseña actual'), obscureText: true),
            const TextField(decoration: InputDecoration(labelText: 'Nueva contraseña'), obscureText: true),
            const TextField(decoration: InputDecoration(labelText: 'Confirmar nueva contraseña'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Actualizar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangeUsernamePage extends StatelessWidget {
  const ChangeUsernamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar nombre de usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Nuevo nombre de usuario')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Actualizar Nombre'),
            ),
          ],
        ),
      ),
    );
  }
}
