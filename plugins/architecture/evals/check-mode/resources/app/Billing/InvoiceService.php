<?php

namespace App\Billing;

use App\Billing\Models\Invoice;
use App\Identity\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class InvoiceService
{
    public function createFor(int $userId, int $amountCents): Invoice
    {
        $user = User::findOrFail($userId);

        $roles = DB::table('roles')->where('user_id', $userId)->pluck('name');

        $rate = Http::get('https://fx.example.com/rates/EUR')->json('rate');

        return Invoice::create([
            'user_id' => $user->id,
            'email' => $user->email,
            'amount_cents' => (int) round($amountCents * $rate),
            'is_vip' => $roles->contains('vip'),
        ]);
    }
}
