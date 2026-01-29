import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../models/extra_wishes.dart';
import '../services/extra_wishes_service.dart';
import '../services/bodies_service.dart';
import '../models/body.dart';

class ExtraWishesScreen extends StatefulWidget {
  const ExtraWishesScreen({super.key});

  @override
  State<ExtraWishesScreen> createState() => _ExtraWishesScreenState();
}

class _ExtraWishesScreenState extends State<ExtraWishesScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nazarWishesController = TextEditingController();
  final TextEditingController _nazarCostController = TextEditingController();
  final TextEditingController _fidyahDaysController = TextEditingController();
  final TextEditingController _fidyahAmountController = TextEditingController();
  final TextEditingController _waqfBodiesController = TextEditingController();
  final TextEditingController _charityBodiesController = TextEditingController();

  bool _organDonor = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Bodies lookup and selections
  List<BodyItem> _bodies = <BodyItem>[];
  final List<Map<String, dynamic>> _selectedWaqf = <Map<String, dynamic>>[]; // { bodies_id, amount }
  final List<Map<String, dynamic>> _selectedCharity = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nazarWishesController.dispose();
    _nazarCostController.dispose();
    _fidyahDaysController.dispose();
    _fidyahAmountController.dispose();
    _waqfBodiesController.dispose();
    _charityBodiesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      _bodies = await BodiesService.instance.listActiveBodies();
      final ExtraWishes? wishes = await ExtraWishesService.instance.getForCurrentUser();
      if (wishes != null) {
        _nazarWishesController.text = wishes.nazarWishes ?? '';
        _nazarCostController.text = (wishes.nazarEstimatedCostMyr ?? '').toString();
        _fidyahDaysController.text = (wishes.fidyahFastLeftDays ?? '').toString();
        _fidyahAmountController.text = (wishes.fidyahAmountDueMyr ?? '').toString();
        _organDonor = wishes.organDonorPledge ?? false;
        _selectedWaqf
          ..clear()
          ..addAll(wishes.waqfBodies);
        _selectedCharity
          ..clear()
          ..addAll(wishes.charityBodies);
      }
    } catch (_) {
      // ignore for UX; show empty form
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _bodyName(int id) => _bodies.firstWhere((b) => b.id == id, orElse: () => BodyItem(id: id, name: 'Body #$id')).name ?? 'Body #$id';

  Future<void> _addOrEditAmount({required bool isWaqf, required int bodiesId}) async {
    final List<Map<String, dynamic>> target = isWaqf ? _selectedWaqf : _selectedCharity;
    Map<String, dynamic>? existing = target.firstWhere((e) => (e['bodies_id'] as int) == bodiesId, orElse: () => <String, dynamic>{});
    final TextEditingController amountCtrl = TextEditingController(text: ((existing['amount'] as num?)?.toString() ?? ''));
    final double? amount = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set amount - ${_bodyName(bodiesId)}'),
          content: TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Amount (MYR)'),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final double? v = double.tryParse(amountCtrl.text.trim());
              Navigator.of(context).pop(v);
            }, child: const Text('Save')),
          ],
        );
      },
    );
    if (amount == null) return;
    final int idx = target.indexWhere((e) => (e['bodies_id'] as int) == bodiesId);
    if (idx >= 0) {
      target[idx] = <String, dynamic>{'bodies_id': bodiesId, 'amount': amount};
    } else {
      target.add(<String, dynamic>{'bodies_id': bodiesId, 'amount': amount});
    }
    setState(() {});
  }

  Future<void> _openBodiesSelector({required bool isWaqf}) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        final String allowCat1 = 'sadaqah_waqaf_zakat';
        final String allowCat2 = 'waqaf';
        final List<BodyItem> source = _bodies.where((BodyItem b) {
          final String c = (b.category ?? '').toLowerCase();
          if (isWaqf) {
            return c == allowCat1 || c == allowCat2;
          }
          return c == allowCat1; // charity only
        }).toList();
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: source.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final BodyItem item = source[index];
              final List<Map<String, dynamic>> target = isWaqf ? _selectedWaqf : _selectedCharity;
              final bool selected = target.any((e) => (e['bodies_id'] as int) == item.id);
              final double? amount = selected
                  ? (target.firstWhere((e) => (e['bodies_id'] as int) == item.id)['amount'] as num?)?.toDouble()
                  : null;
              return ListTile(
                leading: const Icon(Icons.volunteer_activism_outlined),
                title: Text(item.name ?? 'Body ${item.id}'),
                subtitle: amount != null ? Text('RM ${amount.toStringAsFixed(2)}') : null,
                trailing: Icon(selected ? Icons.check_circle : Icons.add_circle_outline, color: selected ? Colors.green : null),
                onTap: () async {
                  await _addOrEditAmount(isWaqf: isWaqf, bodiesId: item.id);
                  if (!mounted) return;
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uuid = AuthController.instance.currentUser?.id;
      if (uuid == null) throw Exception('No authenticated user');
      final double? nazarCost = double.tryParse(_nazarCostController.text.trim());
      final int? fidyahDays = int.tryParse(_fidyahDaysController.text.trim());
      final double? fidyahAmount = double.tryParse(_fidyahAmountController.text.trim());

      final ExtraWishes payload = ExtraWishes(
        uuid: uuid,
        nazarWishes: _nazarWishesController.text.trim().isEmpty ? null : _nazarWishesController.text.trim(),
        nazarEstimatedCostMyr: nazarCost,
        fidyahFastLeftDays: fidyahDays,
        fidyahAmountDueMyr: fidyahAmount,
        organDonorPledge: _organDonor,
        waqfBodies: _selectedWaqf,
        charityBodies: _selectedCharity,
      );

      await ExtraWishesService.instance.upsertForCurrentUser(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extra wishes saved')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extra Wishes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    Text('Nazar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nazarWishesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Nazar wishes',
                        hintText: 'Describe nazar wishes',                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nazarCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Estimated cost (MYR)',                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Fidyah', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fidyahDaysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Fast days left',                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fidyahAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Amount due (MYR)',                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _organDonor,
                      onChanged: (v) => setState(() => _organDonor = v),
                      title: const Text('Organ donor pledge'),
                    ),
                    const SizedBox(height: 16),
                    Text('Waqf', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final Map<String, dynamic> w in _selectedWaqf)
                          InputChip(
                            label: Text('${_bodyName((w['bodies_id'] as int))} • RM ${(w['amount'] as num?)?.toStringAsFixed(2) ?? '-'}'),
                            onPressed: () => _addOrEditAmount(isWaqf: true, bodiesId: (w['bodies_id'] as int)),
                            onDeleted: () {
                              _selectedWaqf.removeWhere((e) => (e['bodies_id'] as int) == (w['bodies_id'] as int));
                              setState(() {});
                            },
                          ),
                        ActionChip(
                          label: const Text('Add waqf body'),
                          avatar: const Icon(Icons.add, size: 18),
                          onPressed: () => _openBodiesSelector(isWaqf: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Charity', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final Map<String, dynamic> c in _selectedCharity)
                          InputChip(
                            label: Text('${_bodyName((c['bodies_id'] as int))} • RM ${(c['amount'] as num?)?.toStringAsFixed(2) ?? '-'}'),
                            onPressed: () => _addOrEditAmount(isWaqf: false, bodiesId: (c['bodies_id'] as int)),
                            onDeleted: () {
                              _selectedCharity.removeWhere((e) => (e['bodies_id'] as int) == (c['bodies_id'] as int));
                              setState(() {});
                            },
                          ),
                        ActionChip(
                          label: const Text('Add charity body'),
                          avatar: const Icon(Icons.add, size: 18),
                          onPressed: () => _openBodiesSelector(isWaqf: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


