import 'package:flutter/material.dart';
import '../models/trust.dart';
import '../services/trust_service.dart';

class TrustEditScreen extends StatefulWidget {
  final Trust? initial;
  const TrustEditScreen({super.key, this.initial});

  @override
  State<TrustEditScreen> createState() => _TrustEditScreenState();
}

class _TrustEditScreenState extends State<TrustEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.initial != null && widget.initial!.id != null;
  bool get _isDraft => (widget.initial?.computedStatus ?? TrustStatus.draft) == TrustStatus.draft;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameCtrl.text = widget.initial!.name ?? '';
      _codeCtrl.text = widget.initial!.trustCode ?? '';
      _emailCtrl.text = widget.initial!.email ?? '';
      _phoneCtrl.text = widget.initial!.phoneNo ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        if (!_isDraft) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only draft trusts can be edited')));
          setState(() => _isSaving = false);
          return;
        }
        final int id = widget.initial!.id!;
        await TrustService.instance.updateTrust(id, {
          'name': _nameCtrl.text.trim(),
          'trust_code': _codeCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          'phone_no': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        });
      } else {
        await TrustService.instance.createTrust(Trust(
          name: _nameCtrl.text.trim(),
          // trust_code will be auto-generated in service
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phoneNo: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Trust' : 'Create Trust')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              enabled: _isDraft || !_isEditing,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'Trust code (auto-generated)'),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: _isDraft || !_isEditing,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
              enabled: _isDraft || !_isEditing,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Save changes' : 'Create trust'),
            ),
          ],
        ),
      ),
    );
  }
}


