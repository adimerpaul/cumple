<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BirthdayController;
use App\Http\Controllers\ShareCodeController;
use Illuminate\Support\Facades\Route;

// Público
Route::post('/auth/firebase', [AuthController::class, 'firebaseLogin']);
Route::get('/share-codes/{code}', [ShareCodeController::class, 'resolve']);

// Protegido
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me',      [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Cumpleaños
    Route::get('/birthdays',            [BirthdayController::class, 'index']);
    Route::post('/birthdays',           [BirthdayController::class, 'store']);
    Route::put('/birthdays/{birthday}', [BirthdayController::class, 'update']);
    Route::delete('/birthdays/{birthday}', [BirthdayController::class, 'destroy']);

    // Compartir por código corto
    Route::post('/share-codes/self', [ShareCodeController::class, 'createSelfBirthdayCode']);
    Route::post('/share-codes/list', [ShareCodeController::class, 'createBirthdayListCode']);
});
