import 'package:hive_ce/hive.dart';

const int kDefaultTarget = 33;
const int kMaxTarget = 9999;
const int kMaxPhraseLength = 80;

class PresetDhikr {
  const PresetDhikr({
    required this.id,
    required this.phrase,
    required this.createdAt,
  });

  final String id;
  final String phrase;
  final int createdAt;
}

const List<PresetDhikr> kPresets = [
  PresetDhikr(id: 'istighfar', phrase: 'استغفر الله', createdAt: 1),
  PresetDhikr(id: 'hamd', phrase: 'الحمد لله', createdAt: 2),
  PresetDhikr(id: 'subhan', phrase: 'سبحان الله', createdAt: 3),
  PresetDhikr(id: 'akbar', phrase: 'الله أكبر', createdAt: 4),
  PresetDhikr(id: 'salawat', phrase: 'الصلاة على النبي', createdAt: 5),
];

class Dhikr {
  Dhikr({
    required this.id,
    required this.phrase,
    required this.isPreset,
    required this.createdAt,
    this.count = 0,
    this.rounds = 0,
    this.total = 0,
    this.target = kDefaultTarget,
  });

  final String id;
  String phrase;
  final bool isPreset;
  int count;
  int rounds;
  int total;
  int target;
  final int createdAt;

  bool get roundComplete => target > 0 && count >= target;

  double get progress {
    if (target <= 0) return 0;
    return (count / target).clamp(0, 1).toDouble();
  }

  /// Counts one tap.
  ///
  /// The round climbs until [target]. The next tap starts again at 1.
  /// Returns true when this tap finishes a round.
  bool increment() {
    total += 1;
    if (count >= target) {
      count = 1;
    } else {
      count += 1;
    }
    if (count >= target) {
      rounds += 1;
      return true;
    }
    return false;
  }

  /// Undoes the latest tap in the current round. Returns false at zero.
  bool decrement() {
    if (count <= 0 || total <= 0) return false;
    final completed = count >= target;
    count -= 1;
    total -= 1;
    if (completed && rounds > 0) rounds -= 1;
    return true;
  }

  void resetRound() => count = 0;

  void resetAll() {
    count = 0;
    rounds = 0;
    total = 0;
  }

  void setTarget(int value) {
    target = value.clamp(1, kMaxTarget);
    if (count > target) count = target;
  }

  void rename(String value) {
    if (isPreset) return;
    final text = value.trim();
    if (text.isEmpty || text.length > kMaxPhraseLength) return;
    phrase = text;
  }
}

class DhikrAdapter extends TypeAdapter<Dhikr> {
  const DhikrAdapter();

  static const int typeIdConst = 1;
  static const int schemaVersion = 1;

  @override
  int get typeId => typeIdConst;

  @override
  Dhikr read(BinaryReader reader) {
    final version = reader.readByte();
    if (version != schemaVersion) {
      throw HiveError('Unknown dhikr schema version: $version');
    }
    return Dhikr(
      id: reader.readString(),
      phrase: reader.readString(),
      isPreset: reader.readBool(),
      count: reader.readInt(),
      rounds: reader.readInt(),
      total: reader.readInt(),
      target: reader.readInt(),
      createdAt: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Dhikr obj) {
    writer
      ..writeByte(schemaVersion)
      ..writeString(obj.id)
      ..writeString(obj.phrase)
      ..writeBool(obj.isPreset)
      ..writeInt(obj.count)
      ..writeInt(obj.rounds)
      ..writeInt(obj.total)
      ..writeInt(obj.target)
      ..writeInt(obj.createdAt);
  }
}
