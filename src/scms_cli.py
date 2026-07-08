#!/usr/bin/env python3
"""
SCMS — Supply Chain Management System  CLI
==========================================
A pgAdmin-style interactive terminal client for the scms PostgreSQL schema.

Usage:
    python scms_cli.py
    python scms_cli.py --host localhost --port 5432 --dbname yourdb --user youruser

Special commands (type these at the prompt):
    .tables            — list all tables in the scms schema
    .schema            — show schema summary (table + column count)
    \\d <table>         — describe a table (columns, types, constraints)
    \\di <table>        — show indexes on a table
    \\df                — list all functions/procedures in scms schema
    \\dv                — list all views in scms schema
    .enums             — list all custom ENUM types and their values
    .search <keyword>  — search table/column names for a keyword
    .export <file>     — export last query result to a CSV file
    .ask <query>       — use Gemini Flash Lite to generate SQL from English
    .timing on/off     — toggle query execution time display
    .clear             — clear the terminal screen
    .help              — show this help
    exit / quit / \\q   — exit the CLI
"""

import argparse
import csv
import io
import os
import sys
import time
import traceback
from datetime import datetime

# ── Dependency check ────────────────────────────────────────────────────────

def _check_deps():
    missing = []
    for pkg in ("psycopg2", "rich", "prompt_toolkit"):
        try:
            __import__(pkg)
        except ImportError:
            missing.append(pkg)
    if missing:
        print("Missing required packages. Install them with:")
        print(f"  pip install {' '.join(missing)}")
        sys.exit(1)

_check_deps()

import psycopg2
import psycopg2.extras
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text
from rich.syntax import Syntax
from rich import box
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.styles import Style
from prompt_toolkit.formatted_text import HTML

# ── Constants ────────────────────────────────────────────────────────────────

SCHEMA = "scms"

SCMS_TABLES = [
    "audit_log", "batch", "customer", "delivery_event", "delivery_tracking",
    "inter_warehouse_transfer", "inventory", "inventory_allocation",
    "inventory_movement_log", "po_item", "product", "product_category",
    "purchase_order", "reorder_alert", "return_item", "return_request",
    "sales_order", "shipment", "shipment_item", "so_item", "staff",
    "supplier", "supplies", "transfer_item", "warehouse", "warehouse_zone",
]

SQL_KEYWORDS = [
    "SELECT", "FROM", "WHERE", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER",
    "ON", "AND", "OR", "NOT", "IN", "IS", "NULL", "ORDER", "BY", "GROUP",
    "HAVING", "LIMIT", "OFFSET", "INSERT", "INTO", "VALUES", "UPDATE",
    "SET", "DELETE", "CREATE", "DROP", "ALTER", "TABLE", "INDEX", "VIEW",
    "WITH", "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MIN", "MAX",
    "CASE", "WHEN", "THEN", "ELSE", "END", "CAST", "COALESCE",
    "RETURNING", "EXISTS", "BETWEEN", "LIKE", "ILIKE",
]

SPECIAL_COMMANDS = [
    ".tables", ".schema", ".enums", ".help", ".clear",
    ".timing on", ".timing off",
    r"\d ", r"\di ", r"\df", r"\dv", ".search ", ".export ", ".ask ",
    "exit", "quit", r"\q",
]

HISTORY_FILE = os.path.expanduser("~/.scms_cli_history")

# ── Console ──────────────────────────────────────────────────────────────────

console = Console()

PROMPT_STYLE = Style.from_dict({
    "prompt.schema": "#00afd7 bold",
    "prompt.arrow": "#888888",
})

# ── Connection ───────────────────────────────────────────────────────────────

def get_connection(args):
    """Establish a psycopg2 connection, prompting for password if needed."""
    import getpass

    host     = args.host     or os.environ.get("PGHOST",     "localhost")
    port     = args.port     or os.environ.get("PGPORT",     "5432")
    dbname   = args.dbname   or os.environ.get("PGDATABASE", "postgres")
    user     = args.user     or os.environ.get("PGUSER",     os.getenv("USER", "postgres"))
    password = args.password or os.environ.get("PGPASSWORD", None)

    if password is None:
        password = getpass.getpass(f"Password for {user}@{host}/{dbname}: ")

    try:
        conn = psycopg2.connect(
            host=host, port=int(port), dbname=dbname,
            user=user, password=password,
            options=f"-c search_path={SCHEMA},public",
        )
        conn.autocommit = False
        return conn, host, port, dbname, user
    except psycopg2.OperationalError as e:
        console.print(f"[bold red]Connection failed:[/bold red] {e}")
        sys.exit(1)

