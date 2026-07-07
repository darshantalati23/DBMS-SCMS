"""
test_cli.py — Pillar C: CLI Subprocess I/O Automation Testing
=============================================================

WHY THESE TESTS EXIST
----------------------
The CLI (src/scms_cli.py) is the user-facing layer of the system. These tests
verify it end-to-end WITHOUT manual interaction -- they launch the CLI as a
real subprocess, pipe commands into its stdin, and assert on stdout.

This pillar demonstrates you understand:
  1. How to automate testing of interactive terminal programs
  2. How to use subprocess.run() for integration testing (no mocking)
  3. How to structure assertions on terminal output

APPROACH:
  - subprocess.run() launches python src/scms_cli.py with DB creds from env vars
  - Commands are written to stdin as a single bytes block (newline-separated)
  - stdout + stderr are captured and decoded; we assert on substrings
  - The CLI always exits cleanly because we pipe "exit" as the last command

WINDOWS / NON-TTY NOTE:
  prompt_toolkit requires a real Win32 console to initialise its Win32Output.
  When launched as a subprocess with piped stdin/stdout (no attached console),
  it raises NoConsoleScreenBufferError. We work around this by setting three
  environment variables before launching the subprocess:
    - NO_COLOR=1               : makes rich emit plain text (no ANSI escape codes)
    - TERM=dumb                : signals a dumb (non-interactive) terminal
    - PROMPT_TOOLKIT_NO_CPR=1  : disables cursor-position requests
  Together these cause prompt_toolkit to fall back from Win32Output to its
  plain-text output path, which works safely when stdout is a pipe.
"""

import os
import subprocess
import sys
import pytest

# ---- Path to the CLI script --------------------------------------------------
CLI_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "src", "scms_cli.py")
)


# ---- Helper: run the CLI with given commands piped into stdin ----------------

def run_cli(*commands: str, timeout: int = 30) -> subprocess.CompletedProcess:
    """
    Launch scms_cli.py as a subprocess, pipe the given commands through stdin,
    and return the CompletedProcess result with stdout/stderr captured.

    Commands are joined with newlines; 'exit' is always appended so the
    CLI terminates cleanly without hanging.

    DB credentials are passed via environment variables so no password prompt
    appears during the test run.
    """
    stdin_payload = "\n".join(list(commands) + ["exit"]) + "\n"

    env = os.environ.copy()
    # These three vars together bypass the Win32 console requirement
    env["NO_COLOR"] = "1"               # rich -> plain text output (no ANSI)
    env["TERM"] = "dumb"                # prompt_toolkit -> non-interactive mode
    env["PROMPT_TOOLKIT_NO_CPR"] = "1"  # disable cursor position requests

    result = subprocess.run(
        [sys.executable, CLI_PATH],
        input=stdin_payload.encode("utf-8"),
        capture_output=True,
        timeout=timeout,
        env=env,
    )
    return result


def _decode(result: subprocess.CompletedProcess) -> str:
    """
    Decode stdout + stderr into a single string for easy assertions.
    Uses the system's preferred encoding with 'replace' error handling
    to safely handle Windows cp1252 / Unicode mismatches in terminal output.
    """
    enc = sys.stdout.encoding or "utf-8"
    out = result.stdout.decode(enc, errors="replace")
    err = result.stderr.decode(enc, errors="replace")
    return out + err


# ---- Skip all CLI tests if PGPASSWORD is not set ----------------------------

def _skip_if_no_password():
    if not os.environ.get("PGPASSWORD"):
        pytest.skip(
            "PGPASSWORD not set -- CLI tests require a live DB connection.\n"
            "Set it with: $env:PGPASSWORD='your_password'  (PowerShell)"
        )


# =============================================================================
#  C-1 : .tables command lists all expected SCMS tables
# =============================================================================

@pytest.mark.cli
def test_cli_tables_command():
    """
    WHAT WE TEST: The '.tables' special command queries information_schema
    and returns all tables in the scms schema.

    ASSERTION: A representative sample of known table names must appear in
    the CLI's rendered output. This proves:
      1. The CLI connected to the DB successfully
      2. The schema is loaded and accessible
      3. The .tables command renders output correctly
    """
    _skip_if_no_password()

    result = run_cli(".tables")
    output = _decode(result)

    expected_tables = [
        "inventory",
        "purchase_order",
        "sales_order",
        "shipment",
        "supplier",
        "warehouse",
        "batch",
        "product",
        # New tables from schema v2
        "inter_warehouse_transfer",
        "transfer_item",
        "delivery_tracking",
        "delivery_event",
    ]
    for table in expected_tables:
        assert table in output, (
            f"Expected table '{table}' to appear in .tables output.\n"
            f"Got:\n{output[:800]}"
        )


# =============================================================================
#  C-2 : .enums command lists all ENUM types defined in the schema
# =============================================================================

