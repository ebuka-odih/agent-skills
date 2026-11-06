# Forms (react-hook-form + zod + shadcn Form)

```tsx
const schema = z.object({
  name: z.string().min(2, "At least 2 characters"),
  priceKobo: z.coerce.number().int().min(0),
  status: z.enum(["active", "archived"]),
});
type Values = z.infer<typeof schema>;

const form = useForm<Values>({ resolver: zodResolver(schema), defaultValues: { name: "", priceKobo: 0, status: "active" } });
const mutation = useUpdateClass();
const onSubmit = form.handleSubmit(async (v) => {
  try { await mutation.mutateAsync(v); toast.success("Class saved"); }
  catch (e) { applyServerErrors(form, e); }       // map API 422 field errors onto fields
});
```

## Rules
- One schema per form, ideally shared with or generated from the API contract.
- Labels always visible (no placeholder-only fields); helper text under the field; errors under the field in `text-destructive`.
- Submit button shows pending state and is disabled while submitting; Enter submits.
- Server validation errors land on the matching fields; unexpected errors show inline above the actions.
- Long forms: sections with headings; destructive actions separated from save.
- Money entered in major units, stored in minor units — convert in one helper.
