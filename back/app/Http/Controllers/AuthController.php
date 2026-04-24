<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Kreait\Firebase\Factory;

class AuthController extends Controller
{
    public function firebaseLogin(Request $request): JsonResponse
    {
        $request->validate(['firebase_token' => 'required|string']);

        try {
            $factory = (new Factory)->withServiceAccount(
                storage_path('app/firebase/serviceAccountKey.json')
            );
            $decoded = $factory->createAuth()->verifyIdToken($request->firebase_token);
        } catch (\Throwable) {
            return response()->json(['message' => 'Token de Firebase inválido'], 401);
        }

        $uid      = $decoded->claims()->get('sub');
        $email    = $decoded->claims()->get('email', '');
        $name     = $decoded->claims()->get('name', 'Usuario');
        $photoUrl = $decoded->claims()->get('picture');

        $existing = User::withTrashed()->where('firebase_uid', $uid)->first();
        if ($existing?->trashed()) {
            return response()->json(['message' => 'Cuenta desactivada'], 403);
        }

        $user = User::updateOrCreate(
            ['firebase_uid' => $uid],
            ['name' => $name, 'email' => $email, 'photo_url' => $photoUrl]
        );

        $user->tokens()->delete();
        $token = $user->createToken('cumple-app')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $this->userPayload($request->user())]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada']);
    }

    private function userPayload(User $user): array
    {
        return [
            'id'                => $user->id,
            'name'              => $user->name,
            'email'             => $user->email,
            'photo_url'         => $user->photo_url,
            'profile_completed' => $user->profile_completed,
        ];
    }
}
