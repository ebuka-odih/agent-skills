#!/usr/bin/env bash
set -euo pipefail
mkdir -p app/Billing tests/Unit
echo '{"require":{"php":"^8.3","laravel/framework":"^12"},"require-dev":{"pestphp/pest":"^3.7"}}' > composer.json
cat > app/Billing/LateCancelFee.php <<'P'
<?php

declare(strict_types=1);

namespace App\Billing;

final class LateCancelFee
{
    public function forMinutesBefore(int $priceKobo, int $minutesBefore): int
    {
        if ($minutesBefore <= 0) {
            return $priceKobo;
        }

        return $minutesBefore >= 120 ? 0 : intdiv($priceKobo, 2);
    }
}
P
cat > tests/Unit/LateCancelFeeTest.php <<'T'
<?php

use App\Billing\LateCancelFee;

it('is free well before class', fn () => expect((new LateCancelFee)->forMinutesBefore(1000, 300))->toBe(0));
it('charges something late', fn () => expect((new LateCancelFee)->forMinutesBefore(1000, 30))->toBeGreaterThan(0));
T
