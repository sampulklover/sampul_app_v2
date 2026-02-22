import 'package:flutter/material.dart';
import '../models/trust_charity.dart';
import '../config/trust_constants.dart';

class TrustCharityFormScreen extends StatefulWidget {
  final TrustCharity? charity;
  final int? index;

  const TrustCharityFormScreen({
    super.key,
    this.charity,
    this.index,
  });

  @override
  State<TrustCharityFormScreen> createState() => _TrustCharityFormScreenState();
}

class _TrustCharityFormScreenState extends State<TrustCharityFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late TextEditingController _organizationNameCtrl;
  late TextEditingController _address1Ctrl;
  late TextEditingController _address2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postcodeCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _accountNumberCtrl;
  late TextEditingController _donationAmountCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  
  String? _selectedCategory;
  String? _selectedBank;
  String? _selectedCountry;
  String? _selectedDonationDuration;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final charity = widget.charity;
    _organizationNameCtrl = TextEditingController(text: charity?.organizationName);
    _address1Ctrl = TextEditingController(text: charity?.addressLine1);
    _address2Ctrl = TextEditingController(text: charity?.addressLine2);
    _cityCtrl = TextEditingController(text: charity?.city);
    _postcodeCtrl = TextEditingController(text: charity?.postcode);
    _stateCtrl = TextEditingController(text: charity?.state);
    _accountNumberCtrl = TextEditingController(text: charity?.accountNumber);
    _donationAmountCtrl = TextEditingController(
      text: charity?.donationAmount?.toString() ?? '',
    );
    _emailCtrl = TextEditingController(text: charity?.email);
    _phoneCtrl = TextEditingController(text: charity?.phoneNo);
    
    _selectedCategory = charity?.category;
    _selectedBank = charity?.bank;
    _selectedCountry = charity?.country;
    _selectedDonationDuration = charity?.donationDuration;
  }

  @override
  void dispose() {
    _organizationNameCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _stateCtrl.dispose();
    _accountNumberCtrl.dispose();
    _donationAmountCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _saveCharity() {
    if (_formKey.currentState?.validate() ?? false) {
      final newCharity = TrustCharity(
        id: widget.charity?.id,
        organizationName: _organizationNameCtrl.text.trim(),
        addressLine1: _address1Ctrl.text.trim().isEmpty ? null : _address1Ctrl.text.trim(),
        addressLine2: _address2Ctrl.text.trim().isEmpty ? null : _address2Ctrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        postcode: _postcodeCtrl.text.trim().isEmpty ? null : _postcodeCtrl.text.trim(),
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        country: _selectedCountry,
        category: _selectedCategory,
        bank: _selectedBank,
        accountNumber: _accountNumberCtrl.text.trim().isEmpty ? null : _accountNumberCtrl.text.trim(),
        donationAmount: _donationAmountCtrl.text.trim().isEmpty 
            ? null 
            : double.tryParse(_donationAmountCtrl.text.trim()),
        donationDuration: _selectedDonationDuration,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phoneNo: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      Navigator.pop(context, newCharity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.charity == null ? 'Add Charity/Donation' : 'Edit Charity/Donation'),
        actions: [
          TextButton(
            onPressed: _saveCharity,
            child: Text(
              widget.charity == null ? 'ADD' : 'UPDATE',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Essential Information Card
            Card(
              elevation: 0,
              color: const Color.fromRGBO(255, 255, 255, 1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Charity Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _organizationNameCtrl,
                      decoration: InputDecoration(labelText: 'Organization Name *',
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      decoration: InputDecoration(labelText: 'Category',
                      ),
                      items: TrustConstants.donationCategories
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['name']!),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bank & Donation Details Card
            Card(
              elevation: 0,
              color: const Color.fromRGBO(255, 255, 255, 1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bank & Donation Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      decoration: InputDecoration(labelText: 'Bank *',
                      ),
                      items: TrustConstants.banks
                          .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(
                                  item['name']!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBank = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Account Number *',
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _donationAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Amount (RM) *',                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final amount = double.tryParse(v.trim());
                              if (amount == null || amount <= 0) {
                                return 'Enter valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDonationDuration,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(labelText: 'Frequency *',
                            ),
                            items: TrustConstants.donationDurations
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedDonationDuration = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Optional Contact & Address (Expandable)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_circle_outline),
                title: Text(
                  'Additional Information (Optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Information',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Address',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address1Ctrl,
                            decoration: InputDecoration(
                              labelText: 'Address Line 1',                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address2Ctrl,
                            decoration: InputDecoration(
                              labelText: 'Address Line 2',                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'City',                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _postcodeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Postcode',                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _stateCtrl,
                            decoration: InputDecoration(
                              labelText: 'State',                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_outlined),
                            decoration: InputDecoration(
                              labelText: 'Country',                            ),
                            items: TrustConstants.countries
                                .map((item) => DropdownMenuItem(
                                      value: item['value'],
                                      child: Text(item['name']!),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCountry = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

