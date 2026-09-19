import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../utils/colors.dart';

class AddTripItemScreen extends StatefulWidget {
  const AddTripItemScreen({super.key});

  @override
  State<AddTripItemScreen> createState() => _AddTripItemScreenState();
}

class _AddTripItemScreenState extends State<AddTripItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _itemType = 'hotel';
  String _currency = 'USD';
  TimeOfDay? _selectedTime;

  final List<Map<String, String>> _types = [
    {'value': 'hotel', 'label': '🏨 Hotel'},
    {'value': 'tour', 'label': '🦁 Tour'},
    {'value': 'beach', 'label': '🏖️ Beach'},
    {'value': 'mountain', 'label': '⛰️ Mountain'},
    {'value': 'culture', 'label': '🎭 Culture'},
    {'value': 'food', 'label': '🍛 Food'},
    {'value': 'transport', 'label': '🚐 Transport'},
    {'value': 'activity', 'label': '🎯 Activity'},
  ];

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final timeString = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    final item = TripItem(
      itemId: DateTime.now().millisecondsSinceEpoch.toString(),
      itemType: _itemType,
      itemName: _nameController.text.trim(),
      itemImage: _imageController.text.trim(),
      time: timeString,
      price: double.tryParse(_priceController.text) ?? 0,
      currency: _currency,
      notes: _notesController.text.trim(),
    );

    Navigator.pop(context, item);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('➕ Add Activity'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('🎯 Activity Type', width),
              SizedBox(height: height * 0.01),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final isSelected = _itemType == t['value'];
                  return GestureDetector(
                    onTap: () => setState(() => _itemType = t['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        t['label']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: height * 0.025),
              _sectionTitle('📝 Details', width),
              SizedBox(height: height * 0.01),
              _buildField(_nameController, 'Activity Name', Icons.title,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: height * 0.015),
              _buildField(
                  _imageController, 'Image URL (optional)', Icons.image),
              SizedBox(height: height * 0.015),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                        _priceController, 'Price', Icons.attach_money,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          isExpanded: true,
                          items: ['USD', 'TZS', 'EUR', 'GBP']
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? 'USD'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          color: AppColors.primary, size: width * 0.05),
                      SizedBox(width: width * 0.03),
                      Text(
                        _selectedTime != null
                            ? 'Time: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select time (optional)',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? Colors.grey.shade800
                              : Colors.grey.shade500,
                          fontSize: width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              _buildField(_notesController, 'Notes (optional)', Icons.note,
                  maxLines: 3),
              SizedBox(height: height * 0.03),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ADD TO ITINERARY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.045,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
