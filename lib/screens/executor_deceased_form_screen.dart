import 'package:flutter/material.dart';
import '../config/executor_constants.dart';

class ExecutorDeceasedFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ExecutorDeceasedFormScreen({
    super.key,
    this.initialData,
  });

  @override
  State<ExecutorDeceasedFormScreen> createState() => _ExecutorDeceasedFormScreenState();
}

class _ExecutorDeceasedFormScreenState extends State<ExecutorDeceasedFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _deceasedFullNameCtrl = TextEditingController();
  final TextEditingController _deceasedNricNewCtrl = TextEditingController();
  final TextEditingController _deceasedNricOldCtrl = TextEditingController();
  final TextEditingController _deceasedPoliceArmyNricCtrl = TextEditingController();
  final TextEditingController _deceasedDateOfDeathCtrl = TextEditingController();
  String? _selectedDeathCause;
  final TextEditingController _placeOfDeathCtrl = TextEditingController();
  String? _selectedMaritalStatus;
  String? _selectedCitizenship;
  String? _selectedReligion;
  String? _selectedRace;
  bool _isBankrupt = false;
  bool _willWritten = false;
  final TextEditingController _willRegistrationNoCtrl = TextEditingController();
  final TextEditingController _executorNameCtrl = TextEditingController();
  final TextEditingController _willCustodianCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final data = widget.initialData;
    if (data != null) {
      _deceasedFullNameCtrl.text = data['full_name'] ?? '';
      _deceasedNricNewCtrl.text = data['nric_new'] ?? '';
      _deceasedNricOldCtrl.text = data['nric_old'] ?? '';
      _deceasedPoliceArmyNricCtrl.text = data['police_army_nric'] ?? '';
      _deceasedDateOfDeathCtrl.text = data['date_of_death'] ?? '';
      _selectedDeathCause = data['cause_of_death'];
      _placeOfDeathCtrl.text = data['place_of_death'] ?? '';
      _selectedMaritalStatus = data['marital_status'];
      _selectedCitizenship = data['citizenship'];
      _selectedReligion = data['religion'];
      _selectedRace = data['race'];
      _isBankrupt = data['bankrupt'] ?? false;
      _willWritten = data['will_written'] ?? false;
      _willRegistrationNoCtrl.text = data['will_registration_no'] ?? '';
      _executorNameCtrl.text = data['executor'] ?? '';
      _willCustodianCtrl.text = data['will_custodian'] ?? '';
    }
  }

  @override
  void dispose() {
    _deceasedFullNameCtrl.dispose();
    _deceasedNricNewCtrl.dispose();
    _deceasedNricOldCtrl.dispose();
    _deceasedPoliceArmyNricCtrl.dispose();
    _deceasedDateOfDeathCtrl.dispose();
    _placeOfDeathCtrl.dispose();
    _willRegistrationNoCtrl.dispose();
    _executorNameCtrl.dispose();
    _willCustodianCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'full_name': _deceasedFullNameCtrl.text.trim(),
        'nric_new': _deceasedNricNewCtrl.text.trim().isNotEmpty ? _deceasedNricNewCtrl.text.trim() : null,
        'nric_old': _deceasedNricOldCtrl.text.trim().isNotEmpty ? _deceasedNricOldCtrl.text.trim() : null,
        'police_army_nric': _deceasedPoliceArmyNricCtrl.text.trim().isNotEmpty ? _deceasedPoliceArmyNricCtrl.text.trim() : null,
        'date_of_death': _deceasedDateOfDeathCtrl.text.trim().isNotEmpty ? _deceasedDateOfDeathCtrl.text.trim() : null,
        'cause_of_death': _selectedDeathCause,
        'place_of_death': _placeOfDeathCtrl.text.trim().isNotEmpty ? _placeOfDeathCtrl.text.trim() : null,
        'marital_status': _selectedMaritalStatus,
        'citizenship': _selectedCitizenship,
        'religion': _selectedReligion,
        'race': _selectedRace,
        'bankrupt': _isBankrupt,
        'will_written': _willWritten,
        'will_registration_no': _willWritten && _willRegistrationNoCtrl.text.trim().isNotEmpty ? _willRegistrationNoCtrl.text.trim() : null,
        'executor': _willWritten && _executorNameCtrl.text.trim().isNotEmpty ? _executorNameCtrl.text.trim() : null,
        'will_custodian': _willWritten && _willCustodianCtrl.text.trim().isNotEmpty ? _willCustodianCtrl.text.trim() : null,
      };
      Navigator.of(context).pop(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deceased Information'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _deceasedFullNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name *',                    prefixIcon: Icon(Icons.person_outline),                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deceasedNricNewCtrl,
                        decoration: InputDecoration(labelText: 'NRIC (New)',                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deceasedNricOldCtrl,
                        decoration: InputDecoration(labelText: 'NRIC (Old)',                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deceasedPoliceArmyNricCtrl,
                  decoration: InputDecoration(
                    labelText: 'Police/Army NRIC',                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deceasedDateOfDeathCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date of Death *',                    prefixIcon: Icon(Icons.calendar_today_outlined),                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _deceasedDateOfDeathCtrl.text = date.toIso8601String().split('T').first;
                      });
                    }
                  },
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDeathCause,
                  decoration: InputDecoration(
                    labelText: 'Cause of Death',                    prefixIcon: Icon(Icons.info_outline),                  ),
                  items: ExecutorConstants.deathCauses
                      .map((c) => DropdownMenuItem<String>(
                            value: c['value'],
                            child: Text(c['name']!),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDeathCause = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _placeOfDeathCtrl,
                  decoration: InputDecoration(
                    labelText: 'Place of Death',                    prefixIcon: Icon(Icons.location_on_outlined),                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMaritalStatus,
                        decoration: InputDecoration(
                          labelText: 'Marital Status',                        ),
                        items: ExecutorConstants.maritalStatus
                            .map((m) => DropdownMenuItem<String>(
                                  value: m['value'],
                                  child: Text(m['name']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMaritalStatus = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCitizenship,
                        decoration: InputDecoration(
                          labelText: 'Citizenship',                        ),
                        items: ExecutorConstants.citizenship
                            .map((c) => DropdownMenuItem<String>(
                                  value: c['value'],
                                  child: Text(c['name']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCitizenship = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedReligion,
                        decoration: InputDecoration(
                          labelText: 'Religion',                        ),
                        items: ExecutorConstants.religions
                            .map((r) => DropdownMenuItem<String>(
                                  value: r['value'],
                                  child: Text(r['name']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedReligion = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRace,
                        decoration: InputDecoration(
                          labelText: 'Race',                        ),
                        items: ExecutorConstants.races
                            .map((r) => DropdownMenuItem<String>(
                                  value: r['value'],
                                  child: Text(r['name']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedRace = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Bankrupt'),
                  value: _isBankrupt,
                  onChanged: (v) => setState(() => _isBankrupt = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Will Written'),
                  value: _willWritten,
                  onChanged: (v) => setState(() => _willWritten = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_willWritten) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _willRegistrationNoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Will Registration Number',                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _executorNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Executor Name',                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _willCustodianCtrl,
                    decoration: InputDecoration(
                      labelText: 'Will Custodian',                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

