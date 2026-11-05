#!/usr/bin/env bash
set -euo pipefail
mkdir -p database/migrations app/Models
echo '{"require":{"laravel/framework":"^12"}}' > composer.json
cat > database/migrations/2026_11_05_120000_rename_bookings_seats.php <<'P'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $t) {
            $t->renameColumn('seats', 'spots');
        });
    }
};
P
printf '<?php\n// Booking model now reads $booking->spots everywhere\n' > app/Models/Booking.php
