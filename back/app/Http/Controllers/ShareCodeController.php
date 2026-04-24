<?php

namespace App\Http\Controllers;

use App\Models\ShareCode;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ShareCodeController extends Controller
{
    public function createSelfBirthdayCode(Request $request): JsonResponse
    {
        $selfBirthday = $request->user()
            ->birthdays()
            ->where('is_self', true)
            ->first();

        if (!$selfBirthday) {
            return response()->json(['message' => 'Primero registra tu propio cumpleaños'], 404);
        }

        $shareCode = $this->createCode(
            userId: $request->user()->id,
            type: 'self',
            payload: [
                'birthdays' => [[
                    'name' => $selfBirthday->name,
                    'birth_day' => $selfBirthday->birth_day,
                    'birth_month' => $selfBirthday->birth_month,
                    'birth_year' => $selfBirthday->birth_year,
                    'gender' => $selfBirthday->gender,
                    'interests' => $selfBirthday->interests,
                    'notes' => $selfBirthday->notes,
                ]],
            ]
        );

        return response()->json([
            'code' => $shareCode->code,
            'url' => url('/share/c/' . $shareCode->code),
            'expires_at' => $shareCode->expires_at?->toIso8601String(),
        ]);
    }

    public function createBirthdayListCode(Request $request): JsonResponse
    {
        $data = $request->validate([
            'birthdays' => 'required|array|min:1',
            'birthdays.*.name' => 'required|string|max:150',
            'birthdays.*.birth_day' => 'required|integer|between:1,31',
            'birthdays.*.birth_month' => 'required|integer|between:1,12',
            'birthdays.*.birth_year' => 'nullable|integer|between:1900,2100',
            'birthdays.*.gender' => 'nullable|in:hombre,mujer,otro',
            'birthdays.*.interests' => 'nullable|string',
            'birthdays.*.notes' => 'nullable|string|max:500',
        ]);

        $shareCode = $this->createCode(
            userId: $request->user()->id,
            type: 'list',
            payload: ['birthdays' => $data['birthdays']]
        );

        return response()->json([
            'code' => $shareCode->code,
            'url' => url('/share/c/' . $shareCode->code),
            'expires_at' => $shareCode->expires_at?->toIso8601String(),
        ]);
    }

    public function resolve(string $code): JsonResponse
    {
        $shareCode = ShareCode::where('code', strtoupper($code))->first();

        if (!$shareCode) {
            return response()->json(['message' => 'Código no válido'], 404);
        }

        if ($shareCode->expires_at === null || $shareCode->expires_at->isPast()) {
            return response()->json(['message' => 'Código expirado'], 410);
        }

        return response()->json([
            'code' => $shareCode->code,
            'type' => $shareCode->type,
            'payload' => $shareCode->payload,
            'expires_at' => $shareCode->expires_at?->toIso8601String(),
        ]);
    }

    private function createCode(int $userId, string $type, array $payload): ShareCode
    {
        for ($i = 0; $i < 8; $i++) {
            $code = strtoupper(Str::random(8));
            if (!ShareCode::where('code', $code)->exists()) {
                return ShareCode::create([
                    'user_id' => $userId,
                    'code' => $code,
                    'type' => $type,
                    'payload' => $payload,
                    'expires_at' => now()->addDays(30),
                ]);
            }
        }

        abort(500, 'No se pudo generar el código');
    }
}

