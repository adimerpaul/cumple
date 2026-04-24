<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Auth;
use OwenIt\Auditing\Contracts\Auditable;
use OwenIt\Auditing\Auditable as AuditableTrait;

class Birthday extends Model implements Auditable
{
    use SoftDeletes, AuditableTrait;

    protected $fillable = [
        'user_id', 'name', 'birth_day', 'birth_month', 'birth_year',
        'gender', 'interests', 'notes', 'is_self',
        'created_by', 'updated_by', 'deleted_by',
    ];

    protected function casts(): array
    {
        return ['is_self' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected static function booted(): void
    {
        static::creating(function (Birthday $b) {
            if (Auth::check()) $b->created_by = Auth::id();
        });
        static::updating(function (Birthday $b) {
            if (Auth::check()) $b->updated_by = Auth::id();
        });
        static::deleting(function (Birthday $b) {
            if (Auth::check()) {
                $b->deleted_by = Auth::id();
                $b->saveQuietly();
            }
        });
    }
}