@pytest.mark.cli
def test_cli_enums_command():
    """
    WHAT WE TEST: The '.enums' command queries pg_type and pg_enum to list
    all custom ENUM types in the scms schema.

    ASSERTION: Key ENUM names must appear in the output. This demonstrates
    that ENUM types are first-class citizens in the schema design (not just
    VARCHAR columns with application-level validation).
    """
    _skip_if_no_password()

    result = run_cli(".enums")
    output = _decode(result)

    expected_enums = [
        "po_status_enum",
        "so_status_enum",
        "shipment_status_enum",
        "supplier_tier_enum",
        "movement_type_enum",
        # New ENUMs from schema v2
        "transfer_status_enum",
        "delivery_event_type_enum",
    ]
    for enum_name in expected_enums:
        assert enum_name in output, (
            f"Expected ENUM '{enum_name}' in .enums output.\n"
            f"Got:\n{output[:800]}"
        )


# =============================================================================
#  C-3 : .help command renders the help panel with all documented commands
# =============================================================================

@pytest.mark.cli
def test_cli_help_command():
    """
    WHAT WE TEST: The '.help' command renders a panel containing all special
    commands that the CLI supports.

    ASSERTION: Key command strings must be present in the output.
    This is a smoke test that the help system is up to date with the
    actual implemented feature set.
    """
    _skip_if_no_password()

    result = run_cli(".help")
    output = _decode(result)

    help_indicators = [".tables", ".schema", ".enums", ".export", ".timing", "exit"]
    for indicator in help_indicators:
        assert indicator in output, (
            f"Expected '{indicator}' to appear in .help output.\n"
            f"Got:\n{output[:800]}"
        )


# =============================================================================
#  C-4 : .schema command shows table summary with column counts
# =============================================================================

@pytest.mark.cli
def test_cli_schema_command():
    """
    WHAT WE TEST: The '.schema' command queries information_schema for a
    summary of each table -- column count, PK count, FK count.

    ASSERTION: Known tables appear in the output. This proves the schema
    introspection queries are working correctly end-to-end.
    """
    _skip_if_no_password()

    result = run_cli(".schema")
    output = _decode(result)

    for table in ["inventory", "warehouse", "product", "supplier"]:
        assert table in output, (
            f"Expected table '{table}' in .schema output.\n"
            f"Got:\n{output[:800]}"
        )


# =============================================================================
#  C-5 : Malformed SQL is handled gracefully -- no unhandled crash
# =============================================================================

@pytest.mark.cli
def test_cli_invalid_sql_handled_gracefully():
    """
    WHAT WE TEST: When a user submits syntactically invalid SQL, the CLI
    must handle the psycopg2 error cleanly -- display an error message and
    continue running, without crashing.

    ASSERTION:
      - The output must NOT contain 'Traceback' (no unhandled Python exception)
      - The output must contain 'ERROR' (the CLI's error display)

    WHY TEST THIS: Error handling is a quality signal. An uncaught exception
    that kills the CLI is far worse than a clean error message. This proves
    the run_query() error handler works correctly.
    """
    _skip_if_no_password()

    result = run_cli("THIS IS NOT VALID SQL;")
    output = _decode(result)

    assert "Traceback" not in output, (
        "CLI should NOT crash with a Python traceback on invalid SQL.\n"
        f"Got:\n{output[:1000]}"
    )
    assert "ERROR" in output.upper(), (
        "CLI should display an ERROR message for invalid SQL.\n"
        f"Got:\n{output[:800]}"
    )


# =============================================================================
#  C-6 : A valid SELECT query returns rows and a row-count summary
# =============================================================================

@pytest.mark.cli
def test_cli_select_query():
    """
    WHAT WE TEST: A valid SELECT query against seeded data returns rows
    and the CLI renders a row count summary.

    ASSERTION: The output contains:
      - At least one warehouse name from the seed data
      - A 'row(s)' summary line (the CLI's standard result footer)

    WHY TEST THIS: This is the "happy path" integration test -- it proves that
    the full pipeline (user input -> SQL execution -> result rendering) works
    correctly when given valid input.
    """
    _skip_if_no_password()

    result = run_cli(
        "SELECT warehouse_code, warehouse_name FROM warehouse ORDER BY warehouse_id;"
    )
    output = _decode(result)

    # Seed data contains 'Mumbai Central Hub' -- it must appear in output
    assert "Mumbai" in output, (
        "Expected seed data ('Mumbai') to appear in SELECT output.\n"
        f"Got:\n{output[:800]}"
    )
    assert "row(s)" in output, (
        "Expected a 'row(s)' summary line in SELECT output.\n"
        f"Got:\n{output[:800]}"
    )


# =============================================================================
#  C-7 : CLI exits cleanly with exit code 0 on 'exit' command
# =============================================================================

@pytest.mark.cli
def test_cli_clean_exit():
    """
    WHAT WE TEST: Typing 'exit' causes the CLI to exit with return code 0
    and print the goodbye message.

    WHY TEST THIS: A non-zero exit code from the CLI would break any shell
    script or CI pipeline that runs it. This is a basic robustness check.
    """
    _skip_if_no_password()

    result = run_cli()  # No commands -- just 'exit' appended by run_cli()
    output = _decode(result)

    assert result.returncode == 0, (
        f"CLI should exit with code 0, got {result.returncode}.\n"
        f"stderr: {result.stderr.decode(errors='replace')[:500]}"
    )
    assert "Bye" in output, (
        "CLI should print 'Bye!' on exit.\n"
        f"Got:\n{output[:400]}"
    )
