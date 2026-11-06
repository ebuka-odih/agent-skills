#!/usr/bin/env bash
set -euo pipefail
mkdir -p resources/views/cafes resources/views/layouts app/Models
cat > app/Models/Cafe.php <<'P'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
/**
 * @property string $name  @property string $slug  @property string $street  @property string $area
 * @property string $city  @property string $postcode  @property string $country_code
 * @property float $lat  @property float $lng  @property string|null $phone  @property string $price_range
 * @property array $hours  e.g. ['mo' => ['08:00','18:00'], 'sa' => ['09:00','15:00'], 'su' => null]
 * @property string|null $photo_url  @property string|null $website
 */
class Cafe extends Model { protected $casts = ['hours' => 'array']; }
P
cat > resources/views/layouts/app.blade.php <<'L'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>@yield('title')</title>
  @stack('head')
</head>
<body>@yield('content')</body>
</html>
L
cat > resources/views/cafes/show.blade.php <<'B'
@extends('layouts.app')
@section('title', $cafe->name.', '.$cafe->area.' — hours, menu and prices')
@section('content')
  <h1>{{ $cafe->name }}</h1>
  <p>{{ $cafe->street }}, {{ $cafe->area }}, {{ $cafe->city }}</p>
  <p>Price: {{ $cafe->price_range }}</p>
  @if($cafe->photo_url)<img src="{{ $cafe->photo_url }}" alt="{{ $cafe->name }}">@endif
  <ul>
    @foreach($cafe->hours as $day => $span)
      <li>{{ strtoupper($day) }}: {{ $span ? $span[0].'–'.$span[1] : 'Closed' }}</li>
    @endforeach
  </ul>
@endsection
B
