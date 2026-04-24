<?php

namespace App\Http\Controllers;

use App\Models\Birthday;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BirthdayController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $birthdays = $request->user()
            ->birthdays()
            ->orderBy('birth_month')
            ->orderBy('birth_day')
            ->get();

        return response()->json(['birthdays' => $birthdays]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'        => 'required|string|max:150',
            'birth_day'   => 'required|integer|between:1,31',
            'birth_month' => 'required|integer|between:1,12',
            'birth_year'  => 'nullable|integer|between:1900,2100',
            'gender'      => 'nullable|in:hombre,mujer,otro',
            'interests'   => 'nullable|string',
            'notes'       => 'nullable|string|max:500',
            'is_self'     => 'boolean',
        ]);

        $user = $request->user();

        // Si es el propio cumpleaños y ya existe uno, actualizarlo
        if (!empty($data['is_self'])) {
            $existing = $user->birthdays()->where('is_self', true)->first();
            if ($existing) {
                $existing->update($data);
                $this->markProfileComplete($user);
                return response()->json(['birthday' => $existing->fresh()]);
            }
        }

        $birthday = $user->birthdays()->create($data);

        if (!empty($data['is_self'])) {
            $this->markProfileComplete($user);
        }

        return response()->json(['birthday' => $birthday], 201);
    }

    public function update(Request $request, Birthday $birthday): JsonResponse
    {
        if ($birthday->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $data = $request->validate([
            'name'        => 'sometimes|string|max:150',
            'birth_day'   => 'sometimes|integer|between:1,31',
            'birth_month' => 'sometimes|integer|between:1,12',
            'birth_year'  => 'nullable|integer|between:1900,2100',
            'gender'      => 'nullable|in:hombre,mujer,otro',
            'interests'   => 'nullable|string',
            'notes'       => 'nullable|string|max:500',
        ]);

        $birthday->update($data);
        return response()->json(['birthday' => $birthday->fresh()]);
    }

    public function destroy(Request $request, Birthday $birthday): JsonResponse
    {
        if ($birthday->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $birthday->delete();
        return response()->json(['message' => 'Eliminado']);
    }

    private function markProfileComplete($user): void
    {
        $user->update(['profile_completed' => true]);
    }
}
