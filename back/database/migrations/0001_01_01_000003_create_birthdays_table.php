<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('birthdays', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->unsignedTinyInteger('birth_day');
            $table->unsignedTinyInteger('birth_month');
            $table->unsignedSmallInteger('birth_year')->nullable();
            $table->string('gender', 10)->nullable();    // hombre | mujer | otro
            $table->text('interests')->nullable();        // string separado por ||
            $table->text('notes')->nullable();
            $table->boolean('is_self')->default(false);  // true = propio cumpleaños del usuario
            // Audit
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->unsignedBigInteger('deleted_by')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('birthdays');
    }
};
