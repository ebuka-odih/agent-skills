#!/usr/bin/env bash
set -euo pipefail
mkdir -p database/migrations app/Models app/Http/Controllers
cat > database/migrations/2024_01_01_000000_create_users_table.php <<'P'
<?php
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema;
return new class extends Migration { public function up(): void { Schema::create('users', function (Blueprint $t) { $t->id(); $t->string('name'); $t->string('phone')->nullable(); $t->timestamps(); }); } };
P
cat > app/Models/User.php <<'P'
<?php
namespace App\Models; use Illuminate\Database\Eloquent\Model;
class User extends Model { protected $fillable = ['name', 'phone']; }
P
cat > app/Http/Controllers/ProfileController.php <<'P'
<?php
namespace App\Http\Controllers; use App\Models\User; use Illuminate\Http\Request;
class ProfileController { public function update(Request $r, User $u) { $u->update(['phone' => $r->input('phone')]); return $u->only(['name', 'phone']); } }
P
