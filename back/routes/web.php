<?php

use App\Models\ShareCode;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/share/c/{code}', function (string $code) {
    $shareCode = ShareCode::where('code', strtoupper($code))->first();
    if (!$shareCode || $shareCode->expires_at === null || $shareCode->expires_at->isPast()) {
        abort(410, 'Código inválido o expirado');
    }

    $deepLink = 'cumple://share-import?' . http_build_query([
        'code' => strtoupper($code),
    ]);

    $payload = $shareCode->payload ?? [];
    $birthdays = $payload['birthdays'] ?? [];
    $firstName = isset($birthdays[0]['name']) ? (string) $birthdays[0]['name'] : 'contacto';
    $safeName = e($firstName);
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
    <p>Te compartieron cumpleaños desde <strong>{$safeName}</strong>.</p>
    <p>Toca el botón para abrir Cumple e importar los datos.</p>
    <a class="btn" href="{$safeDeepLink}">Abrir en la app</a>
  </div>
  <script>
    window.location.href = "{$safeDeepLink}";
  </script>
</body>
</html>
HTML, 200)->header('Content-Type', 'text/html; charset=UTF-8');
})->name('share.birthday');
