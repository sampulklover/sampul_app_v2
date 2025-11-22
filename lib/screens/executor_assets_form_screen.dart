import 'package:flutter/material.dart';

class ExecutorAssetsFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ExecutorAssetsFormScreen({
    super.key,
    this.initialData,
  });

  @override
  State<ExecutorAssetsFormScreen> createState() => _ExecutorAssetsFormScreenState();
}

class _ExecutorAssetsFormScreenState extends State<ExecutorAssetsFormScreen> {
  final List<Map<String, dynamic>> _immovableAssets = [];
  final List<Map<String, dynamic>> _movableAssets = [];
  final List<Map<String, dynamic>> _liabilities = [];
  final List<Map<String, dynamic>> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Clear existing data first
    _immovableAssets.clear();
    _movableAssets.clear();
    _liabilities.clear();
    _beneficiaries.clear();
    
    final data = widget.initialData;
    if (data != null) {
      if (data['immovable_assets'] != null) {
        final items = (data['immovable_assets'] as List).cast<Map<String, dynamic>>();
        _immovableAssets.addAll(items.map((item) => Map<String, dynamic>.from(item)));
      }
      if (data['movable_assets'] != null) {
        final items = (data['movable_assets'] as List).cast<Map<String, dynamic>>();
        _movableAssets.addAll(items.map((item) => Map<String, dynamic>.from(item)));
      }
      if (data['liabilities'] != null) {
        final items = (data['liabilities'] as List).cast<Map<String, dynamic>>();
        _liabilities.addAll(items.map((item) => Map<String, dynamic>.from(item)));
      }
      if (data['beneficiaries'] != null) {
        final items = (data['beneficiaries'] as List).cast<Map<String, dynamic>>();
        _beneficiaries.addAll(items.map((item) => Map<String, dynamic>.from(item)));
      }
    }
  }

  Future<void> _showAddAssetDialog(String type, List<Map<String, dynamic>> list, int? index) async {
    final nameController = TextEditingController(text: index != null ? list[index]['name'] ?? list[index]['description'] : '');
    final valueController = TextEditingController(text: index != null ? list[index]['value']?.toString() : '');
    final descriptionController = TextEditingController(text: index != null ? list[index]['description'] ?? list[index]['name'] : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${index != null ? 'Edit' : 'Add'} $type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name/Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Value (RM)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (type == 'Beneficiary') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final item = {
                'name': nameController.text.trim(),
                'description': descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : nameController.text.trim(),
                'value': valueController.text.trim().isNotEmpty ? double.tryParse(valueController.text.trim()) : null,
              };
              setState(() {
                if (index != null) {
                  list[index] = item;
                } else {
                  list.add(item);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsSection(String title, IconData icon, List<Map<String, dynamic>> items, Function(int?) onAdd) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No ${title.toLowerCase()} added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item['name'] ?? item['description'] ?? 'Unnamed'),
                    subtitle: item['value'] != null
                        ? Text('Value: RM ${item['value']}')
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onAdd(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              items.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAdd(null),
                icon: const Icon(Icons.add),
                label: Text('Add ${title.substring(0, title.length - 1)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    // Create new list instances to avoid reference issues
    final data = {
      'immovable_assets': _immovableAssets.map((item) => Map<String, dynamic>.from(item)).toList(),
      'movable_assets': _movableAssets.map((item) => Map<String, dynamic>.from(item)).toList(),
      'liabilities': _liabilities.map((item) => Map<String, dynamic>.from(item)).toList(),
      'beneficiaries': _beneficiaries.map((item) => Map<String, dynamic>.from(item)).toList(),
    };
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets Information'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assets Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This section allows you to add immovable assets, movable assets, liabilities, and beneficiaries. You can add multiple items in each category.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildAssetsSection(
                      'Immovable Assets',
                      Icons.home_outlined,
                      _immovableAssets,
                      (index) => _showAddAssetDialog('Immovable Asset', _immovableAssets, index),
                    ),
                    const SizedBox(height: 24),
                    _buildAssetsSection(
                      'Movable Assets',
                      Icons.directions_car_outlined,
                      _movableAssets,
                      (index) => _showAddAssetDialog('Movable Asset', _movableAssets, index),
                    ),
                    const SizedBox(height: 24),
                    _buildAssetsSection(
                      'Liabilities',
                      Icons.account_balance_outlined,
                      _liabilities,
                      (index) => _showAddAssetDialog('Liability', _liabilities, index),
                    ),
                    const SizedBox(height: 24),
                    _buildAssetsSection(
                      'Beneficiaries',
                      Icons.people_outlined,
                      _beneficiaries,
                      (index) => _showAddAssetDialog('Beneficiary', _beneficiaries, index),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Assets'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

