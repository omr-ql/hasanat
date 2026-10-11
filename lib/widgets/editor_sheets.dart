import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hasanat/models/dhikr.dart';
import 'package:hasanat/theme/app_theme.dart';
import 'package:hasanat/widgets/ui.dart';

class PhraseDraft {
  const PhraseDraft({required this.phrase, required this.target});

  final String phrase;
  final int target;
}

Future<PhraseDraft?> showPhraseEditor(
  BuildContext context, {
  String initialPhrase = '',
  int initialTarget = kDefaultTarget,
  bool includeTarget = true,
}) {
  return showModalBottomSheet<PhraseDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: PhraseEditorSheet(
            initialPhrase: initialPhrase,
            initialTarget: initialTarget,
            includeTarget: includeTarget,
          ),
        ),
      );
    },
  );
}

class PhraseEditorSheet extends StatefulWidget {
  const PhraseEditorSheet({
    super.key,
    required this.initialPhrase,
    required this.initialTarget,
    required this.includeTarget,
  });

  final String initialPhrase;
  final int initialTarget;
  final bool includeTarget;

  @override
  State<PhraseEditorSheet> createState() => _PhraseEditorSheetState();
}

class _PhraseEditorSheetState extends State<PhraseEditorSheet> {
  late final TextEditingController _phrase = TextEditingController(
    text: widget.initialPhrase,
  );
  late final TextEditingController _customTarget = TextEditingController(
    text: '${widget.initialTarget}',
  );
  final _formKey = GlobalKey<FormState>();
  late int? _chip = _matchingChip(widget.initialTarget);
  String? _targetError;

  static const _chips = [33, 100, 500];

  static int? _matchingChip(int target) {
    return _chips.contains(target) ? target : null;
  }

  @override
  void dispose() {
    _phrase.dispose();
    _customTarget.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    var target = widget.initialTarget;
    if (widget.includeTarget) {
      if (_chip != null) {
        target = _chip!;
      } else {
        final parsed = int.tryParse(_customTarget.text.trim());
        if (parsed == null || parsed < 1 || parsed > kMaxTarget) {
          setState(() => _targetError = 'أدخل رقماً من 1 إلى $kMaxTarget');
          return;
        }
        target = parsed;
      }
    }

    Navigator.pop(
      context,
      PhraseDraft(phrase: _phrase.text.trim(), target: target),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final editing = widget.initialPhrase.trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'تعديل الذكر' : 'إضافة ذكر',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'أي كلمة أو ذكر تريد عدّه على هذا الجهاز.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('phrase-field'),
              controller: _phrase,
              autofocus: true,
              maxLength: kMaxPhraseLength,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              textInputAction: widget.includeTarget
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'الذكر أو الكلمة',
                hintText: 'مثال: لا إله إلا الله',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'اكتب ذكراً أو كلمة';
                if (text.length > kMaxPhraseLength) {
                  return 'الحد $kMaxPhraseLength حرفاً';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (!widget.includeTarget) _submit();
              },
            ),
            if (widget.includeTarget) ...[
              const SizedBox(height: 16),
              Text(
                'هدف الحلقة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in _chips)
                    BlueChoiceChip(
                      label: '$value',
                      selected: _chip == value,
                      onSelected: (_) => setState(() {
                        _chip = value;
                        _targetError = null;
                      }),
                    ),
                  BlueChoiceChip(
                    key: const Key('target-custom'),
                    label: 'أخرى',
                    selected: _chip == null,
                    onSelected: (_) => setState(() {
                      _chip = null;
                      _targetError = null;
                    }),
                  ),
                ],
              ),
              if (_chip == null) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('target-field'),
                  controller: _customTarget,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: InputDecoration(
                    labelText: 'رقم الهدف',
                    errorText: _targetError,
                  ),
                  onChanged: (_) {
                    if (_targetError != null) {
                      setState(() => _targetError = null);
                    }
                  },
                ),
              ],
            ],
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('phrase-save'),
              onPressed: _submit,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<int?> showTargetEditor(BuildContext context, {required int current}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TargetEditorSheet(current: current),
        ),
      );
    },
  );
}

class TargetEditorSheet extends StatefulWidget {
  const TargetEditorSheet({super.key, required this.current});

  final int current;

  @override
  State<TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<TargetEditorSheet> {
  static const _chips = [33, 100, 500];

  late int? _chip = _chips.contains(widget.current) ? widget.current : null;
  late final TextEditingController _custom = TextEditingController(
    text: '${widget.current}',
  );
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _apply() {
    final target = _chip;
    if (target != null) {
      Navigator.pop(context, target);
      return;
    }
    final parsed = int.tryParse(_custom.text.trim());
    if (parsed == null || parsed < 1 || parsed > kMaxTarget) {
      setState(() => _error = 'أدخل رقماً من 1 إلى $kMaxTarget');
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('هدف الحلقة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'عند بلوغ الهدف تكتمل الحلقة، والعدّ التالي يبدأ من جديد.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.of(context).muted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in _chips)
                BlueChoiceChip(
                  label: '$value',
                  selected: _chip == value,
                  onSelected: (_) => setState(() {
                    _chip = value;
                    _error = null;
                  }),
                ),
              BlueChoiceChip(
                key: const Key('target-custom'),
                label: 'أخرى',
                selected: _chip == null,
                onSelected: (_) => setState(() {
                  _chip = null;
                  _error = null;
                }),
              ),
            ],
          ),
          if (_chip == null) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('target-field'),
              controller: _custom,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              decoration: InputDecoration(
                labelText: 'رقم الهدف',
                errorText: _error,
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('target-apply'),
            onPressed: _apply,
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final palette = AppPalette.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: destructive ? palette.danger : null),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
