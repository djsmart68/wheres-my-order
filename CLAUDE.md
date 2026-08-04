# wheres-my-order

## Stack

- Node.js with Express, written in TypeScript that Node runs natively — there is no build step.
- No frontend framework; the browser-facing page stays plain HTML and JavaScript.

## TypeScript rules

- Erasable TypeScript syntax only: no enums, no namespaces, no parameter properties.
- Imports between our files use explicit `.ts` extensions (e.g. `import { foo } from "./foo.ts"`).
- `tsconfig.json` sets `erasableSyntaxOnly` and `noEmit`.
- Type-check with: `npx tsc --noEmit`

## Server

- The port comes from the `PORT` environment variable, defaulting to 3000.

## Dependencies

- Keep dependencies to an absolute minimum.

## Testing

- Tests use Node's built-in test runner (`node:test`).
- Run tests with: `npm test`
- Every endpoint gets at least one test.
