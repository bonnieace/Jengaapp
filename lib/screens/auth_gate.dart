import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/farm_scope.dart';
import 'home_screens.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          FarmScope.clear();
          return const AuthScreen();
        }
        return _FarmBootstrap(user: user);
      },
    );
  }
}

class _FarmBootstrap extends StatelessWidget {
  const _FarmBootstrap({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data?.data();
        final tenantId = data?['activeTenantId'] as String?;
        if (snapshot.hasError || tenantId == null || tenantId.isEmpty) {
          return const _BootstrapError();
        }
        FarmScope.tenantId = tenantId;
        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('tenants').doc(tenantId).collection('flocks')
              .where('active', isEqualTo: true).limit(1).get(),
          builder: (context, flockSnapshot) {
            if (flockSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final docs = flockSnapshot.data?.docs ?? [];
            if (docs.isEmpty) return const FlockSetupScreen();
            FarmScope.flockId = docs.first.id;
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('We could not load your farm account. Please sign in again.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: FirebaseAuth.instance.signOut, child: const Text('Sign out')),
          ]),
        )),
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _farmName = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose(); _password.dispose(); _farmName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_register) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text,
        );
        final uid = credential.user!.uid;
        final db = FirebaseFirestore.instance;
        final tenant = db.collection('tenants').doc();
        final batch = db.batch();
        batch.set(tenant, {'name': _farmName.text.trim(), 'ownerId': uid, 'createdAt': FieldValue.serverTimestamp()});
        batch.set(tenant.collection('members').doc(uid), {'role': 'owner', 'status': 'active', 'createdAt': FieldValue.serverTimestamp()});
        batch.set(db.collection('users').doc(uid), {'email': _email.text.trim().toLowerCase(), 'activeTenantId': tenant.id, 'createdAt': FieldValue.serverTimestamp()});
        await batch.commit();
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Authentication failed.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not finish setup. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.egg_alt_outlined, size: 72, color: Colors.deepPurple),
        const SizedBox(height: 12),
        Text(_register ? 'Create your ChickFarm' : 'Welcome to ChickFarm', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        if (_register) TextFormField(controller: _farmName, decoration: const InputDecoration(labelText: 'Farm name', border: OutlineInputBorder()), validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your farm name' : null),
        if (_register) const SizedBox(height: 12),
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), validator: (v) => !(v ?? '').contains('@') ? 'Enter a valid email' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), validator: (v) => (v ?? '').length < 8 ? 'Use at least 8 characters' : null),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Please wait…' : (_register ? 'Create farm' : 'Sign in'))),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'Already have an account? Sign in' : 'New farm? Create an account')),
      ])),
    )))),
  );
}

class FlockSetupScreen extends StatefulWidget {
  const FlockSetupScreen({super.key});
  @override
  State<FlockSetupScreen> createState() => _FlockSetupScreenState();
}

class _FlockSetupScreenState extends State<FlockSetupScreen> {
  final _name = TextEditingController();
  final _count = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    final count = int.tryParse(_count.text);
    if (_name.text.trim().isEmpty || count == null || count < 1) return;
    setState(() => _busy = true);
    try {
      final doc = await FarmScope.collection('flocks').add({'name': _name.text.trim(), 'initialBirdCount': count, 'eggStock': 0, 'startedAt': Timestamp.now(), 'active': true, 'createdAt': FieldValue.serverTimestamp()});
      FarmScope.flockId = doc.id;
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Set up your first flock')), body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(children: [
    const Text('Create an active batch before recording mortality or vaccinations.'), const SizedBox(height: 20),
    TextField(controller: _name, decoration: const InputDecoration(labelText: 'Flock or batch name', border: OutlineInputBorder())), const SizedBox(height: 12),
    TextField(controller: _count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Starting number of birds', border: OutlineInputBorder())), const SizedBox(height: 20),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? 'Saving…' : 'Create flock'))),
  ])))));
}