# ── Result rendering ─────────────────────────────────────────────────────────

def render_results(cursor, elapsed_ms: float, timing_on: bool):
    """Pretty-print query results using rich tables."""
    if cursor.description is None:
        # DML / DDL — show affected rows
        rowcount = cursor.rowcount if cursor.rowcount >= 0 else 0
        msg = f"[bold green]Query OK.[/bold green] {rowcount} row(s) affected."
        if timing_on:
            msg += f"  [dim]({elapsed_ms:.1f} ms)[/dim]"
        console.print(msg)
        return None          # nothing to export

    rows = cursor.fetchall()
    col_names = [d[0] for d in cursor.description]

    if not rows:
        msg = "[yellow]No rows returned.[/yellow]"
        if timing_on:
            msg += f"  [dim]({elapsed_ms:.1f} ms)[/dim]"
        console.print(msg)
        return None

    tbl = Table(
        box=box.SIMPLE_HEAVY,
        show_header=True,
        header_style="bold cyan",
        border_style="bright_black",
        row_styles=["", "dim"],   # alternating
        show_lines=False,
    )

    for col in col_names:
        tbl.add_column(col, overflow="fold", no_wrap=False)

    for row in rows:
        tbl.add_row(*[_fmt(v) for v in row])

    console.print(tbl)

    summary = f"[bold green]{len(rows)}[/bold green] row(s)"
    if timing_on:
        summary += f"  [dim]({elapsed_ms:.1f} ms)[/dim]"
    console.print(summary)

    return col_names, rows   # for .export


def _fmt(value) -> str:
    """Format a Python value for table display."""
    if value is None:
        return "[dim italic]NULL[/dim italic]"
    if isinstance(value, bool):
        return "[green]true[/green]" if value else "[red]false[/red]"
    if isinstance(value, (int, float)):
        return str(value)
    return str(value)

# ── Special commands ─────────────────────────────────────────────────────────

