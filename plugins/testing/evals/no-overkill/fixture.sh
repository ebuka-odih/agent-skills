#!/usr/bin/env bash
set -euo pipefail
G="git -c user.name=dev -c user.email=dev@example.invalid"
git init -q -b main
mkdir -p web/src/pages
printf 'export const BookButton = () => <button>Book</button>;\n' > web/src/pages/BookButton.tsx
printf 'import { render, screen } from "@testing-library/react";\nimport { BookButton } from "./BookButton";\nit("renders", () => { render(<BookButton />); expect(screen.getByRole("button", { name: "Book" })).toBeTruthy(); });\n' > web/src/pages/BookButton.test.tsx
$G add -A && $G commit -qm "chore: init"
$G switch -q -c fix/button-label
printf 'export const BookButton = () => <button>Book this class</button>;\n' > web/src/pages/BookButton.tsx
