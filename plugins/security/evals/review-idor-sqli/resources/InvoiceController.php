<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class InvoiceController extends Controller
{
    public function show(Invoice $invoice)
    {
        return $invoice;
    }

    public function search(Request $request)
    {
        $q = $request->input('q');
        return DB::select("select * from invoices where tenant_id = {$request->user()->tenant_id} and number like '%$q%'");
    }

    public function update(Request $request, Invoice $invoice)
    {
        $this->authorize('update', $invoice);
        $invoice->update($request->all());
        return $invoice;
    }

    public function stripeWebhook(Request $request)
    {
        $event = json_decode($request->getContent(), true);
        if ($event['type'] === 'invoice.paid') {
            Invoice::where('stripe_id', $event['data']['object']['id'])->update(['status' => 'paid']);
        }
        return response()->noContent();
    }
}
