<!-- Managed by agent: keep sections and order; edit content, not structure. Last updated: {{TIMESTAMP}} -->

# AGENTS.md — {{SCOPE_NAME}}

## Overview
{{SCOPE_DESCRIPTION}}

## Setup & environment
- Install: `npm install` or `yarn install`
- Node version: {{NODE_VERSION}}
- Framework: {{FRAMEWORK}}
- Package manager: {{PACKAGE_MANAGER}}
- Environment variables: {{ENV_VARS}}

## Build & tests (prefer file-scoped)
- Typecheck a file: `npx tsc --noEmit {{FILE_PATH}}`
- Lint a file: `npx eslint {{FILE_PATH}}`
- Format a file: `npx prettier --write {{FILE_PATH}}`
- Test a file: `npm test {{FILE_PATH}}`
- Build: {{BUILD_CMD}}
- Dev server: {{DEV_CMD}}

## Code style & conventions
- TypeScript strict mode enabled
- Use functional components with hooks (React)
- Naming: `camelCase` for variables/functions, `PascalCase` for components
- File naming: `ComponentName.tsx`, `utilityName.ts`
- Imports: group and sort (external, internal, types)
- CSS: {{CSS_APPROACH}} (CSS Modules, Tailwind, styled-components, etc.)
{{FRAMEWORK_CONVENTIONS}}

## Security & safety
- Sanitize user inputs before rendering
- Use `dangerouslySetInnerHTML` only with sanitized content
- Validate environment variables at build time
- Never expose secrets in client-side code
- Use HTTPS for all API calls
- Implement CSP headers
- WCAG 2.2 AA accessibility compliance

## PR/commit checklist
- [ ] Tests pass: `npm test`
- [ ] TypeScript compiles: `npx tsc --noEmit`
- [ ] Lint clean: `npm run lint`
- [ ] Formatted: `npm run format`
- [ ] Accessibility: keyboard navigation works, ARIA labels present
- [ ] Responsive: tested on mobile, tablet, desktop
- [ ] Performance: no unnecessary re-renders

## Good vs. bad examples
**Good**: Proper TypeScript typing
```typescript
interface User {
  id: string;
  name: string;
  email: string;
}

function UserCard({ user }: { user: User }): JSX.Element {
  return <div>{user.name}</div>;
}
```

**Bad**: Using `any`
```typescript
function UserCard({ user }: { user: any }) {
  return <div>{user.name}</div>;
}
```

**Good**: Accessible button
```tsx
<button
  onClick={handleClick}
  aria-label="Close dialog"
  type="button"
>
  <CloseIcon />
</button>
```

**Bad**: Non-semantic click handler
```tsx
<div onClick={handleClick}>
  <CloseIcon />
</div>
```

## When stuck
- Check {{FRAMEWORK}} documentation: {{FRAMEWORK_DOCS}}
- Review TypeScript handbook: https://www.typescriptlang.org/docs/
- Check root AGENTS.md for project-wide conventions
- Review existing components for patterns

## House Rules (optional)
{{HOUSE_RULES}}
