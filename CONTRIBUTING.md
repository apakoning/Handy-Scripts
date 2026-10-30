# Contributing

Keep tools focused and document purpose, prerequisites, supported environment and side effects in the script catalogue. Do not commit credentials, cookies, real inventory reports or personal network logs.

- Use `bash -n` for shell syntax and `python3 -m py_compile` for Python syntax.
- Test configuration changes in a disposable environment; syntax checks do not prove they are safe or portable.
- Use quoted paths and explicit error handling. A failed external command must not produce a success message.
- Add regression checks for meaningful behaviour changes; mock privileged and network operations.
- Preserve third-party attribution and verify licensing before introducing copied code.
- Keep historical variants in `archive/` when replacing them with a maintained implementation.
