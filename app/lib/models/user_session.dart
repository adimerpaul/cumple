class UserSession {
  final int? id;
  final String firebaseUid;
  final int laravelUserId;
  final String name;
  final String email;
  final String? photoB64;
  final String laravelToken;
  final String createdAt;

  const UserSession({
    this.id,
    required this.firebaseUid,
    required this.laravelUserId,
    required this.name,
    required this.email,
    this.photoB64,
    required this.laravelToken,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'firebase_uid': firebaseUid,
        'laravel_user_id': laravelUserId,
        'name': name,
        'email': email,
        'photo_b64': photoB64,
        'laravel_token': laravelToken,
        'created_at': createdAt,
      };

  factory UserSession.fromMap(Map<String, dynamic> map) => UserSession(
        id: map['id'] as int?,
        firebaseUid: map['firebase_uid'] as String,
        laravelUserId: map['laravel_user_id'] as int,
        name: map['name'] as String,
        email: map['email'] as String,
        photoB64: map['photo_b64'] as String?,
        laravelToken: map['laravel_token'] as String,
        createdAt: map['created_at'] as String,
      );
}