def cmd_tables(conn):
    sql = """
        SELECT table_name,
               (SELECT COUNT(*) FROM information_schema.columns c
                WHERE  c.table_schema = t.table_schema
                AND    c.table_name   = t.table_name) AS columns
        FROM   information_schema.tables t
        WHERE  table_schema = %s
        ORDER  BY table_name;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA,))
        rows = cur.fetchall()

    tbl = Table(title=f"Tables in schema '{SCHEMA}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("#",          style="dim", justify="right")
    tbl.add_column("Table Name", style="bold white")
    tbl.add_column("Columns",    justify="right")

    for i, (name, cols) in enumerate(rows, 1):
        tbl.add_row(str(i), name, str(cols))

    console.print(tbl)
    console.print(f"[bold green]{len(rows)}[/bold green] tables")


def cmd_schema_summary(conn):
    sql = """
        SELECT t.table_name,
               COUNT(c.column_name)  AS col_count,
               COUNT(tc.constraint_name) FILTER (
                   WHERE tc.constraint_type = 'PRIMARY KEY') AS pk,
               COUNT(tc.constraint_name) FILTER (
                   WHERE tc.constraint_type = 'FOREIGN KEY')  AS fk
        FROM   information_schema.tables t
        JOIN   information_schema.columns c
               ON  c.table_schema = t.table_schema
               AND c.table_name   = t.table_name
        LEFT JOIN information_schema.table_constraints tc
               ON  tc.table_schema = t.table_schema
               AND tc.table_name   = t.table_name
        WHERE  t.table_schema = %s
        GROUP  BY t.table_name
        ORDER  BY t.table_name;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA,))
        rows = cur.fetchall()

    tbl = Table(title=f"Schema Summary — '{SCHEMA}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("Table",   style="bold white")
    tbl.add_column("Columns", justify="right")
    tbl.add_column("PK",      justify="right")
    tbl.add_column("FK",      justify="right")

    for name, cols, pk, fk in rows:
        tbl.add_row(name, str(cols), str(pk), str(fk))

    console.print(tbl)


def cmd_describe(conn, table_name: str):
    # Columns
    sql_cols = """
        SELECT column_name,
               data_type ||
                   CASE WHEN character_maximum_length IS NOT NULL
                        THEN '(' || character_maximum_length || ')'
                        ELSE '' END                              AS type,
               CASE WHEN is_nullable = 'NO' THEN 'NOT NULL' ELSE '' END AS nullable,
               COALESCE(column_default, '')                     AS default_val
        FROM   information_schema.columns
        WHERE  table_schema = %s AND table_name = %s
        ORDER  BY ordinal_position;
    """
    # Constraints
    sql_cons = """
        SELECT tc.constraint_name, tc.constraint_type,
               STRING_AGG(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS cols
        FROM   information_schema.table_constraints tc
        JOIN   information_schema.key_column_usage kcu
               ON  kcu.constraint_name  = tc.constraint_name
               AND kcu.table_schema     = tc.table_schema
        WHERE  tc.table_schema = %s AND tc.table_name = %s
        GROUP  BY tc.constraint_name, tc.constraint_type
        ORDER  BY tc.constraint_type, tc.constraint_name;
    """
    with conn.cursor() as cur:
        cur.execute(sql_cols, (SCHEMA, table_name))
        cols = cur.fetchall()
        cur.execute(sql_cons, (SCHEMA, table_name))
        cons = cur.fetchall()

    if not cols:
        console.print(f"[yellow]Table '{table_name}' not found in schema '{SCHEMA}'.[/yellow]")
        return

    col_tbl = Table(title=f"\\d {SCHEMA}.{table_name}", box=box.SIMPLE_HEAVY,
                    header_style="bold cyan", border_style="bright_black")
    col_tbl.add_column("Column",   style="bold white")
    col_tbl.add_column("Type")
    col_tbl.add_column("Nullable", justify="center")
    col_tbl.add_column("Default")

    for col, dtype, nullable, default in cols:
        col_tbl.add_row(col, dtype,
                        "[red]✗[/red]" if nullable else "[green]✓[/green]",
                        default or "")
    console.print(col_tbl)

    if cons:
        con_tbl = Table(title="Constraints", box=box.SIMPLE_HEAVY,
                        header_style="bold magenta", border_style="bright_black")
        con_tbl.add_column("Name")
        con_tbl.add_column("Type")
        con_tbl.add_column("Columns")
        for cname, ctype, ccols in cons:
            style = {"PRIMARY KEY": "bold yellow",
                     "FOREIGN KEY": "cyan",
                     "UNIQUE":      "green",
                     "CHECK":       "magenta"}.get(ctype, "white")
            con_tbl.add_row(cname, f"[{style}]{ctype}[/{style}]", ccols)
        console.print(con_tbl)


def cmd_indexes(conn, table_name: str):
    sql = """
        SELECT indexname, indexdef
        FROM   pg_indexes
        WHERE  schemaname = %s AND tablename = %s
        ORDER  BY indexname;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA, table_name))
        rows = cur.fetchall()

    if not rows:
        console.print(f"[yellow]No indexes found for '{table_name}'.[/yellow]")
        return

    tbl = Table(title=f"Indexes on {table_name}", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("Index Name", style="bold white")
    tbl.add_column("Definition")
    for name, defn in rows:
        tbl.add_row(name, defn)
    console.print(tbl)


def cmd_functions(conn):
    sql = """
        SELECT routine_name, routine_type, data_type AS return_type
        FROM   information_schema.routines
        WHERE  routine_schema = %s
        ORDER  BY routine_name;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA,))
        rows = cur.fetchall()

    if not rows:
        console.print(f"[yellow]No functions/procedures found in schema '{SCHEMA}'.[/yellow]")
        return

    tbl = Table(title=f"Functions in '{SCHEMA}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("Name")
    tbl.add_column("Type")
    tbl.add_column("Returns")
    for name, rtype, ret in rows:
        tbl.add_row(name, rtype, ret or "")
    console.print(tbl)


def cmd_views(conn):
    sql = """
        SELECT table_name AS view_name, view_definition
        FROM   information_schema.views
        WHERE  table_schema = %s
        ORDER  BY table_name;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA,))
        rows = cur.fetchall()

    if not rows:
        console.print(f"[yellow]No views found in schema '{SCHEMA}'.[/yellow]")
        return

    tbl = Table(title=f"Views in '{SCHEMA}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("View Name", style="bold white")
    tbl.add_column("Definition", overflow="fold")
    for name, defn in rows:
        tbl.add_row(name, (defn or "")[:120] + ("…" if defn and len(defn) > 120 else ""))
    console.print(tbl)


def cmd_enums(conn):
    sql = """
        SELECT t.typname AS enum_name,
               STRING_AGG(e.enumlabel, ', ' ORDER BY e.enumsortorder) AS values
        FROM   pg_type t
        JOIN   pg_enum e ON e.enumtypid = t.oid
        JOIN   pg_catalog.pg_namespace n ON n.oid = t.typnamespace
        WHERE  n.nspname = %s
        GROUP  BY t.typname
        ORDER  BY t.typname;
    """
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA,))
        rows = cur.fetchall()

    if not rows:
        console.print(f"[yellow]No ENUM types found in schema '{SCHEMA}'.[/yellow]")
        return

    tbl = Table(title=f"ENUM types in '{SCHEMA}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("ENUM Name", style="bold white")
    tbl.add_column("Values")
    for name, vals in rows:
        tbl.add_row(name, vals)
    console.print(tbl)


def cmd_search(conn, keyword: str):
    sql = """
        SELECT table_name, column_name, data_type
        FROM   information_schema.columns
        WHERE  table_schema = %s
        AND   (table_name  ILIKE %s OR column_name ILIKE %s)
        ORDER  BY table_name, ordinal_position;
    """
    pat = f"%{keyword}%"
    with conn.cursor() as cur:
        cur.execute(sql, (SCHEMA, pat, pat))
        rows = cur.fetchall()

    if not rows:
        console.print(f"[yellow]No tables/columns matching '{keyword}'.[/yellow]")
        return

    tbl = Table(title=f"Search: '{keyword}'", box=box.SIMPLE_HEAVY,
                header_style="bold cyan", border_style="bright_black")
    tbl.add_column("Table",  style="bold white")
    tbl.add_column("Column")
    tbl.add_column("Type")
    for t, c, d in rows:
        kw = keyword.lower()
        tname = f"[bold yellow]{t}[/bold yellow]" if kw in t.lower() else t
        cname = f"[bold yellow]{c}[/bold yellow]" if kw in c.lower() else c
        tbl.add_row(tname, cname, d)
    console.print(tbl)

def cmd_ask(conn, natural_query: str):
    if not os.environ.get("GEMINI_API_KEY"):
        console.print("[bold red]GEMINI_API_KEY environment variable is not set.[/bold red]")
        console.print("Please set it in your terminal: [bold cyan]$env:GEMINI_API_KEY=\"your_key\"[/bold cyan]")
        return None

    try:
        from google import genai
        client = genai.Client()
    except Exception as e:
        console.print(f"[bold red]Failed to initialize Gemini Client: {e}[/bold red]")
        console.print("[dim]Make sure you ran: pip install google-genai[/dim]")
        return None
        
    schema_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'db', 'schema.sql')
    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            schema_content = f.read()
    except Exception as e:
        console.print(f"[bold red]Could not read schema.sql: {e}[/bold red]")
        return None
        
    prompt = f"""
You are an expert PostgreSQL developer. Write a raw PostgreSQL query based on the user's natural language request.
The database uses the 'scms' schema (already in search_path, do not prefix tables with scms.).
Here is the complete schema context:
```sql
{schema_content}
```
User request: {natural_query}

CRITICAL RULES:
1. ONLY return the raw SQL query. Do not wrap it in markdown code blocks like ```sql. Do not add any explanation or comments.
2. The query must end with a semicolon.
3. Validate the request against the schema. If the request is impossible or lacks required columns, return a SELECT statement returning a single string column that explains why it's impossible.
"""
    console.print(f"[dim]Asking Gemini Flash Lite...[/dim]")
    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash-lite',
            contents=prompt,
        )
        sql_query = response.text.strip()
        if sql_query.startswith("```sql"):
            sql_query = sql_query[6:]
        if sql_query.startswith("```"):
            sql_query = sql_query[3:]
        if sql_query.endswith("```"):
            sql_query = sql_query[:-3]
        sql_query = sql_query.strip()
        
        console.print("[bold magenta]Gemini Generated SQL:[/bold magenta]")
        console.print(f"[bold cyan]{sql_query}[/bold cyan]\n")
        return sql_query
    except Exception as e:
        console.print(f"[bold red]Gemini API request failed: {e}[/bold red]")
        return None

    console.print(f"[bold green]{len(rows)}[/bold green] match(es)")


def cmd_export(last_result, filename: str):
    if last_result is None:
        console.print("[yellow]No result to export. Run a SELECT query first.[/yellow]")
        return
    col_names, rows = last_result
    try:
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(col_names)
            for row in rows:
                writer.writerow(["" if v is None else str(v) for v in row])
        console.print(f"[bold green]Exported {len(rows)} rows → {filename}[/bold green]")
    except OSError as e:
        console.print(f"[bold red]Export failed:[/bold red] {e}")


def cmd_help():
    help_text = """
[bold cyan].tables[/bold cyan]              List all tables in the scms schema
[bold cyan].schema[/bold cyan]              Schema summary (columns, PK, FK per table)
[bold cyan]\\d <table>[/bold cyan]           Describe a table (columns + constraints)
[bold cyan]\\di <table>[/bold cyan]          Show indexes on a table
[bold cyan]\\df[/bold cyan]                  List functions/procedures
[bold cyan]\\dv[/bold cyan]                  List views
[bold cyan].enums[/bold cyan]               List all ENUM types and their values
[bold cyan].search <keyword>[/bold cyan]    Search table/column names
[bold cyan].export <file.csv>[/bold cyan]   Export last query result to CSV
[bold cyan].timing on|off[/bold cyan]       Toggle execution time display
[bold cyan].clear[/bold cyan]               Clear the screen
[bold cyan]exit / quit / \\q[/bold cyan]     Exit the CLI

[dim]Multi-line queries: end your statement with ; to execute.
Press Ctrl+C to cancel current input.
Press Ctrl+D to exit.[/dim]
"""
    console.print(Panel(help_text, title="[bold]SCMS CLI — Help[/bold]",
                        border_style="cyan", padding=(0, 2)))

# ── Query runner ─────────────────────────────────────────────────────────────

def run_query(conn, sql: str, timing_on: bool):
    """Execute SQL and display results. Returns (col_names, rows) or None."""
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            t0 = time.perf_counter()
            cur.execute(sql)
            elapsed = (time.perf_counter() - t0) * 1000

            if cur.description is None:
                rowcount = cur.rowcount if cur.rowcount >= 0 else 0
                msg = f"[bold green]Query OK.[/bold green] {rowcount} row(s) affected."
                if timing_on:
                    msg += f"  [dim]({elapsed:.1f} ms)[/dim]"
                console.print(msg)
                conn.commit()
                return None

            rows_dict = cur.fetchall()
            col_names = list(rows_dict[0].keys()) if rows_dict else \
                        [d[0] for d in cur.description]

            # Convert RealDictRow → plain lists
            rows = [list(r.values()) for r in rows_dict]

        conn.commit()

        if not rows:
            msg = "[yellow]No rows returned.[/yellow]"
            if timing_on:
                msg += f"  [dim]({elapsed:.1f} ms)[/dim]"
            console.print(msg)
            return None

        tbl = Table(
            box=box.SIMPLE_HEAVY,
            show_header=True,
            header_style="bold cyan",
            border_style="bright_black",
            row_styles=["", "dim"],
            show_lines=False,
        )
        for col in col_names:
            tbl.add_column(str(col), overflow="fold")

        for row in rows:
            tbl.add_row(*[_fmt(v) for v in row])

        console.print(tbl)
        summary = f"[bold green]{len(rows)}[/bold green] row(s)"
        if timing_on:
            summary += f"  [dim]({elapsed:.1f} ms)[/dim]"
        console.print(summary)

        return col_names, rows

    except psycopg2.Error as e:
        conn.rollback()
        console.print(f"[bold red]ERROR:[/bold red] {e.pgerror or str(e)}")
        if e.pgcode:
            console.print(f"[dim]SQLSTATE: {e.pgcode}[/dim]")
        return None
    except Exception as e:
        conn.rollback()
        console.print(f"[bold red]Unexpected error:[/bold red] {e}")
        return None

# ── Input dispatch ────────────────────────────────────────────────────────────

def dispatch(conn, line: str, timing_on: bool, last_result):
    """
    Handle a complete (semicolon-terminated or special) command.
    Returns (timing_on, last_result).
    """
    stripped = line.strip()

    # ── Exit ──────────────────────────────────────────────────────────────
    if stripped.lower() in ("exit", "quit", r"\q"):
        console.print("[bold yellow]Bye![/bold yellow]")
        sys.exit(0)

    # ── .clear ────────────────────────────────────────────────────────────
    if stripped == ".clear":
        os.system("cls" if os.name == "nt" else "clear")
        return timing_on, last_result

    # ── .help ─────────────────────────────────────────────────────────────
    if stripped in (".help", "\\?", "help"):
        cmd_help()
        return timing_on, last_result

    # ── .tables ───────────────────────────────────────────────────────────
    if stripped == ".tables":
        cmd_tables(conn)
        return timing_on, last_result

    # ── .schema ───────────────────────────────────────────────────────────
    if stripped == ".schema":
        cmd_schema_summary(conn)
        return timing_on, last_result

    # ── .enums ────────────────────────────────────────────────────────────
    if stripped == ".enums":
        cmd_enums(conn)
        return timing_on, last_result

    # ── \df ───────────────────────────────────────────────────────────────
    if stripped == r"\df":
        cmd_functions(conn)
        return timing_on, last_result

    # ── \dv ───────────────────────────────────────────────────────────────
    if stripped == r"\dv":
        cmd_views(conn)
        return timing_on, last_result

    # ── \d <table> ────────────────────────────────────────────────────────
    if stripped.startswith(r"\d ") and not stripped.startswith(r"\di"):
        table_name = stripped[3:].strip()
        cmd_describe(conn, table_name)
        return timing_on, last_result

    # ── \di <table> ───────────────────────────────────────────────────────
    if stripped.startswith(r"\di "):
        table_name = stripped[4:].strip()
        cmd_indexes(conn, table_name)
        return timing_on, last_result

    # ── .search <keyword> ─────────────────────────────────────────────────
    if stripped.startswith(".search "):
        keyword = stripped[8:].strip()
        if keyword:
            cmd_search(conn, keyword)
        else:
            console.print("[yellow]Usage: .search <keyword>[/yellow]")
        return timing_on, last_result

    # ── .ask <query> ──────────────────────────────────────────────────────
    if stripped.startswith(".ask "):
        query = stripped[5:].strip()
        if query:
            generated_sql = cmd_ask(conn, query)
            if generated_sql:
                result = run_query(conn, generated_sql, timing_on)
                if result is not None:
                    last_result = result
        else:
            console.print("[yellow]Usage: .ask <natural language query>[/yellow]")
        return timing_on, last_result

    # ── .export <file> ────────────────────────────────────────────────────
    if stripped.startswith(".export "):
        filename = stripped[8:].strip()
        if filename:
            cmd_export(last_result, filename)
        else:
            console.print("[yellow]Usage: .export <filename.csv>[/yellow]")
        return timing_on, last_result

    # ── .timing on/off ────────────────────────────────────────────────────
    if stripped.lower() in (".timing on", ".timing off"):
        timing_on = stripped.lower().endswith("on")
        state = "[green]ON[/green]" if timing_on else "[red]OFF[/red]"
        console.print(f"Timing: {state}")
        return timing_on, last_result

    # ── SQL query ─────────────────────────────────────────────────────────
    result = run_query(conn, stripped, timing_on)
    if result is not None:
        last_result = result

    return timing_on, last_result

# ── Banner ────────────────────────────────────────────────────────────────────

def print_banner(host, port, dbname, user):
    console.print(Panel(
        f"[bold white]SCMS[/bold white] [dim]Supply Chain Management System[/dim]\n"
        f"[dim]Connected to [bold]{dbname}[/bold] as [bold]{user}[/bold]"
        f" @ {host}:{port}[/dim]\n"
        f"[dim]Schema: [bold cyan]{SCHEMA}[/bold cyan] · "
        f"Type [bold].help[/bold] for commands · "
        f"[bold]exit[/bold] to quit[/dim]",
        border_style="cyan",
        padding=(0, 2),
    ))

# ── Autocomplete word list ────────────────────────────────────────────────────

def build_completer():
    words = (
        SQL_KEYWORDS
        + [k.lower() for k in SQL_KEYWORDS]
        + SCMS_TABLES
        + [f"scms.{t}" for t in SCMS_TABLES]
        + SPECIAL_COMMANDS
    )
    return WordCompleter(words, ignore_case=True, sentence=True)

# ── Main REPL ─────────────────────────────────────────────────────────────────

def repl(conn, host, port, dbname, user):
    print_banner(host, port, dbname, user)

    # ── Non-TTY / pipe mode (used by subprocess tests and CI) ────────────────
    # When stdin is not a real terminal (e.g. piped in tests), prompt_toolkit's
    # Win32Output crashes because there is no console screen buffer attached.
    # We detect this and fall back to a simple line-reading loop.
    if not sys.stdin.isatty():
        timing_on   = False
        last_result = None
        buffer      = []
        try:
            for line in sys.stdin:
                line = line.rstrip("\n\r")
                if not line.strip():
                    continue
                stripped = line.strip()
                is_special = (
                    stripped.startswith(".")
                    or stripped.startswith("\\")
                    or stripped.lower() in ("exit", "quit", "help")
                )
                if is_special:
                    timing_on, last_result = dispatch(
                        conn, stripped, timing_on, last_result)
                    continue
                buffer.append(line)
                combined = "\n".join(buffer).strip()
                if combined.rstrip().endswith(";"):
                    timing_on, last_result = dispatch(
                        conn, combined, timing_on, last_result)
                    buffer.clear()
        except (EOFError, KeyboardInterrupt):
            pass
        return

    # ── Interactive TTY mode ──────────────────────────────────────────────────
    session = PromptSession(
        history=FileHistory(HISTORY_FILE),
        auto_suggest=AutoSuggestFromHistory(),
        completer=build_completer(),
        complete_while_typing=True,
        style=PROMPT_STYLE,
        mouse_support=False,
    )

    timing_on   = False
    last_result = None
    buffer      = []          # accumulate multi-line queries

    def get_prompt():
        if buffer:
            return HTML(f"<bold>   ...  </bold>")
        return HTML(f'<prompt.schema>scms</prompt.schema>'
                    f'<prompt.arrow>=# </prompt.arrow>')

    while True:
        try:
            line = session.prompt(get_prompt)
        except KeyboardInterrupt:
            if buffer:
                buffer.clear()
                console.print("[dim]Query cancelled.[/dim]")
            continue
        except EOFError:
            console.print("[bold yellow]Bye![/bold yellow]")
            break

        if not line.strip():
            continue

        stripped = line.strip()

        # ── Special commands (no semicolon needed) ────────────────────────
        is_special = (
            stripped.startswith(".")
            or stripped.startswith("\\")
            or stripped.lower() in ("exit", "quit", "help")
        )

        if is_special:
            timing_on, last_result = dispatch(
                conn, stripped, timing_on, last_result)
            continue

        # ── SQL accumulation until ; ──────────────────────────────────────
        buffer.append(line)
        combined = "\n".join(buffer).strip()

        if combined.rstrip().endswith(";"):
            timing_on, last_result = dispatch(
                conn, combined, timing_on, last_result)
            buffer.clear()
        # else keep accumulating

# ── CLI args ──────────────────────────────────────────────────────────────────

def parse_args():
    p = argparse.ArgumentParser(
        description="SCMS PostgreSQL CLI — pgAdmin-style terminal client")
    p.add_argument("--host",     default=None, help="DB host (default: localhost)")
    p.add_argument("--port",     default=None, help="DB port (default: 5432)")
    p.add_argument("--dbname",   default=None, help="Database name")
    p.add_argument("--user",     default=None, help="DB user")
    p.add_argument("--password", default=None, help="DB password (not recommended; use env)")
    return p.parse_args()


def main():
    args = parse_args()
    conn, host, port, dbname, user = get_connection(args)
    try:
        repl(conn, host, port, dbname, user)
    finally:
        conn.close()


if __name__ == "__main__":
    main()

    