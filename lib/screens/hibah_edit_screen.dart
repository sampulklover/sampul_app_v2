import 'package:flutter/material.dart';
import '../models/hibah.dart';
import '../services/hibah_service.dart';

class HibahEditScreen extends StatefulWidget {
  final Hibah? initial;
  const HibahEditScreen({super.key, this.initial});

  @override
  State<HibahEditScreen> createState() => _HibahEditScreenState();
}

class _HibahEditScreenState extends State<HibahEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.initial != null && widget.initial!.id != null;
  bool get _isDraft => (widget.initial?.computedStatus ?? HibahStatus.draft) == HibahStatus.draft;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameCtrl.text = widget.initial!.name ?? '';
      _codeCtrl.text = widget.initial!.hibahCode ?? '';
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Only draft hibahs can be edited')));
          setState(() => _isSaving = false);
          return;
        }
        final int id = widget.initial!.id!;
        await HibahService.instance.updateHibah(id, {
          'name': _nameCtrl.text.trim(),
          'hibah_code': _codeCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          'phone_no': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        });
      } else {
        await HibahService.instance.createHibah(Hibah(
          name: _nameCtrl.text.trim(),
          // hibah_code will be auto-generated in service
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Hibah' : 'Create Hibah')),
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
              decoration: const InputDecoration(labelText: 'Hibah code (auto-generated)'),
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
              label: Text(_isEditing ? 'Save changes' : 'Create hibah'),
            ),
          ],
        ),
      ),
    );
  }
}


