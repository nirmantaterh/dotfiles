# Personal Engineering Rules
- Verification is more important than generation.
- Never claim a test passed unless run this session; report command and exit code.
- Reproduce bugs before fixing them. Keep the reproduction as a regression test.
- Write TASK, CONTEXT, and VERIFY before implementation.
- Prefer the smallest diff satisfying VERIFY. No speculative abstractions or dependencies.
- Read repository instructions and inspect the working tree before acting.
- Plan before editing more than two files; wait for approval.
- Finish with a verification report, max 3 lines: what ran, pass/fail, anything NOT VERIFIED. Show the diff only if asked.
- Never merge, force-push, deploy, or edit CI/infra/shared configuration without explicit approval.
- Do not commit or post on teammates' PRs unless explicitly asked.
- Only when the user says "learning mode": explain the mechanism and let the user write or reason through core logic. Otherwise just do the work.

@RTK.md
