# Final verification

Run the selected stack's checks after scaffolding or reconciliation.

## Minimum report

State:

- Files created.
- Existing files changed.
- Existing files intentionally left intact.
- Decisions defaulted.
- Commands run and whether they passed.
- Commands not run and why.

## Verification rules

- Prefer the repo's documented verify command if one exists.
- Otherwise compose from the selected language/framework references.
- Run format/lint/type checks before test/build checks when that is practical.
- Do not claim green from config inspection alone.
