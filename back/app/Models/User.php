<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\HasApiTokens;
use OwenIt\Auditing\Contracts\Auditable;
use OwenIt\Auditing\Auditable as AuditableTrait;

class User extends Authenticatable implements Auditable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes, AuditableTrait;

    protected $fillable = [
        'firebase_uid', 'name', 'email', 'photo_url', 'photo_b64',
        'profile_completed', 'created_by', 'updated_by', 'deleted_by',
    ];

    protected $hidden = ['remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'profile_completed' => 'boolean',
        ];
    }

    public function birthdays(): HasMany
    {
        return $this->hasMany(Birthday::class);
    }

    protected static function booted(): void
    {
        static::creating(function (User $user) {
            if (Auth::check()) $user->created_by = Auth::id();
        });
        static::updating(function (User $user) {
            if (Auth::check()) $user->updated_by = Auth::id();
        });
        static::deleting(function (User $user) {
            if (Auth::check()) {
                $user->deleted_by = Auth::id();
                $user->saveQuietly();
            }
        });
    }
}
