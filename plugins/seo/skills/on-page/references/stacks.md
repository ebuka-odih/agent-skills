# Head tags by stack

## Laravel (Blade)
```blade
{{-- resources/views/layouts/public.blade.php --}}
<title>{{ $seo->title }}</title>
<meta name="description" content="{{ $seo->description }}">
<link rel="canonical" href="{{ $seo->canonical }}">
@if($seo->noindex)<meta name="robots" content="noindex,follow">@endif
<meta property="og:title" content="{{ $seo->title }}">
<meta property="og:description" content="{{ $seo->description }}">
<meta property="og:image" content="{{ $seo->image }}">
<meta name="twitter:card" content="summary_large_image">
@isset($seo->jsonLd)<script type="application/ld+json">{!! json_encode($seo->jsonLd, JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE) !!}</script>@endisset
```
Build `$seo` in the controller (or a `SeoData` DTO per page type); canonical via `url()->route(...)` without query string. Inertia: SSR on + `<Head>` per page.

## React (Vite + prerender / SSR)
```tsx
// React 19: these tags are hoisted into <head> during render/prerender
export function SeoHead({ title, description, canonical, image, noindex, jsonLd }: SeoProps) {
  return (<>
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href={canonical} />
    {noindex && <meta name="robots" content="noindex,follow" />}
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={image} />
    <meta name="twitter:card" content="summary_large_image" />
    {jsonLd && <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />}
  </>);
}
```
Verify the **prerendered HTML file** contains them (not just the browser DOM).

## Next.js
`export async function generateMetadata({ params })` returning `title`, `description`, `alternates.canonical`, `robots`, `openGraph`; JSON-LD in the page as a `<script type="application/ld+json">`.
