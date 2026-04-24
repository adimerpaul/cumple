<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Público — login con Firebase
Route::post('/auth/firebase', [AuthController::class, 'firebaseLogin']);

// Protegido con Sanctum
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me',     [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
});
