import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../main.dart';
import '../core/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
  const AccountSettingsPage({super.key});

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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeEmailPage())),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambiar contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage())),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Cambiar Nombre y Apellidos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeUsernamePage())),
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA: CAMBIAR EMAIL ---
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  _ChangeEmailPageState createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _cargando = false;

  Future<void> _actualizarEmail() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _cargando = true);
    try {
      await apiService.patch('/users/me/email', data: {
        "email": _emailController.text.trim(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo actualizado con éxito"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } on DioException catch (e) {
      String error = "Error al actualizar el correo";
      if (e.response?.statusCode == 400) {
        error = e.response?.data['error'] ?? "Este correo ya está en uso";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar correo')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Nuevo correo electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _cargando 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _actualizarEmail,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Actualizar Correo'),
                ),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA: CAMBIAR CONTRASEÑA ---
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _cargando = false;

  bool _validarPassword(String p) {
    // 8 caracteres, mayúscula, número y símbolo
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(p);
  }

  Future<void> _actualizarPassword() async {
    if (_nuevaController.text != _confirmarController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Las contraseñas no coinciden")));
      return;
    }

    if (!_validarPassword(_nuevaController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña debe tener 8 caracteres, una mayúscula, un número y un símbolo (!@#\$&*~)")),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      await apiService.patch('/users/me/password', data: {
        "passwordActual": _actualController.text,
        "passwordNueva": _nuevaController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña actualizada"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Contraseña actual incorrecta"), backgroundColor: Colors.red));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _actualController, decoration: const InputDecoration(labelText: 'Contraseña actual'), obscureText: true),
            const SizedBox(height: 10),
            TextField(controller: _nuevaController, decoration: const InputDecoration(labelText: 'Nueva contraseña'), obscureText: true),
            const SizedBox(height: 10),
            TextField(controller: _confirmarController, decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'), obscureText: true),
            const SizedBox(height: 30),
            _cargando 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _actualizarPassword, child: const Text('Actualizar Contraseña')),
          ],
        ),
      ),
    );
  }
}

// --- PANTALLA: CAMBIAR NOMBRE/APELLIDOS ---
class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({super.key});

  @override
  _ChangeUsernamePageState createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _nomController = TextEditingController();
  final _cognomsController = TextEditingController();
  bool _cargando = false;

  Future<void> _actualizarNombre() async {
    setState(() => _cargando = true);
    try {
      await apiService.put('/users/me', data: {
        "nom": _nomController.text.trim(),
        "cognoms": _cognomsController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al actualizar perfil"), backgroundColor: Colors.red));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar perfil')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 10),
            TextField(controller: _cognomsController, decoration: const InputDecoration(labelText: 'Apellidos')),
            const SizedBox(height: 20),
            _cargando 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _actualizarNombre, child: const Text('Actualizar Perfil')),
          ],
        ),
      ),
    );
  }
}
