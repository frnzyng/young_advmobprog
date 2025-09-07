import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:young_longexam_mobile/models/item_model.dart';
import 'package:young_longexam_mobile/services/item_service.dart';
import 'package:young_longexam_mobile/widgets/custom_text.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final Item item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _qtyTotalCtrl;
  late TextEditingController _qtyAvailCtrl;
  late bool _isActive;

  bool _isEditing = false;
  bool _isSaving = false;
  final _svc = ItemService();
  late Item _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _nameCtrl = TextEditingController(text: _item.name);
    _descCtrl = TextEditingController(text: _item.description.join('\n'));
    _photoCtrl = TextEditingController(text: _item.photoUrl);
    _qtyTotalCtrl = TextEditingController(text: _item.qtyTotal);
    _qtyAvailCtrl = TextEditingController(text: _item.qtyAvailable);
    _isActive = (_item.isActive.toString().toLowerCase() == 'true');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    _qtyTotalCtrl.dispose();
    _qtyAvailCtrl.dispose();
    super.dispose();
  }

  List<String> _parseDesc(String raw) => raw
      .split(RegExp(r'[\n,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  int _toInt(TextEditingController c, {int fallback = 0}) {
    int? v = int.tryParse(c.text.trim());
    return v == null || v < 0 ? fallback : v;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final total = _toInt(_qtyTotalCtrl, fallback: 0);
    final avail = _toInt(_qtyAvailCtrl, fallback: 0);
    if (avail > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qty Available cannot exceed Qty Total'))
      );
      return;
    }

    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _parseDesc(_descCtrl.text),
      'photoUrl': _photoCtrl.text.trim(),
      'qtyTotal': total,
      'qtyAvailable': avail,
      'isActive': _isActive,
    };

    setState(() => _isSaving = true);
    try {
      final res = await _svc.updateItem(_item.iid, payload);
      final updated = res['res'] ?? res;
      final updatedItem = Item.fromJson(updated);

      setState(() => _item = updatedItem);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item updated.')));
      Navigator.of(context)
          .pop(updatedItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _isSaving = true);
    try {
      await _svc.deleteItem(_item.iid, {});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Item deleted.')));
      Navigator.of(context).pop({'deleted': true, 'id': _item.iid});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _imagePreview() {
    final url = _photoCtrl.text.trim();
    if (url.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.inventory_2_outlined, size: 48),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, size: 48),
        ),
      ),
    );
  }

  Widget _statusChip(String active) {
    return Chip(
      label: Text(active == 'true' ? 'Active' : 'Inactive',
        style: TextStyle(color: Colors.white),
      ),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active == 'true' ? Colors.green : Colors.grey),
      backgroundColor: active == 'true' ? Colors.green : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item.name.isEmpty ? 'Item' : _item.name),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                // toggle view/edit
                _isEditing = !_isEditing;
              });
            },
          ),
          if (!_isActive && _isEditing)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _confirmDelete()
          ),
        ],
      ),
      body: _isEditing ? _buildEditView() : _buildDetailView(),
    );
  }

  Widget _buildEditView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imagePreview(),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _photoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Photo URL',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}), // refresh preview
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description (one per line or comma-separated)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => _parseDesc(v ?? '').isEmpty
                    ? 'Add at least one line'
                    : null,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyTotalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qty Total',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyAvailCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qty Available',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final a = int.tryParse((v ?? '').trim());
                        final t = int.tryParse(_qtyTotalCtrl.text.trim());
                        if (a == null || a < 0) return 'Invalid';
                        if (t != null && a > t) return '> total';
                        return null;
                      },
                    ),
                  ),
                ]
              ),
              SizedBox(height: 8.h),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : Navigator.of(context).pop,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView () {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          _imagePreview(),
          SizedBox(height: 20.h,),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: widget.item.name.isEmpty
                                ? 'Untitled'
                                : widget.item.name,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                            ),
                          ),
                          _statusChip(widget.item.isActive),
                        ],
                      ),
                      SizedBox(height: 4.h,),
                      CustomText(
                        text: 'Description',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      if (widget.item.description.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(4)
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.item.description.map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 4.h), // spacing between bullets
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "• ",
                                        style: TextStyle(fontSize: 14.sp),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          text: item,
                                          fontSize: 14.sp,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ),
                        ),
                        SizedBox(height: 8.h,),
                        CustomText(
                          text: 'Quantity',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: 'Quantity Total:',
                                fontSize: 14.sp,
                              ),
                              CustomText(
                                text: widget.item.qtyTotal,
                                fontSize: 14.sp,
                              ),
                            ],
                          )
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: 'Quantity Available:',
                                fontSize: 14.sp,
                              ),
                              CustomText(
                                text: widget.item.qtyAvailable,
                                fontSize: 14.sp,
                              ),
                            ],
                          )
                        ),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}