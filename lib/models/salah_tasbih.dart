import 'package:hasanat/models/dhikr.dart';

/// The dhikr said after the obligatory prayer.
///
/// Three times أستغفر الله, then the salam supplication, then thirty-three
/// of سبحان الله، الحمد لله، and الله أكبر, then the phrase that completes
/// one hundred.
const List<SalahStep> kSalahTasbih = [
  SalahStep(id: 'istighfar', phrase: 'أستغفر الله', target: 3),
  SalahStep(
    id: 'salam',
    phrase: 'اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام',
    target: 1,
  ),
  SalahStep(id: 'subhan', phrase: 'سبحان الله', target: 33),
  SalahStep(id: 'hamd', phrase: 'الحمد لله', target: 33),
  SalahStep(id: 'akbar', phrase: 'الله أكبر', target: 33),
  SalahStep(
    id: 'tahlil',
    phrase:
        'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير',
    target: 1,
  ),
];

/// Phrases counted by the after-prayer sequence that are not home-screen cards.
final List<PresetDhikr> kSalahStored = [
  for (final step in kSalahTasbih)
    if (step.id == 'salam' || step.id == 'tahlil')
      PresetDhikr(
        id: step.id,
        phrase: step.phrase,
        createdAt: step.id == 'salam' ? 6 : 7,
        target: step.target,
      ),
];

class SalahStep {
  const SalahStep({
    required this.id,
    required this.phrase,
    required this.target,
  });

  final String id;
  final String phrase;
  final int target;
}

class SalahProgress {
  const SalahProgress({this.step = 0, this.count = 0, this.finished = false});

  final int step;
  final int count;
  final bool finished;

  bool get started => finished || step > 0 || count > 0;

  SalahStep get current =>
      kSalahTasbih[step.clamp(0, kSalahTasbih.length - 1)];

  double get progress {
    if (finished) return 1;
    final target = current.target;
    if (target <= 0) return 0;
    return (count / target).clamp(0, 1).toDouble();
  }

  /// The dhikr that received the latest tap in this prayer.
  String? get undoId {
    if (finished) return kSalahTasbih.last.id;
    if (count > 0) return current.id;
    if (step <= 0) return null;
    return kSalahTasbih[step - 1].id;
  }

  SalahProgress tap() {
    if (finished) return this;
    final target = current.target;
    final nextCount = count + 1;
    if (nextCount < target) {
      return SalahProgress(step: step, count: nextCount);
    }
    final last = step >= kSalahTasbih.length - 1;
    if (last) {
      return SalahProgress(step: step, count: target, finished: true);
    }
    return SalahProgress(step: step + 1);
  }

  SalahProgress undo() {
    if (finished) {
      final last = kSalahTasbih.length - 1;
      final target = kSalahTasbih[last].target;
      return SalahProgress(
        step: last,
        count: target > 0 ? target - 1 : 0,
      );
    }
    if (count > 0) {
      return SalahProgress(step: step, count: count - 1);
    }
    if (step <= 0) return this;
    final previous = kSalahTasbih[step - 1];
    return SalahProgress(
      step: step - 1,
      count: previous.target > 0 ? previous.target - 1 : 0,
    );
  }
}
