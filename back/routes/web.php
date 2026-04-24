<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/share/birthday', function (Request $request) {
    if (!$request->hasValidSignature()) {
        abort(403, 'Enlace inválido o expirado');
    }

    $name = (string) $request->query('name', '');
    $birthDay = (int) $request->query('birth_day');
    $birthMonth = (int) $request->query('birth_month');
    $birthYear = $request->query('birth_year');
    $gender = (string) $request->query('gender', '');
    $interests = (string) $request->query('interests', '');
    $notes = (string) $request->query('notes', '');

    $deepLink = 'cumple://birthday-import?' . http_build_query([
        'name' => $name,
        'birth_day' => $birthDay,
        'birth_month' => $birthMonth,
        'birth_year' => $birthYear,
        'gender' => $gender,
        'interests' => $interests,
        'notes' => $notes,
    ]);

    $safeName = e($name);
    $safeDeepLink = e($deepLink);

    return response(<<<HTML
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Importar cumpleaños</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background:#f5f7ff; color:#1a1d3a; }
    .card { max-width: 520px; margin: 40px auto; background:#fff; border-radius:16px; padding:24px; box-shadow:0 6px 24px rgba(0,0,0,.08); }
    h1 { margin: 0 0 8px; font-size: 24px; }
    p { color:#6b7280; line-height:1.5; }
    .btn { display:inline-block; margin-top:14px; padding:12px 18px; background:#2563ff; color:#fff; text-decoration:none; border-radius:999px; font-weight:700; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Importar cumpleaños</h1>
    <p>Te compartieron el cumpleaños de <strong>{$safeName}</strong>.</p>
    <p>Toca el botón para abrir Cumple e importar la fecha.</p>
    <a class="btn" href="{$safeDeepLink}">Abrir en la app</a>
  </div>
  <script>
    window.location.href = "{$safeDeepLink}";
  </script>
</body>
</html>
HTML, 200)->header('Content-Type', 'text/html; charset=UTF-8');
})->name('share.birthday');
