# Todo: Sevvn Guest TypeScript Migration

Plano completo em `tasks/plan-sevvn-guest-typescript-migration.md`.

## Phase 1: Foundation And Host App
- [x] Task 1: Define the new guest TypeScript app location and deployment shape
- [x] Task 2: Scaffold the new TypeScript guest app with repo conventions
- [x] Task 3: Extract and normalize guest API contracts for TypeScript
- [ ] Checkpoint: foundation reviewed and approved

## Phase 2: Template System And Shell
- [ ] Task 4: Build the guest shell architecture in TypeScript
- [ ] Task 5: Port the five Sevvn guest templates into a TypeScript theme/layout system
- [ ] Task 6: Port the guest claim/session bootstrap flow
- [ ] Checkpoint: shell reviewed and approved

## Phase 3: Core Vertical Slices
- [ ] Task 7: Ship the Home slice in TypeScript
- [ ] Task 8: Ship the Services directory slice in TypeScript
- [ ] Task 9: Ship service detail flows for room service, minibar, and reservations
- [ ] Checkpoint: core guest flow reviewed and approved

## Phase 4: Secondary Surfaces And Replacement Readiness
- [ ] Task 10: Port bookings, notices/messages, profile, and stay-bill surfaces
- [ ] Task 11: Align portal/admin links and QR entrypoints to the new guest app
- [ ] Task 12: Execute cutover readiness audit and Flutter retirement checklist
- [ ] Checkpoint: replacement readiness reviewed and approved

## First Execution Slice
- [x] Decide final repo path/name for the TypeScript guest app
- [x] Scaffold the app
- [x] Define typed API client layer
- [ ] Implement claim flow
- [ ] Implement template-aware shell
- [ ] Implement Home
- [ ] Implement Services list
