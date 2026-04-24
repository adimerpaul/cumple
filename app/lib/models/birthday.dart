class Birthday {
  final int? id;
  final String name;
  final int birthDay;
  final int birthMonth;
  final int? birthYear;
  final String? gender;
  final String? notes;
  final String? interests;
  final bool isSelf;
  final int notifyDaysBefore;
  final String createdAt;

  const Birthday({
    this.id,
    required this.name,
    required this.birthDay,
    required this.birthMonth,
    this.birthYear,
    this.gender,
    this.notes,
    this.interests,
    this.isSelf = false,
    this.notifyDaysBefore = 1,
    required this.createdAt,
  });

  int get daysUntil {
    final today = DateTime.now();
    final flat = DateTime(today.year, today.month, today.day);
    var next = DateTime(today.year, birthMonth, birthDay);
    if (next.isBefore(flat)) next = DateTime(today.year + 1, birthMonth, birthDay);
    return next.difference(flat).inDays;
  }

  int? get nextAge {
    if (birthYear == null) return null;
    final today = DateTime.now();
    int age = today.year - birthYear!;
    final hasPassed = today.month > birthMonth ||
        (today.month == birthMonth && today.day >= birthDay);
    if (!hasPassed) age--;
    return age + 1;
  }

  List<String> get interestsList =>
      (interests == null || interests!.isEmpty) ? [] : interests!.split('||');

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'birth_day': birthDay,
        'birth_month': birthMonth,
        'birth_year': birthYear,
        'gender': gender,
        'notes': notes,
        'interests': interests,
        'is_self': isSelf ? 1 : 0,
        'notify_days_before': notifyDaysBefore,
        'created_at': createdAt,
      };

  factory Birthday.fromMap(Map<String, dynamic> map) => Birthday(
        id: map['id'] as int?,
        name: map['name'] as String,
        birthDay: map['birth_day'] as int,
        birthMonth: map['birth_month'] as int,
        birthYear: map['birth_year'] as int?,
        gender: map['gender'] as String?,
        notes: map['notes'] as String?,
        interests: map['interests'] as String?,
        isSelf: (map['is_self'] as int? ?? 0) == 1,
        notifyDaysBefore: map['notify_days_before'] as int? ?? 1,
        createdAt: map['created_at'] as String,
      );
}
