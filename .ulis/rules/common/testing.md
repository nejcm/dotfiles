# Testing

- **Coverage ≥ 80%.** Unit (functions/utils/components) + Integration (API/DB) + E2E (critical flows).
- **TDD (mandatory):** write failing test (RED) → minimal impl (GREEN) → refactor → verify coverage. Use tdd-guide.
- **Failures:** check isolation & mocks; fix implementation, not tests (unless the test is wrong).
- **Structure:** Arrange-Act-Assert.
- **Names** describe behavior: `"throws error when API key is missing"`, `"returns empty array when no markets match query"`.
