import 'package:flutter/material.dart';
import '../config/executor_constants.dart';
import '../utils/form_decoration_helper.dart';

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
                  decoration: FormDecorationHelper.roundedInputDecoration(
                    context: context,
                    labelText: 'Full Name *',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deceasedNricNewCtrl,
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'NRIC (New)',
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deceasedNricOldCtrl,
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'NRIC (Old)',
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deceasedPoliceArmyNricCtrl,
                  decoration: FormDecorationHelper.roundedInputDecoration(
                    context: context,
                    labelText: 'Police/Army NRIC',
                    prefixIcon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deceasedDateOfDeathCtrl,
                  readOnly: true,
                  decoration: FormDecorationHelper.roundedInputDecoration(
                    context: context,
                    labelText: 'Date of Death *',
                    prefixIcon: Icons.calendar_today_outlined,
                  ),
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
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_outlined),
                  decoration: FormDecorationHelper.roundedInputDecoration(
                    context: context,
                    labelText: 'Cause of Death',
                    prefixIcon: Icons.info_outline,
                  ),
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
                  decoration: FormDecorationHelper.roundedInputDecoration(
                    context: context,
                    labelText: 'Place of Death',
                    prefixIcon: Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedMaritalStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'Marital Status',
                          prefixIcon: Icons.favorite_outline,
                        ),
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
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'Citizenship',
                          prefixIcon: Icons.public_outlined,
                        ),
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
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'Religion',
                          prefixIcon: Icons.church_outlined,
                        ),
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
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_outlined),
                        decoration: FormDecorationHelper.roundedInputDecoration(
                          context: context,
                          labelText: 'Race',
                          prefixIcon: Icons.people_outline,
                        ),
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
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Will Registration Number',
                      prefixIcon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _executorNameCtrl,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Executor Name',
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _willCustodianCtrl,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Will Custodian',
                      prefixIcon: Icons.security_outlined,
                    ),
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

