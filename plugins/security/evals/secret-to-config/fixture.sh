#!/usr/bin/env bash
set -euo pipefail
mkdir -p config app/Services
printf '.env\nvendor/\n' > .gitignore
printf 'APP_NAME=Studio\nSTRIPE_SECRET=\n' > .env.example
cat > config/services.php <<'C'
<?php

return [
    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
    ],
];
C
cat > app/Services/PaymentService.php <<'S'
<?php

namespace App\Services;

class PaymentService
{
    public function __construct(private string $stripeSecret) {}
}
S
echo '{"require":{"laravel/framework":"^12"}}' > composer.json
# fake live-format key, assembled so the committed eval never contains a key-shaped string
printf '%s%s%s\n' 'sk_' 'live_' '51HxQzZ9eV2wq8T4yR6uN0pLm3' > stripe-key.txt
