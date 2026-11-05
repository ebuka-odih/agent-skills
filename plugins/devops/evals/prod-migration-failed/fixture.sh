#!/usr/bin/env bash
set -euo pipefail
mkdir -p database/migrations
echo '{"require":{"laravel/framework":"^12"}}' > composer.json
touch artisan
cat > database/migrations/2026_11_05_120000_split_member_name.php <<'P'
<?php
// adds first_name/last_name, backfills from name, then drops name — all in one migration
P
