import 'package:flutter/material.dart';
import '../models/contact_note.dart';
import '../models/enums.dart';

/// Résultat du dialog de note
class NoteDialogResult {
  final String content;
  final NoteCategory category;
  final NoteImportance importance;
  final bool isPinned;
  final bool isActionItem;
  final DateTime? dueDate;

  NoteDialogResult({
    required this.content,
    required this.category,
    required this.importance,
    required this.isPinned,
    required this.isActionItem,
    this.dueDate,
  });
}

/// Dialog pour ajouter/éditer une note complète
class NoteDialog extends StatefulWidget {
  final ContactNote? note;

  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late TextEditingController _controller;
  late NoteCategory _category;
  late NoteImportance _importance;
  late bool _isPinned;
  late bool _isActionItem;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note?.content);
    _category = widget.note?.category ?? NoteCategory.general;
    _importance = widget.note?.importance ?? NoteImportance.medium;
    _isPinned = widget.note?.isPinned ?? false;
    _isActionItem = widget.note?.isActionItem ?? false;
    _dueDate = widget.note?.dueDate;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date d\'échéance',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adapter le nombre de lignes selon la catégorie
    final isLongNote = _category == NoteCategory.transcript;
    final maxLines = isLongNote ? 15 : 3;

    return AlertDialog(
      title: Text(widget.note == null ? 'Ajouter une note' : 'Modifier la note'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenu
              TextField(
                controller: _controller,
                maxLines: maxLines,
                minLines: isLongNote ? 10 : 3,
                decoration: InputDecoration(
                  hintText: isLongNote
                      ? 'Transcript de la conversation...\n\nVous pouvez écrire autant que nécessaire.'
                      : 'Contenu de la note...',
                  border: const OutlineInputBorder(),
                  helperText: isLongNote
                      ? '📝 Mode transcript - Saisie longue activée'
                      : null,
                ),
                autofocus: true,
              ),

              const SizedBox(height: 16),

              // Catégorie
              const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: NoteCategory.values.map((cat) {
                return ChoiceChip(
                  label: Text('${cat.icon} ${cat.displayName}'),
                  selected: _category == cat,
                  onSelected: (selected) {
                    if (selected) setState(() => _category = cat);
                  },
                );
              }).toList(),
              ),

              const SizedBox(height: 16),

              // Importance
              const Text('Importance', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<NoteImportance>(
                segments: NoteImportance.values.map((imp) {
                  return ButtonSegment(
                    value: imp,
                    label: Text('${imp.icon} ${imp.displayName}'),
                  );
                }).toList(),
                selected: {_importance},
                onSelectionChanged: (Set<NoteImportance> selected) {
                  setState(() => _importance = selected.first);
                },
              ),

              const SizedBox(height: 16),

              // Épingler
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('📌 Épingler en haut'),
                value: _isPinned,
                onChanged: (value) => setState(() => _isPinned = value),
              ),

              const Divider(),

              // Action avec échéance
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('🎯 Action à faire'),
                value: _isActionItem,
                onChanged: (value) => setState(() {
                  _isActionItem = value;
                  if (!value) _dueDate = null;
                }),
              ),

              if (_isActionItem) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _dueDate != null
                        ? 'Échéance: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Aucune échéance',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                      const Icon(Icons.edit, size: 20),
                    ],
                  ),
                  onTap: _selectDueDate,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final content = _controller.text.trim();
            if (content.isNotEmpty) {
              Navigator.pop(
                context,
                NoteDialogResult(
                  content: content,
                  category: _category,
                  importance: _importance,
                  isPinned: _isPinned,
                  isActionItem: _isActionItem,
                  dueDate: _dueDate,
                ),
              );
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
