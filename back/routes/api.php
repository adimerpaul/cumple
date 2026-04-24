<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BirthdayController;
use Illuminate\Support\Facades\Route;

// Público
Route::post('/auth/firebase', [AuthController::class, 'firebaseLogin']);

// Protegido
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me',      [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Cumpleaños
    Route::get('/birthdays',            [BirthdayController::class, 'index']);
    Route::post('/birthdays',           [BirthdayController::class, 'store']);
    Route::put('/birthdays/{birthday}', [BirthdayController::class, 'update']);
    Route::delete('/birthdays/{birthday}', [BirthdayController::class, 'destroy']);
});
