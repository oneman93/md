* See [](../Canvas_TeamsData_Sync_sql/[dbo].[Populate_Test_Section_Enrollments].sql)
* Convert it into a view
* Save in the samve folder with a name, `dbo.vPopulate_Test_Section_Enrollments.sql`

# Speed issue

* See below queries. What is wrong with the table `Banner_Grade_Push_log`? With `nolock`, most of cases returned `counter(*)` value within seconds.

```
Select count(*) From [BLACKBOARD].[dbo].Banner_Grade_Push_log with (nolock)
--takes more than 2min and still running

Select top 100 * From [BLACKBOARD].[dbo].Banner_Grade_Push_log with (nolock)
order by Process_date desc
-- takes more than 2min and still running

Select top 100 * From [BLACKBOARD].[dbo].Banner_Grade_Push_log with (nolock)
-- takes 1 sec
```

* You suggested
```
 -- Option A: Add a clustered index on Process_date (best for date-range queries)
  CREATE CLUSTERED INDEX CIX_Banner_Grade_Push_log_ProcessDate
  ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_date DESC);

```

* What is difference between clustered index and non-clustered index and which one should I use?

## Clustered vs Non-Clustered Index

| | Clustered | Non-Clustered |
|---|---|---|
| Physical storage | Table rows **are** sorted and stored in index order on disk | Separate structure storing key + pointer back to the row |
| Count per table | **One only** (rows can only have one physical order) | Many allowed |
| No index = | **Heap** (random page order) | N/A |
| Best for | Columns used in ORDER BY, range scans, or full SELECT * | Filtering/lookups where only a few columns are needed |

**Which to use for `Banner_Grade_Push_log`?**

Use a **Clustered Index** on `Process_date` because:
- `SELECT TOP 100 * ORDER BY Process_date DESC` → reads from the end of the sorted index, grabs 100 rows, done — no extra page hops
- `SELECT COUNT(*)` → scans compact, sorted pages instead of a fragmented heap
- `SELECT *` queries benefit most from clustered because non-clustered would need a key lookup per row to fetch all columns (expensive at scale)

Only use non-clustered if the table already has a clustered index on another column (e.g., a primary key ID). Check first:
```sql
SELECT i.name, i.type_desc
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('[BLACKBOARD].[dbo].Banner_Grade_Push_log')
ORDER BY i.type;
-- If no CLUSTERED row → table is a heap → safe to create clustered index
```

---

* Creating index takes forever as in [](./imgs/errors/creating-index-takes-forever.png). Is this ok?

## Creating Clustered Index Taking Long Time — Is This OK?

**Yes, this is normal. Do NOT cancel it.**

The screenshot shows it running for ~4 min 52 sec. Here is why it takes long and what to expect:

**Why it is slow:**
- Creating a clustered index physically **reorders every single row** in the table to match the new sort order (`Process_date DESC`)
- For a large log table with millions of rows, SQL Server must read all pages, sort all data, and rewrite the entire table — this is an O(n) rebuild
- The bigger the table, the longer it takes (can be 5–30+ minutes for large tables)

**Is the 99+ warnings/errors badge a problem?**
- No — those are from previous query results in the session, not from the `CREATE INDEX` command itself

**What to do:**
- Leave it running until it completes
- Cancelling it mid-way triggers a **rollback** which can take equally long and leaves the table in its original heap state
- Once complete, re-run the slow queries — they should return in seconds

* q. While creating index, does other process still can write to the table, `Banner_Grade_Push_log`? Or is it blocked?

## Writes During Index Creation — Blocked or Not?

**By default (what you ran): YES, writes are blocked.**

`CREATE CLUSTERED INDEX` without any option takes a **Schema Modification lock (Sch-M)** on the table for the entire duration. This means:
- All reads and writes from other sessions are **queued/blocked** until the index build finishes
- For a production log table that is constantly being written to, this is a concern

**The fix: `WITH (ONLINE = ON)`**

```sql
CREATE CLUSTERED INDEX CIX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_date DESC)
WITH (ONLINE = ON);
```

With `ONLINE = ON`:
- Other sessions can **continue reading and writing** during the build
- SQL Server builds the index in the background and tracks concurrent changes
- Only takes a very brief lock at the very start and at the very end (seconds, not minutes)
- Takes slightly longer to complete overall, but does not block production traffic

**Caveat:** `ONLINE = ON` requires **SQL Server Enterprise or Developer edition**. Your server is `15.0 RTM` (SQL Server 2019) — check your edition:
```sql
SELECT SERVERPROPERTY('Edition');
-- If result contains 'Enterprise' or 'Developer' → ONLINE = ON is available
-- If 'Standard' → not available, you must accept the blocking or schedule during off-hours
```

**Practical advice for `Banner_Grade_Push_log`:**
- If Enterprise edition → re-run with `WITH (ONLINE = ON)` (cancel current one first if still running)
- If Standard edition → let the current one finish (it is already running), and accept the brief downtime; schedule future index maintenance during off-peak hours

* I've cancelled after 13mins [](./imgs/errors/cancelling.png)

## After Cancelling — What Happened?

The screenshot shows "Cancelling query..." at 00:13:29. This is expected:
- SQL Server is now **rolling back** the partial index build — this also takes time (proportional to how far it got)
- Once rollback completes, the table returns to its original heap state — no damage done
- You can safely re-run the index creation after it finishes

---

* Q. the table structure is here:
  * [](./imgs/banner-grade-push-log.png)
  * [](./sql/dbo.Banner_Grade_Push_log.sql)
* Do I need to create index for `StudentID` and `Status` as well?

## Table Structure Analysis & Index Recommendations

**Table DDL summary:**
```
RecID               bigint IDENTITY(1,1) NOT NULL   ← no PK, no clustered index!
StudentID           varchar(50) NULL
ClassID             varchar(50) NULL
Process_Status      varchar(50) NULL
Process_date        datetime2(7) NULL
Banner_response_Message  varchar(max) NULL           ← LOB data, stored off-page
```

**Two root causes of slowness confirmed:**
1. **No clustered index** — table is a heap, rows in random order, full scan required for everything
2. **`varchar(max)` column** — LOB pages stored separately; full `SELECT *` must chase LOB pointers across pages

---

**Revised recommendation — do NOT put the clustered index on `Process_date`.**

Put it on `RecID` instead:

```sql
-- Step 1: Make RecID the clustered primary key (FAST — data is already in IDENTITY order)
ALTER TABLE [BLACKBOARD].[dbo].Banner_Grade_Push_log
ADD CONSTRAINT PK_Banner_Grade_Push_log PRIMARY KEY CLUSTERED (RecID ASC);

-- Step 2: Non-clustered index for ORDER BY Process_date queries
CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_date DESC);

-- Step 3 (optional): Composite index for filtered queries like:
--   WHERE Process_Status = 'ERROR' AND Process_date > '2025-11-25'
CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_Status_Date
ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_Status, Process_date DESC);
```

**Why `RecID` for clustered, not `Process_date`?**

| | Clustered on RecID (IDENTITY) | Clustered on Process_date |
|---|---|---|
| Insert speed | Rows always appended to end — zero page splits | Process_date may have duplicates → page splits → fragmentation |
| Index build time | Very fast — data already in IDENTITY order physically | Slow — must sort and rewrite entire table (what you just cancelled) |
| TOP 100 ORDER BY date | NC index seek → 100 key lookups → done in milliseconds | Direct read from end of table |
| COUNT(*) | Fast scan of clustered index pages | Same |

**Do you need indexes on `StudentID` and `Process_Status`?**

- **`StudentID`** — only useful if you query `WHERE StudentID = 'A0001234'` frequently. Not needed for the slow queries shown. Skip for now.
- **`Process_Status`** — low cardinality (only a handful of values like `'ERROR'`, `'Delete'`). A standalone index on it is not useful. Use the **composite index (Step 3)** above with `(Process_Status, Process_date DESC)` instead — that handles `WHERE Process_Status = 'ERROR' AND Process_date > '...'` efficiently.

**Run order:**
1. Step 1 first (clustered PK on RecID) — this will be **very fast** since IDENTITY data is already sequential
2. Then Step 2 and Step 3 — these build non-clustered indexes, no full table rewrite needed

* Q. After creating indexes, do i need to archive table to reduce table size?

## Do You Need to Archive After Creating Indexes?

**Short answer: Indexes fix query speed now. Archiving prevents the problem from coming back.**

They solve different problems:

| | Indexes | Archiving / Purging |
|---|---|---|
| What it fixes | Slow queries on a large table | Table growing too large over time |
| Effect on disk | Uses **more** space (index structures) | Reduces space |
| Effect on future inserts | No change to row count | Keeps table small permanently |
| One-time or ongoing | One-time setup | Ongoing maintenance |

**For `Banner_Grade_Push_log` specifically — yes, archiving is recommended.**

Evidence from what we know:
- The index build ran for **13+ minutes before being cancelled** → this table has many millions of rows
- `Banner_response_Message` is `varchar(max)` → each row can be several KB; millions of rows = significant disk usage
- It is a **log table** → old records are almost certainly never queried in normal operations
- Without archiving, the table will keep growing and indexes will gradually slow down again as they cover more rows

**Recommended approach — scheduled purge job:**

```sql
-- Delete log records older than 6 months (adjust retention as needed)
-- Run this via SQL Agent Job on a schedule (e.g. nightly or weekly)
DELETE TOP (10000)  -- delete in batches to avoid log explosion
FROM [BLACKBOARD].[dbo].Banner_Grade_Push_log
WHERE Process_date < DATEADD(MONTH, -6, GETDATE());
```

> Delete in small batches (`TOP 10000`) and loop rather than one giant DELETE — a single delete of millions of rows locks heavily and bloats the transaction log.

**If you need to keep old data (audit/compliance):**

```sql
-- Archive to a separate table first, then delete from main
SELECT *
INTO [BLACKBOARD].[dbo].Banner_Grade_Push_log_Archive
FROM [BLACKBOARD].[dbo].Banner_Grade_Push_log
WHERE Process_date < DATEADD(MONTH, -6, GETDATE());

-- Then delete from main table (in batches as above)
```

**Recommended retention for a grade push log:** 6–12 months in the live table is usually sufficient. Anything older can be archived or dropped unless there is a compliance requirement to keep it.

**Run order summary (complete plan):**
1. Add clustered PK on `RecID` → fixes speed immediately
2. Add NC indexes on `Process_date` and `(Process_Status, Process_date)` → optimises filtered queries
3. Purge old records in batches → reduces table size
4. Set up a SQL Agent job to purge automatically going forward → keeps the table healthy long-term

* q. In step 1, 2,3 given above, should i add `WITH (ONLINE = ON);` as well?

## Should You Add `WITH (ONLINE = ON)` to Steps 1, 2, 3?

**Yes — if your edition supports it (Enterprise/Developer). Add it to all three.**

Here is the updated complete script:

```sql
-- Step 1: Clustered PK on RecID  (WITH ONLINE = ON supported for ALTER TABLE ADD CONSTRAINT)
ALTER TABLE [BLACKBOARD].[dbo].Banner_Grade_Push_log
ADD CONSTRAINT PK_Banner_Grade_Push_log PRIMARY KEY CLUSTERED (RecID ASC)
WITH (ONLINE = ON);

-- Step 2: NC index on Process_date
CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_date DESC)
WITH (ONLINE = ON);

-- Step 3: Composite NC index on Process_Status + Process_date
CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_Status_Date
ON [BLACKBOARD].[dbo].Banner_Grade_Push_log (Process_Status, Process_date DESC)
WITH (ONLINE = ON);
```

**Per step breakdown:**

| Step | ONLINE = ON effect | Without ONLINE = ON |
|---|---|---|
| Step 1 (clustered PK on RecID) | Writes allowed during build | Table fully locked during build |
| Step 2 (NC on Process_date) | Writes allowed during build | Table fully locked during build |
| Step 3 (NC composite) | Writes allowed during build | Table fully locked during build |

**Good news about Step 1 specifically:**
Even without `ONLINE = ON`, Step 1 will be **much faster** than the previous attempt on `Process_date` — because `RecID` is an IDENTITY column and rows are already physically stored in ascending RecID order. SQL Server does not need to sort anything; it just builds the index on top of data that is already in the right sequence. Expect seconds to a few minutes, not 13+ minutes.

Steps 2 and 3 (non-clustered) are also generally faster than clustered — they build a separate structure without rewriting table data.

**If edition is Standard (ONLINE = ON not available):**
- Run Steps 1–3 without `WITH (ONLINE = ON)`
- Schedule during off-peak hours (e.g. overnight or weekend)
- Step 1 will still be fast due to IDENTITY ordering; Steps 2–3 are non-clustered so also relatively quick

* q. Step1 takes 40min now. Is this normal? [](./imgs/errors/step1-40min.png)

## Step 1 Taking 40 Minutes — Is This Normal?

**Yes — with `WITH (ONLINE = ON)`, 40+ minutes is expected for this table. Do NOT cancel it.**

Earlier the estimate was "seconds to a few minutes" — that was for the **offline** version. Adding `WITH (ONLINE = ON)` changes the picture significantly.

**Why `ONLINE = ON` takes much longer than offline:**

| Factor | What happens |
|---|---|
| Multiple build passes | SQL Server builds the index, then does a second pass to merge concurrent changes that arrived during the build |
| Row versioning overhead | Every row inserted/updated/deleted during the build is tracked in tempdb's version store |
| `varchar(max)` LOB data | `Banner_response_Message` forces SQL Server to handle LOB pages separately during the online build — significantly more I/O |
| Active log table | If rows are constantly being inserted (this is a log table), SQL Server must continuously reconcile new rows into the index being built |

**Why it is still slower than the cancelled Process_date attempt:**
- That attempt ran offline — no versioning overhead
- It was cancelled at 13 min, so you never saw how long it would have taken to finish
- Step 1 with ONLINE=ON is doing more work: build + version tracking + LOB handling + concurrent merge

**Verify it is still actively progressing (run in a new query window):**
```sql
SELECT
    r.session_id,
    r.command,
    r.percent_complete,
    r.estimated_completion_time / 1000 / 60 AS est_minutes_remaining,
    r.total_elapsed_time / 1000 / 60 AS elapsed_minutes,
    r.wait_type,
    r.wait_resource
FROM sys.dm_exec_requests r
WHERE r.command LIKE '%ALTER%'
   OR r.command LIKE '%INDEX%';
```

If `percent_complete` is increasing and `wait_type` is I/O-related (e.g. `PAGEIOLATCH_EX`, `WRITELOG`) — it is working normally, just I/O-bound.

**What to do:**
- Leave it running — cancelling at this point triggers a long rollback (proportional to 40 min of work)
- Once it finishes, Steps 2 and 3 (non-clustered indexes) will be much faster — they do not rewrite table data

**If you need a rough completion estimate:**
```sql
-- Run while the ALTER TABLE is in progress
SELECT
    percent_complete,
    estimated_completion_time / 1000 AS est_seconds_remaining
FROM sys.dm_exec_requests
WHERE command LIKE '%ALTER%' OR command LIKE '%INDEX%';
```


* q. progress query shows nothing while another the index creation process is still running.
* [](./imgs/errors/progress-nothing.png)

## Progress Query Shows Nothing — But Index Build Is Still Running

**This is expected. `sys.dm_exec_requests` only shows the user session, not the background workers doing the actual online index build work.**

With `ONLINE = ON`, SQL Server offloads the heavy work to **background worker threads**. The user session itself goes into a wait state (or briefly disappears between phases), while the real work happens in background tasks not visible in `sys.dm_exec_requests`.

**Two additional reasons the query returns nothing:**
1. `percent_complete` is only populated for a limited set of operations. `ALTER TABLE ... ADD CONSTRAINT PRIMARY KEY CLUSTERED WITH (ONLINE=ON)` may report `percent_complete = 0` throughout — the row exists but looks "stuck"
2. The `command` column may not match `'%ALTER%'` or `'%INDEX%'` exactly depending on SQL Server's internal representation

**Step 1 — Get your session ID first** (run in the query window running the ALTER TABLE, in a second tab):
```sql
-- In the ALTER TABLE session window, before or during the operation:
SELECT @@SPID AS my_session_id;
```

**Step 2 — Monitor that specific session:**
```sql
-- Replace 99 with your actual SPID from above
SELECT
    session_id,
    status,           -- 'running', 'suspended', 'sleeping'
    command,
    wait_type,
    wait_time / 1000  AS wait_seconds,
    total_elapsed_time / 1000 / 60 AS elapsed_minutes,
    percent_complete
FROM sys.dm_exec_requests
WHERE session_id = 99;  -- your SPID here
```

If this returns a row with `status = 'suspended'` and a `wait_type` like `WAIT_XTP_OFFLINE_CKPT_NEW_LOG`, `LCK_M_X`, `PAGEIOLATCH_*`, or `WRITELOG` — it is alive and working.

**Step 3 — Look for background worker threads doing the actual build:**
```sql
SELECT
    session_id,
    status,
    command,
    wait_type,
    total_elapsed_time / 1000 / 60 AS elapsed_minutes,
    percent_complete
FROM sys.dm_exec_requests
WHERE session_id > 50
  AND command NOT IN ('SLEEP', 'TASK MANAGER', 'RESOURCE MONITOR', 'GHOST CLEANUP')
ORDER BY total_elapsed_time DESC;
```

Look for rows with `command` containing `INDEX`, `SORT`, `BUILD`, or `PARALLEL` — those are the online index worker threads.

* q11. I could not find any useful records from above query. Can I find my session id using eg, `sa_who` etc?

## Finding Your Session ID — sp_who, sp_who2, and Alternatives

**Yes — use `sp_who2` or `@@SPID`. The procedure name is `sp_who2`, not `sa_who`.**

**Option 1 — Simplest: `@@SPID` (run in the same window as the ALTER TABLE)**
```sql
SELECT @@SPID AS my_session_id;
```
This returns your own session ID instantly. Run it in the query window that is executing the index build — it gives the exact SPID to use in monitoring queries.

**Option 2 — `sp_who2` (shows all active sessions with login name, status, CPU, etc.)**
```sql
EXEC sp_who2;
-- Look for rows where:
-- Status    = SUSPENDED or RUNNABLE
-- Command   = ALTER TABLE or CREATE INDEX
-- DBName    = BLACKBOARD
-- BlkBy     = blank (not blocked)
```

`sp_who2` is an undocumented but universally available system procedure. It shows more columns than `sp_who` — including CPU time and I/O — which makes it easier to spot the long-running session.

**Option 3 — `sp_who` (official, less detail)**
```sql
EXEC sp_who;
-- Same idea, fewer columns than sp_who2
```

**Option 4 — filter `sys.dm_exec_sessions` by login name (most reliable when DMV query returns nothing)**
```sql
SELECT
    s.session_id,
    s.status,
    s.login_name,
    s.host_name,
    s.program_name,
    r.command,
    r.wait_type,
    r.total_elapsed_time / 1000 / 60 AS elapsed_minutes
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON r.session_id = s.session_id
WHERE s.login_name = SYSTEM_USER   -- your login
  AND s.session_id <> @@SPID       -- exclude the monitoring query itself
ORDER BY s.session_id;
```

This shows all sessions under your login across all query windows, even if `sys.dm_exec_requests` shows no active command (the session exists but is in a wait state between phases).

**Quick reference:**

| Tool | Use case |
|---|---|
| `SELECT @@SPID` | Get your own session ID in the current window |
| `EXEC sp_who2` | See all active sessions, spot yours by login/status/command |
| `EXEC sp_who` | Same but fewer columns |
| `sys.dm_exec_sessions` | Filter by login name, reliable even for sleeping/waiting sessions |

* q. I don't understand when you said, ` Run it in the query window that is executing the index build...`
* The query is running in [](./imgs/actual-process.png). How is it possible to run another query in the same tab of `alternative...Executing...`?
* Also running `sp_who2` only returned unrelated process not the indexcreating process as in [](./imgs/sp-who2.png)

## Running a Second Query While ALTER TABLE Is Executing — And Why sp_who2 Misses It

**You cannot run another query in the same tab while it is executing. Open a new query tab.**

In SSMS, each query tab is tied to one session. When that session is busy running `ALTER TABLE`, you cannot type and execute another query in the same tab — the Execute button is greyed out. The instruction "run it in the same window" meant: before you started the ALTER TABLE, run `SELECT @@SPID` first to note your session ID. Now that it is running, you need a separate tab.

**How to open a second query tab connected to the same server:**
1. In SSMS: `File → New Query` (or Ctrl+N) — this opens a new tab connected to the same registered server
2. Or right-click the server in Object Explorer → `New Query`
3. Both methods give you a fresh session where you can run monitoring queries while the ALTER TABLE runs in the original tab

---

**Why `sp_who2` did not show the index build:**

With `WITH (ONLINE = ON)`, SQL Server runs the index build on **internal background worker threads** — these are system-level tasks that do not appear as user sessions in `sp_who2`. Your session (the one that issued `ALTER TABLE`) transitions into a wait state (`status = SUSPENDED`) while the background workers do the heavy lifting. `sp_who2` shows user sessions; it hides the background worker activity.

What you likely saw in the screenshot: your session shows `status = SLEEPING` or `SUSPENDED` with `command = AWAITING COMMAND` — this looks like it is doing nothing, but it is actually waiting for the background build to finish.

**How to find it:**

```sql
-- In a NEW query tab (not the one running ALTER TABLE):

-- 1. Find all non-sleeping sessions including yours:
SELECT session_id, status, command, wait_type,
       total_elapsed_time / 1000 / 60 AS elapsed_min,
       login_name
FROM sys.dm_exec_requests
WHERE status <> 'sleeping'
ORDER BY total_elapsed_time DESC;

-- 2. If that returns nothing, look for your session in dm_exec_sessions
--    (it exists even when suspended between phases):
SELECT s.session_id, s.status, s.login_name,
       r.command, r.wait_type,
       r.total_elapsed_time / 1000 / 60 AS elapsed_min
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON r.session_id = s.session_id
WHERE s.is_user_process = 1
  AND s.login_name = SYSTEM_USER
ORDER BY s.session_id;
```

Look for a row where `elapsed_min` is large (matching how long the ALTER TABLE has been running) — that is your session. The `wait_type` column tells you what it is waiting on:
- `WAIT_XTP_OFFLINE_CKPT_NEW_LOG` — online index build in progress, normal
- `PAGEIOLATCH_EX` / `WRITELOG` — I/O bound, working normally
- `LCK_M_X` — waiting on a lock (brief, happens at the start/end of ONLINE build)

**The simplest confirmation the operation is still alive:**

As long as the original query tab shows `Executing...` in the status bar at the bottom of SSMS — it is running. No monitoring query needed. The spinner + `Executing...` is the most reliable indicator.

**The real way to confirm it is still running:**
Check SQL Server Activity Monitor (right-click server in SSMS → Activity Monitor → Processes tab) — filter by your database. The session will show as "Running" or "Waiting" with high CPU or I/O, even if the DMV query shows nothing.

**Bottom line:** As long as the query window shows the spinner (executing), the operation is alive. The blank result from the progress query is a normal artifact of how online index builds work — not a sign something is wrong.

* q. I don't have Activity Monitor access. I see that `Executing...` is the real proof. But I need to turn off this laptop and need to check process later. What is a way to check the index creation process? All methods you provided so far could not find the index creation process of [](./imgs/index-creation-process.png)

# Turning Off Laptop While Index Build Is Running — What Happens and How to Check

**Critical warning: Do NOT turn off the laptop or close SSMS while the index build is running from an interactive SSMS window.**

When your laptop powers off or the SSMS window closes, the TCP connection to SQL Server is severed. SQL Server detects the broken connection and **rolls back the ALTER TABLE** — this rollback takes roughly as long as the forward operation did. At 40+ minutes in, a rollback could take another hour, during which the table is locked.

---

**If you must step away — the correct approach is a SQL Agent Job.**

A SQL Agent Job runs on the server itself. It survives laptop shutdown, network drops, and SSMS closing. The index build continues even after you close your machine.

**Step 1 — Create a SQL Agent Job for the index build:**

```sql
-- Run this BEFORE starting the index build
-- Creates a one-time SQL Agent job that runs server-side

USE msdb;
GO

EXEC sp_add_job
    @job_name = N'AdminJob_CreateIndex_BannerGradePushLog';

EXEC sp_add_jobstep
    @job_name   = N'AdminJob_CreateIndex_BannerGradePushLog',
    @step_name  = N'Create PK and NC indexes',
    @command    = N'
        ALTER TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
        ADD CONSTRAINT PK_Banner_Grade_Push_log PRIMARY KEY CLUSTERED (RecID ASC)
        WITH (ONLINE = ON);

        CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_ProcessDate
        ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] (Process_date ASC)
        WITH (ONLINE = ON);
    ',
    @database_name = N'BLACKBOARD';

EXEC sp_add_jobserver
    @job_name = N'AdminJob_CreateIndex_BannerGradePushLog';

-- Start it immediately:
EXEC sp_start_job N'AdminJob_CreateIndex_BannerGradePushLog';
```

The job runs in SQL Server Agent — it keeps going regardless of your SSMS session or laptop state.

---

**Step 2 — Check job status from any machine, any time:**

```sql
-- Check if the job is still running:
SELECT
    j.name                          AS job_name,
    ja.start_execution_date         AS started_at,
    DATEDIFF(MINUTE, ja.start_execution_date, GETDATE()) AS elapsed_minutes,
    CASE ja.last_executed_step_id
        WHEN NULL THEN 'Running step 1'
        ELSE CONCAT('Completed step ', ja.last_executed_step_id)
    END                             AS status
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobactivity ja ON ja.job_id = j.job_id
WHERE j.name = 'AdminJob_CreateIndex_BannerGradePushLog'
  AND ja.start_execution_date IS NOT NULL
  AND ja.stop_execution_date  IS NULL;  -- NULL = still running
```

```sql
-- Or check job history (shows completed/failed runs):
SELECT
    j.name,
    h.run_date,
    h.run_time,
    h.run_duration,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'Running'
    END AS result,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON h.job_id = j.job_id
WHERE j.name = 'AdminJob_CreateIndex_BannerGradePushLog'
ORDER BY h.run_date DESC, h.run_time DESC;
```

---

**What to do now if the laptop is already off and the session was killed:**

```sql
-- Check if the index exists (means it completed before the disconnect)
SELECT i.name, i.type_desc
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]')
ORDER BY i.type;

-- If PK_Banner_Grade_Push_log appears → it completed successfully
-- If only the heap entry or nothing → it was rolled back → must re-run
```

If it was rolled back: re-run via a SQL Agent Job (above) so it survives disconnections going forward.

**Summary:**

| Scenario | What happens |
|---|---|
| Close SSMS / turn off laptop | SQL Server kills the session → rollback begins |
| SQL Agent Job running | Continues on server — unaffected by laptop shutdown |
| Check status later | `msdb.dbo.sysjobactivity` (running) or `sysjobhistory` (completed/failed) |
| Verify index exists | `SELECT name FROM sys.indexes WHERE object_id = OBJECT_ID(...)` |

* q. Let's say I have 3 indexes already in the `Banner_Grade_Push_log_OLD` table:
  * RecID primary key
  * Process_date index
  * Status + Process_date composite index
* I want to improve search speed for `WHERE STUDENT_ID=???`. If I add another index for StudentID, will it be too much?

## Adding a 4th Index (StudentID) to `Banner_Grade_Push_log_OLD` — Is It Too Much?

**No — add it. 4 indexes on an archive table is not too much.**

### Why the OLD table is special

`Banner_Grade_Push_log_OLD` is a **write-frozen** archive table:
- No new INSERTs happening (data was migrated in bulk, then done)
- No UPDATEs or DELETEs in normal operation
- Queries are **read-only lookups** by ops/support teams

This completely changes the index cost calculus. The main downside of extra indexes — **write overhead** — is zero for a frozen archive table.

### Index overhead breakdown

| Operation | Live table cost | OLD table cost |
|---|---|---|
| INSERT per row | Maintain all indexes → slow | No inserts → zero |
| UPDATE | Update affected index pages | No updates → zero |
| DELETE | Remove from all indexes | No deletes → zero |
| SELECT `WHERE STUDENT_ID=?` | Full scan without index | **Fast seek with index** |
| Storage | Extra index pages on disk | Small fraction of 1.6B-row data |

### What the 4 indexes cover

| Index | Covers |
|---|---|
| RecID (PK, clustered) | `WHERE RecID BETWEEN ? AND ?`, range walks |
| Process_date (NC) | `WHERE Process_date = ?`, date-range queries |
| Status + Process_date (composite NC) | `WHERE Status = ? AND Process_date = ?` |
| **StudentID (new NC)** | **`WHERE STUDENT_ID = ?`** — no existing index covers this |

Without the StudentID index, a `WHERE STUDENT_ID = '12345'` query on 1.6 billion rows does a **full clustered index scan** — reads the entire table. With the index, it seeks directly to matching rows.

### How to add it

```sql
CREATE NONCLUSTERED INDEX IX_BannerGradePushLogOLD_StudentID
    ON Banner_Grade_Push_log_OLD (STUDENT_ID);
```

If you also commonly filter by StudentID + date together, consider a composite:

```sql
CREATE NONCLUSTERED INDEX IX_BannerGradePushLogOLD_StudentID_Date
    ON Banner_Grade_Push_log_OLD (STUDENT_ID, Process_date);
```

**Rule of thumb:** On a read-only archive table, add as many indexes as you have distinct query patterns. The only cost is disk space and the one-time build time.

* q12. Does composite index usually takes longer than single index? It is taking more than 1 hour 20 min: [](./imgs/index-creation-process.png). This is the longest index creation time. The other 2 indexes took 1 hour each. For 1.6 billion records, can you guess how long it will take?

## q12 — Composite Index Build Time vs Single-Column Index on 1.6B Rows

**Yes — composite indexes typically take longer than single-column indexes, and 1h20m+ is expected here. Estimate: 1.5–2.5 hours total.**

---

### Why the composite index takes longer

| Factor | Single-column `(Process_date ASC)` | Composite `(Status, Process_date DESC)` |
|---|---|---|
| Index key width | ~8 bytes (datetime2) | ~58 bytes (varchar(50) + datetime2) |
| Sort complexity | Sort 1.6B values of one column | Sort 1.6B rows by Status first, then Process_date within each Status group |
| Index leaf page size | Each page holds ~700+ key entries | Each page holds ~100–130 key entries (wider key = fewer entries per page) |
| Total leaf pages to write | Fewer | More — wider keys = more pages to allocate and write |

The wider key means each 8KB index page fits fewer entries, so SQL Server must allocate and write more pages total. More pages = more I/O = longer build time.

**Low-cardinality first column adds extra work:**
`Status` likely has only a handful of distinct values (e.g. `'ERROR'`, `'Delete'`, `'Complete'`, `'Running'`). SQL Server must sort all 1.6B rows by this column first, which produces large contiguous runs — this is sortable efficiently, but the subsequent sort within each Status group by `Process_date DESC` adds a second sort pass on each partition.

---

### Time estimate for 1.6B rows

The other two indexes each took ~1 hour. The composite is at 1h20m and still running. Based on the width difference and sort complexity:

| Index | Expected time (estimate) |
|---|---|
| PK on RecID (clustered, IDENTITY order) | Already done |
| NC on Process_date (single column, 8 bytes) | ~1 hour ✓ |
| NC on Status + Process_date (composite, ~58 bytes, 2-column sort) | **~1.5–2.5 hours** |

At 1h20m, it is likely **50–70% complete**. Do not cancel — a rollback at this point would cost another hour of wasted time, and you would have to restart.

**Verify it is still progressing (run in a new tab):**
```sql
SELECT
    session_id,
    status,
    command,
    wait_type,
    total_elapsed_time / 1000 / 60 AS elapsed_min,
    percent_complete
FROM sys.dm_exec_requests
WHERE status <> 'sleeping'
ORDER BY total_elapsed_time DESC;
```

If a row appears with large `elapsed_min` and an I/O wait type (`PAGEIOLATCH_EX`, `WRITELOG`, `IO_COMPLETION`) — it is working. Leave it running.

* q. varchar(max) vs varchar(8000), which one is more efficent to select query?

## `varchar(max)` vs `varchar(8000)` — Which Is More Efficient for SELECT?

**`varchar(8000)` is more efficient — but only when the actual data exceeds 8,000 bytes.**

The critical threshold is **8,000 bytes** (SQL Server's data page inline limit):

| | `varchar(max)` | `varchar(8000)` |
|---|---|---|
| Value ≤ 8,000 bytes | Stored **inline** on data page — same as varchar(8000) | Stored **inline** on data page |
| Value > 8,000 bytes | Stored **off-row** in separate LOB pages — extra I/O per row | Cannot store > 8,000 bytes (error) |
| Index key column | **Not allowed** | Allowed (up to 900 bytes key) |
| INCLUDE in NC index | Allowed | Allowed |
| Max allowed size | 2 GB | 8,000 bytes |

**The performance hit only occurs when values exceed 8,000 bytes:**
- SQL Server must follow a **LOB pointer** from the data page to a separate LOB allocation unit
- For `SELECT *` on a table with millions of rows, this means millions of extra page reads — one LOB page chain per row
- This is one of the two root causes of `Banner_Grade_Push_log` slowness

**If values are ≤ 8,000 bytes: no difference.** `varchar(max)` stores them inline just like `varchar(8000)`.

**Practical rule for `Banner_response_Message`:**
```sql
-- Check actual max length in the table to decide whether to change the column type:
SELECT
    MAX(LEN(Banner_response_Message))  AS max_length,
    AVG(LEN(Banner_response_Message))  AS avg_length,
    COUNT(CASE WHEN LEN(Banner_response_Message) > 8000 THEN 1 END) AS rows_over_8000
FROM [BLACKBOARD].[dbo].Banner_Grade_Push_log;
```

- If `max_length` ≤ 8,000 → change to `varchar(8000)` (or smaller) — eliminates LOB overhead entirely
- If `rows_over_8000` > 0 → some rows genuinely need `varchar(max)`; consider truncating at insert time if those long values are not needed (e.g. `LEFT(message, 4000)`)
- If `avg_length` is small (e.g. < 500) → change to `varchar(500)` or similar — SQL Server validates length at insert, no storage benefit over `varchar(8000)` but enforces data integrity

**Note:** `varchar(n)` is variable-length — declaring `varchar(8000)` vs `varchar(500)` does **not** change storage for existing values. It only sets the maximum allowed size. The actual bytes stored are the same either way.

* q. why my activity monitor shows nothing?
* [](./imgs/errors/activity-monitor-empty.png)

## Activity Monitor Shows Nothing — Why?

**Most likely cause: Activity Monitor is connected to a different server instance than where the index build is running, or it has not been refreshed.**

Check these in order:

**1. Wrong server connection (most common)**
- Activity Monitor opened from a different SSMS connection tab connects to that tab's server
- Verify the title bar of Activity Monitor shows the correct server name (e.g. `BLACKBOARD`)
- If wrong: close it, right-click the correct server in Object Explorer → Activity Monitor

**2. Activity Monitor not refreshed**
- It does NOT auto-refresh by default — click the green **Refresh** button (or press F5 inside it)
- Or right-click inside the Processes grid → Refresh
- You can also set auto-refresh: right-click → Refresh Interval → e.g. 10 seconds

**3. Filter hiding suspended sessions**
- The Processes section may be filtered to show only "Active" or "Running" sessions
- The ALTER TABLE session is likely in `status = 'suspended'` (waiting on I/O or locks) — this can look invisible in filtered views
- Right-click any column header in the Processes grid → Filter → clear any filters

**4. Permissions issue**
- Activity Monitor requires `VIEW SERVER STATE` permission
- If you see the Processes section but it is empty (no rows at all, not even your own session), you may lack this permission
- Check: `SELECT HAS_PERMS_BY_NAME(null, null, 'VIEW SERVER STATE');` — should return `1`

**Reliable alternative — use T-SQL directly:**

Activity Monitor is a GUI wrapper. Use this instead (no refresh issues, no connection confusion):

```sql
-- Run in any query window on the correct server
-- First get your SPID from the ALTER TABLE window:
--   SELECT @@SPID   (run in the window running ALTER TABLE)

-- Then monitor it:
SELECT
    session_id,
    status,
    command,
    wait_type,
    total_elapsed_time / 1000 / 60 AS elapsed_minutes,
    cpu_time / 1000               AS cpu_seconds,
    reads,
    writes
FROM sys.dm_exec_requests
WHERE session_id = <your_spid>;   -- replace with actual SPID

-- Or show ALL non-sleeping sessions:
SELECT session_id, status, command, wait_type,
       total_elapsed_time/1000/60 AS elapsed_min
FROM sys.dm_exec_requests
WHERE status <> 'sleeping'
ORDER BY total_elapsed_time DESC;
```

This is more reliable than Activity Monitor for monitoring long-running operations.


* Yes, I did not have permission:
  * [](./imgs/i-dont-have.png)
* And creating index finished after 1 hour:
  * [](./imgs/took-1hour.png)

* q. I want to create archive table as [](./sql/dbo.Banner_Grade_Push_log_Archive.sql). I got error:
```
Msg 1709, Level 16, State 1, Line 10
Cannot use TEXTIMAGE_ON when a table has no text, ntext, image, varchar(max), nvarchar(max), non-FILESTREAM varbinary(max), xml or large CLR type columns.
```
What is wrong?

## Msg 1709 — TEXTIMAGE_ON Error When Creating Archive Table

**The archive table DDL has `TEXTIMAGE_ON [PRIMARY]` but the `Banner_response_Message` column is either missing or was changed to a non-LOB type.**

`TEXTIMAGE_ON` tells SQL Server which filegroup to store LOB data (varchar(max), text, xml, etc.) in. It is only valid when the table actually has at least one LOB column. If no LOB column exists, the clause is illegal — hence the error.

**How this happens:** SSMS generates `TEXTIMAGE_ON [PRIMARY]` automatically when scripting a table that has `varchar(max)`. If you modified the column type or removed the column before running the script, the clause becomes invalid.

**The fix — two options:**

**Option A: Keep `varchar(max)` in the archive table (recommended — preserves all data)**

The archive table should mirror the source. Keep `Banner_response_Message` as `varchar(max)` and the `TEXTIMAGE_ON` clause stays valid:

```sql
CREATE TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive] (
    [RecID]                    bigint        NOT NULL,
    [StudentID]                varchar(50)   NULL,
    [ClassID]                  varchar(50)   NULL,
    [Process_Status]           varchar(50)   NULL,
    [Process_date]             datetime2(7)  NULL,
    [Banner_response_Message]  varchar(max)  NULL,   -- keep as varchar(max)
    [Archived_date]            datetime2(7)  NOT NULL DEFAULT GETDATE()
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];               -- valid because varchar(max) exists
```

**Option B: Change the column to a fixed-length type and remove `TEXTIMAGE_ON`**

If you want to reduce archive table size by truncating long messages:

```sql
CREATE TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive] (
    [RecID]                    bigint        NOT NULL,
    [StudentID]                varchar(50)   NULL,
    [ClassID]                  varchar(50)   NULL,
    [Process_Status]           varchar(50)   NULL,
    [Process_date]             datetime2(7)  NULL,
    [Banner_response_Message]  varchar(1000) NULL,   -- truncated, no LOB storage
    [DateArchived]            datetime2(7)  NOT NULL DEFAULT GETDATE()
) ON [PRIMARY];                                      -- TEXTIMAGE_ON removed
```

**Which to use?**
- Option A: Use when you need the full message for audit/debugging purposes
- Option B: Use when the message is only for reference and truncation at 4000 chars is acceptable; also saves ~50% disk space on the archive table

After creating the archive table, populate it:
```sql
-- Insert records older than 6 months into archive
INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive]
       (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
SELECT  RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message
FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
WHERE  Process_date < DATEADD(MONTH, -6, GETDATE());

-- Then delete those rows from the main table in batches
WHILE 1 = 1
BEGIN
    DELETE TOP (10000)
    FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
    WHERE Process_date < DATEADD(MONTH, -6, GETDATE());

    IF @@ROWCOUNT = 0 BREAK;
    WAITFOR DELAY '00:00:01';  -- 1 second pause between batches
END
```

* I took optionB and created table: [Banner_Grade_Push_log_Archive]. If i want to insert more than 6months old data into archive table, i am afraid it will take forever because the source table is huge:
```
Select MIN(RECID), MAX(RECID) From [BLACKBOARD].[dbo].Banner_Grade_Push_log with (nolock)
-- 1-1656776247
--1,656,776,247 == 1 billion rows
```

## Archiving 1.6 Billion Rows — Strategy for a Huge Table

**Do NOT use `TOP (10000)` looping for a table this large. Use RecID range-based batching instead.**

With `TOP`-based batching, each iteration re-scans from the start to find the next batch. On a 1.6B row table this degrades over time. RecID range batching does a precise clustered index seek every iteration — constant speed regardless of position.

**Step 1 — Check how many rows actually qualify (do this first):**
```sql
-- Find the RecID cutoff for 6 months ago
-- Use NOLOCK since exact count is not critical here
SELECT
    COUNT(*)              AS rows_to_archive,
    MIN(RecID)            AS min_recid,
    MAX(RecID)            AS cutoff_recid,
    MIN(Process_date)     AS oldest_date,
    MAX(Process_date)     AS cutoff_date
FROM [BLACKBOARD].[dbo].Banner_Grade_Push_log WITH (NOLOCK)
WHERE Process_date < DATEADD(MONTH, -6, GETDATE());
```

This tells you the scope. Save the `cutoff_recid` value — use it as a fixed target in the loop below (do not recalculate it inside the loop).

**Step 2 — RecID range-based batch INSERT + DELETE loop:**
```sql
DECLARE @BatchSize   BIGINT = 100000;
DECLARE @StartID     BIGINT = 1;
DECLARE @CutoffID    BIGINT;   -- fill from Step 1 result, e.g. 1200000000
DECLARE @EndID       BIGINT;
DECLARE @Inserted    INT;
DECLARE @Deleted     INT;
DECLARE @BatchNum    INT = 0;

-- Set the cutoff RecID from Step 1 result:
SET @CutoffID = 1200000000;   -- REPLACE with actual cutoff_recid from Step 1

WHILE @StartID <= @CutoffID
BEGIN
    SET @EndID = @StartID + @BatchSize - 1;
    SET @BatchNum = @BatchNum + 1;

    -- Archive batch
    INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive]
           (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
    SELECT  RecID, StudentID, ClassID, Process_Status, Process_date,
            LEFT(ISNULL(Banner_response_Message, ''), 1000)  -- truncate for varchar(1000)
    FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
    WHERE  RecID BETWEEN @StartID AND @EndID
      AND  Process_date < DATEADD(MONTH, -6, GETDATE());

    SET @Inserted = @@ROWCOUNT;

    -- Delete same batch from source
    DELETE FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
    WHERE  RecID BETWEEN @StartID AND @EndID
      AND  Process_date < DATEADD(MONTH, -6, GETDATE());

    SET @Deleted = @@ROWCOUNT;

    -- Progress log
    PRINT CONCAT('Batch ', @BatchNum,
                 ' | RecID ', @StartID, '-', @EndID,
                 ' | Inserted: ', @Inserted,
                 ' | Deleted: ', @Deleted);

    SET @StartID = @StartID + @BatchSize;

    -- Pause to reduce I/O pressure on production
    WAITFOR DELAY '00:00:02';
END

PRINT 'Archive complete.';
```

**Why this approach works at scale:**

| | TOP-based loop | RecID range loop |
|---|---|---|
| Each iteration | Scans from row 1 to find next batch | Direct seek to `RecID BETWEEN x AND y` |
| Speed over time | Slows down as processed rows accumulate | Constant — clustered index seek is O(log n) |
| Progress tracking | Unknown — no fixed endpoint | Predictable: `(@StartID / @CutoffID) * 100%` |
| Restartable | Must track last processed row externally | Just note last `@StartID` and resume |

**Monitor progress in a second window:**
```sql
-- See how far the loop has gotten (check the PRINT output in the Messages tab)
-- Or query current archive count:
SELECT COUNT(*) AS archived_so_far FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive];
```

**Practical advice for 1.6B rows:**
- Run off-peak (nights/weekends) — this will take many hours across multiple sessions
- If you need to stop and resume: note the last `@StartID` printed, then set `@StartID` to that value when restarting
- `@BatchSize = 100000` is a good starting point; reduce to 50000 if transaction log grows too fast, increase to 200000 if the server is lightly loaded
- After archiving is done, run `ALTER INDEX ALL ON Banner_Grade_Push_log REBUILD` to reclaim fragmented space

* q. Provide step2 into a stored proc, spAdminArchiveBannerPushLogByRecIDRange
  * parameter StartID, EndID
  * Implement with TRY/CATCH so that it will be safe to resume on error.

## Stored Procedure: spAdminArchiveBannerPushLogByRecIDRange
[](./sql/[dbo].[spAdminArchiveBannerPushLogByRecIDRange].sql)

**Calling loop — resumes safely from last successful StartID on error:**
[](./sql/spAdminArchiveLoop.sql)

**TRY/CATCH behaviour:**
- If INSERT succeeds but DELETE fails → `ROLLBACK` undoes the INSERT — no orphaned archive rows, no data loss
- The calling loop prints the resume `@StartID`, stops cleanly, no partial batches committed
- On resume: set `@StartID` to the printed value and re-run the loop — already-archived batches are skipped (the `WHERE Process_date < ...` filter prevents re-inserting them)

---

* q. Why the last step is required?
```
After archiving is done, run `ALTER INDEX ALL ON Banner_Grade_Push_log REBUILD` to reclaim fragmented space
```

# Why ALTER INDEX REBUILD Is Required After Mass Delete

**Because deleting rows does not remove their index pages. The index structure becomes full of mostly-empty pages — this is called fragmentation.**

Here is what happens step by step:

**Before archiving:**
- Table has 1.6B rows, indexes are compact and full
- Each 8KB data page holds ~100–200 rows (depending on row width)

**After deleting ~1B+ rows:**
- SQL Server marks deleted rows as "ghost records" — the rows are gone logically but the pages remain allocated
- Ghost cleanup eventually removes the ghost records, leaving pages that are now 90%+ empty
- The B-tree index still has leaf-level pointers to all those sparse pages
- Example: what used to be 10 million full pages is now 10 million pages each holding only 10% of their capacity

**Effect on queries:**
- `SELECT COUNT(*)` must still scan all 10 million pages (even though they are mostly empty)
- `SELECT TOP 100 ORDER BY Process_date DESC` still traverses sparsely populated index leaf pages
- Disk I/O increases — SQL Server reads pages with almost no data in them

**`ALTER INDEX ALL ON table REBUILD` fixes this:**
```sql
-- Run after archiving is complete
-- This rewrites all indexes from scratch, compacting pages
ALTER INDEX ALL ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] REBUILD
WITH (ONLINE = ON);  -- add if Enterprise edition, to avoid locking during rebuild
```

What REBUILD does:
- Reads all non-deleted rows
- Writes them back into a new, compact index structure
- Pages are now full again (typically 80–90% fill factor)
- The old sparse pages are deallocated and returned to free space

**Result:** Index size shrinks from ~1.6B row equivalent to ~600M row equivalent; queries return to fast speeds.

**Lighter alternative — REORGANIZE:**
```sql
-- REORGANIZE: online, less disruptive, but only defragments — does not compact empty pages at the bottom
ALTER INDEX ALL ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] REORGANIZE;
```

Use REBUILD after a mass delete. REORGANIZE is better for routine weekly maintenance when fragmentation is incremental.


* q. If I archive delta records daily (hundreds of records), show me how to use `REORGANIZE`.

# Daily Delta Archiving — Using REORGANIZE for Routine Maintenance

**For hundreds of rows deleted per day, fragmentation accumulates slowly. REORGANIZE run weekly is the right level of maintenance — REBUILD is overkill until fragmentation exceeds ~30%.**

**Standard fragmentation thresholds:**

| Fragmentation % | Action |
|---|---|
| < 5% | None needed |
| 5% – 30% | `REORGANIZE` — online, lightweight, sufficient |
| > 30% | `REBUILD` — compacts empty pages, reclaims space |

For daily deletes of a few hundred rows, you will stay below 5% for weeks. Weekly REORGANIZE is more than enough.

**Step 1 — Check current fragmentation (run any time):**
```sql
SELECT
    i.name                          AS index_name,
    i.type_desc                     AS index_type,
    s.avg_fragmentation_in_percent  AS frag_pct,
    s.page_count
FROM sys.dm_db_index_physical_stats(
         DB_ID('BLACKBOARD'),
         OBJECT_ID('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]'),
         NULL,   -- all indexes
         NULL,   -- all partitions
         'LIMITED'
     ) s
JOIN sys.indexes i
    ON i.object_id = s.object_id
    AND i.index_id = s.index_id
WHERE s.page_count > 100  -- skip tiny indexes
ORDER BY s.avg_fragmentation_in_percent DESC;
```

**Step 2 — Smart maintenance script (decide REORGANIZE vs REBUILD automatically):**
```sql
-- Run this weekly via SQL Agent Job
DECLARE @frag FLOAT;

SELECT @frag = avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(
         DB_ID('BLACKBOARD'),
         OBJECT_ID('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]'),
         1,        -- index_id 1 = clustered index
         NULL,
         'LIMITED'
     );

IF @frag IS NULL
    PRINT 'No index stats available — table may be too small or stats not yet collected.';
ELSE IF @frag < 5
    PRINT CONCAT('Fragmentation ', @frag, '% — no action needed.');
ELSE IF @frag <= 30
BEGIN
    PRINT CONCAT('Fragmentation ', @frag, '% — running REORGANIZE...');
    ALTER INDEX ALL ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] REORGANIZE;
    PRINT 'REORGANIZE complete.';
END
ELSE
BEGIN
    PRINT CONCAT('Fragmentation ', @frag, '% — running REBUILD...');
    ALTER INDEX ALL ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] REBUILD
    WITH (ONLINE = ON);   -- remove WITH clause if Standard edition
    PRINT 'REBUILD complete.';
END
```

**REORGANIZE vs REBUILD for daily delta scenario:**

| | REORGANIZE | REBUILD |
|---|---|---|
| Always online | Yes — never blocks reads/writes | Only with Enterprise + `ONLINE=ON` |
| What it fixes | Defragments existing pages, compacts adjacent pages | Rewrites entire index, reclaims empty pages |
| When sufficient | Fragmentation 5–30%, small daily deletes | Fragmentation > 30%, or after a mass delete |
| Resource cost | Low — runs incrementally | High — full index rewrite |
| Updates statistics | No — must run `UPDATE STATISTICS` separately | Yes — automatically |

**Because REORGANIZE does not update statistics, add this after:**
```sql
ALTER INDEX ALL ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] REORGANIZE;

-- Update stats so the query optimizer has accurate row counts
UPDATE STATISTICS [BLACKBOARD].[dbo].[Banner_Grade_Push_log];
```

**Suggested SQL Agent Job schedule for daily archiving scenario:**
- **Daily archive job** (nightly): calls `spAdminArchiveBannerPushLogByRecIDRange` loop for yesterday's records
- **Weekly maintenance job** (Sunday off-peak): runs the smart REORGANIZE/REBUILD script above + UPDATE STATISTICS
- **Monthly check**: re-run the fragmentation query; if consistently < 5% after weekly REORGANIZE, extend to monthly maintenance

* I got cut off date:
* [cut-off date](./imgs/cut-off.png)

* q. I got statistics as below:
* [](./imgs/calculate-fragmentation.png)
* Although `IX_Banner_Grade_Push_log_ProcessDate` is not clustered index (primary key), it went up to 99%. Why is it so? And is it worth of doing `REBUILD` index? Answer here in next line.

## Why `IX_Banner_Grade_Push_log_ProcessDate` Reaches 99% Fragmentation

**Root cause: DESC index on an ever-increasing column creates a permanent hot-spot at the front of the index.**

`Banner_Grade_Push_log` is an active log table — new rows are constantly inserted with the most recent `Process_date`. Here is what happens inside the B-tree:

| Index direction | Where new inserts land | Effect |
|---|---|---|
| `Process_date ASC` | Rightmost leaf page (highest date = end of sorted order) | Sequential append → near-zero fragmentation (same as IDENTITY pattern) |
| `Process_date DESC` | **Leftmost leaf page** (highest date = start of sorted order) | Every insert hits the same page → page splits → rapid fragmentation |

Because the index was created as `DESC`, every new grade push record immediately goes to the very first leaf page. That page fills up, splits into two half-empty pages, and the cycle repeats. Even a short period of active inserts after index creation can push fragmentation above 90%.

**Is it worth doing `REBUILD`?**

Short answer: **Yes, but change the index direction at the same time — otherwise it will fragment again within hours.**

**Fix — drop and recreate as ASC:**

```sql
-- Drop the fragmented DESC index
DROP INDEX IX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log];

-- Recreate as ASC — SQL Server can satisfy ORDER BY Process_date DESC
-- by scanning the ASC index backwards, equally efficient
CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] (Process_date ASC)
WITH (ONLINE = ON);
```

With `ASC`, new inserts always go to the rightmost page (same physical order as arrival). No hot-spot, no page splits — fragmentation stays near 0% indefinitely.

**Does `ORDER BY Process_date DESC` still use the ASC index?**

Yes. SQL Server's query optimizer can scan any index in either direction. `SELECT TOP 100 * ORDER BY Process_date DESC` will use the ASC index with a backward scan — performance is identical to the DESC index.

**Summary:**

| Action | Result |
|---|---|
| REBUILD the DESC index as-is | Fragmentation reset to ~0% but returns to 99% within hours |
| Drop DESC + recreate as ASC | Fragmentation stays near 0% permanently |

Recreate as ASC. The REBUILD alone is wasted effort on an active log table.

* q. After creating Archive table, do I need to create Index on this archive table as well? if so, is it better to create index first before inserting to archive table?

## Archive Table — Do You Need Indexes, and When to Create Them?

**Short answers:**
1. **Do you need indexes?** Only if you query the archive table. For a pure storage/compliance table, no index is fine.
2. **Before or after bulk insert?** Always **after** for large bulk loads.

---

**Do you need indexes on the archive table?**

| Query pattern | Index needed |
|---|---|
| Never queried (storage only) | None — saves disk space |
| `WHERE Process_date BETWEEN x AND y` | NC index on `Process_date` |
| `WHERE StudentID = 'A0001234'` | NC index on `StudentID` |
| `WHERE RecID = 12345` (lookup by ID) | Clustered PK on `RecID` |
| General audit browsing by date | Clustered PK on `RecID` + NC on `Process_date` |

For a **grade push log archive**, typical access is:
- "Show me all pushes for student X" → need `StudentID` index
- "Show me pushes around date Y" → need `Process_date` index
- Most archive tables are queried rarely and don't need all the same indexes as the live table

**Recommended minimal indexes for the archive table:**
```sql
-- Clustered PK on RecID (prevents duplicates, enables fast single-row lookup)
ALTER TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive]
ADD CONSTRAINT PK_Banner_Grade_Push_log_Archive PRIMARY KEY CLUSTERED (RecID ASC);

-- NC index on Process_date for date-range audit queries
CREATE NONCLUSTERED INDEX IX_Archive_ProcessDate
ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive] (Process_date DESC);
```

---

**Before or after bulk insert — create indexes AFTER:**

When inserting millions of rows into a table that already has indexes, SQL Server must maintain the index for **every single row inserted**. For a bulk load of 1B rows this is extremely slow.

The correct pattern for bulk loading:

```
1. Create table (no indexes)      ← fast table creation
2. Bulk INSERT all data           ← maximum insert speed, no index overhead
3. Create indexes                 ← one-time build on completed data
```

vs the wrong pattern:
```
1. Create table with indexes
2. Bulk INSERT → SQL Server updates index per row ← very slow
```

**For your specific scenario:**

| Phase | Action |
|---|---|
| Initial migration (1B rows) | Create archive table **without** indexes → bulk INSERT → then create indexes |
| Daily delta (hundreds of rows) | Keep indexes in place — small batches don't cause meaningful overhead |

**Complete sequence for the initial migration:**
```sql
-- Step 1: Table already created (no indexes) — good, leave it

-- Step 2: Run the RecID range batch loop (spAdminArchiveBannerPushLogByRecIDRange)
--         Insert all historical rows first

-- Step 3: After all rows inserted, THEN create indexes:
ALTER TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive]
ADD CONSTRAINT PK_Banner_Grade_Push_log_Archive PRIMARY KEY CLUSTERED (RecID ASC);

CREATE NONCLUSTERED INDEX IX_Archive_ProcessDate
ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive] (Process_date DESC);

-- Step 4: Update statistics
UPDATE STATISTICS [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive];
```

**Why is index-after faster?**
- SQL Server uses a **sort + bulk build** algorithm when building an index on existing data — much more efficient than updating a B-tree per row
- The PK clustered index build on `RecID` will be near-instant since `RecID` values are already sequential (IDENTITY order from the source table)

* Archive script works good, but it will take a while:
  * [](./imgs/archive-with-batch.png)
```
5,000,001
8,400,001
11,700,001
...
10 milion/10min
1000 milion/1000min -> 16 hours
```

* q. If I just copy/past table, `Banner_Grade_Push_log`, would it be faster than 16 hours?

## Can a Bulk Table Copy Beat 16 Hours?

**Yes — dramatically. The fastest approach for your situation is the Rename/Swap trick: ~minutes instead of 16 hours.**

---

**Why the batch loop is slow:**
Each batch does a logged INSERT + logged DELETE inside a transaction. For 1B rows, that is ~10,000 round trips with transaction overhead, lock acquisition, and log writes per batch.

---

**Option A — Rename/Swap (FASTEST — recommended)**

Instead of moving old rows to archive, flip the tables: rename the giant table to the archive name, create a new small live table, copy only the recent 6 months back in.

```sql
-- Step 1: Rename the live table to the archive name (INSTANT — metadata only, < 1 second)
EXEC sp_rename
    '[BLACKBOARD].[dbo].[Banner_Grade_Push_log]',
    'Banner_Grade_Push_log_Old';

-- Step 2: Create a new, clean live table (identical schema)
CREATE TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log] (
    [RecID]                   bigint        IDENTITY(1,1) NOT NULL,
    [StudentID]               varchar(50)   NULL,
    [ClassID]                 varchar(50)   NULL,
    [Process_Status]          varchar(50)   NULL,
    [Process_date]            datetime2(7)  NULL,
    [Banner_response_Message] varchar(max)  NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

-- Step 3: Copy only the RECENT 6 months into the new live table
-- (only a fraction of 1.6B rows — much faster than moving old data)
SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] ON;

INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
       (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
SELECT  RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message
FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old]
WHERE  Process_date >= DATEADD(MONTH, -6, GETDATE());

SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] OFF;

-- Step 4: Recreate indexes on the new live table
ALTER TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
ADD CONSTRAINT PK_Banner_Grade_Push_log PRIMARY KEY CLUSTERED (RecID ASC);

CREATE NONCLUSTERED INDEX IX_Banner_Grade_Push_log_ProcessDate
ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log] (Process_date DESC);

-- Step 5: The old table IS the archive — rename it properly
-- (your existing Banner_Grade_Push_log_Archive has different schema — keep both or drop one)
EXEC sp_rename
    '[BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old]',
    'Banner_Grade_Push_log_Archive_Full';
```

**Why this is fast:**
- Step 1 rename: metadata change only — no data moved, takes < 1 second
- Step 3 insert: only ~6 months of rows (maybe 50–100M instead of 1B) — ~1–2 hours instead of 16
- The 1B+ old rows stay in place on disk, just under a different table name

**Requirement:** App writes must pause briefly between Step 1 and Step 3 (or use a maintenance window). Once Step 3 completes, point the app back at the new `Banner_Grade_Push_log`.

---

**Option B — `SELECT * INTO` (bulk copy, no batching)**

If you want to populate the existing archive table in one shot rather than batches:

```sql
-- Requires SIMPLE or BULK_LOGGED recovery model for minimal logging
-- Check current model:
SELECT recovery_model_desc FROM sys.databases WHERE name = 'BLACKBOARD';

-- If FULL recovery, temporarily switch (confirm with DBA first):
-- ALTER DATABASE BLACKBOARD SET RECOVERY BULK_LOGGED;

INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Archive]
       (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
SELECT  RecID, StudentID, ClassID, Process_Status, Process_date,
        LEFT(ISNULL(Banner_response_Message, ''), 1000)
FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
WHERE  Process_date < DATEADD(MONTH, -6, GETDATE());

-- Restore recovery model if changed:
-- ALTER DATABASE BLACKBOARD SET RECOVERY FULL;
```

Under BULK_LOGGED: minimally logged — 3–5x faster than the batch loop. Still slower than Option A because it still moves ~1B rows.

---

**Summary:**

| Approach | Speed | Data moved | Risk |
|---|---|---|---|
| Batch loop (current) | ~16 hrs | 1B rows archived, 1B rows deleted | Low — resumable |
| Option B: bulk INSERT | ~3–5 hrs | 1B rows inserted | Medium — needs recovery model change |
| **Option A: Rename/Swap** | **~1–2 hrs** | **Only 6-month recent rows inserted** | Medium — needs brief maintenance window |

**Recommendation:** Use Option A (Rename/Swap). The rename is instant, and you only pay the I/O cost for recent records. The 1B+ historical rows never move — they're already on disk, just archived under a new table name.


* q. for step3, after this line:
`SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] ON;`
, I understand that I can insert `RecID` with value. But what about other processes that are inserting records into this table? Will they still populate `RecID` automatically?

## IDENTITY_INSERT ON — Effect on Other Concurrent Sessions

**Yes — other processes continue inserting with auto-generated RecIDs normally. `SET IDENTITY_INSERT` is session-scoped and only affects the session that ran it.**

**What happens per session:**

| Session | IDENTITY_INSERT state | INSERT behaviour |
|---|---|---|
| Your session | `ON` | Must specify `RecID` explicitly — auto-generation is disabled **for your session** |
| Other sessions (app writes) | Not set (default OFF) | Auto-generate `RecID` normally — unaffected |

Other processes inserting new grade push records will get auto-generated RecIDs as usual. Your explicit inserts coexist safely.

**However — there is one important caveat: IDENTITY seed after the bulk insert.**

When the new table is created empty (`IDENTITY(1,1)`), new auto-inserts from other processes start at RecID = 1, 2, 3…

Your bulk insert (Step 3) inserts old records with RecIDs like 1,500,000,000+.

These do not collide (different ranges). But after Step 3 completes, SQL Server needs to know the correct next IDENTITY value. SQL Server does update the seed when explicit values are inserted, but to be safe and explicit, **reseed immediately after turning IDENTITY_INSERT OFF:**

```sql
-- After Step 3 INSERT completes:
SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] OFF;

-- Reseed IDENTITY to max RecID from the old table so new inserts continue from there
DECLARE @MaxRecID BIGINT;
SELECT @MaxRecID = MAX(RecID) FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old];
DBCC CHECKIDENT('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]', RESEED, @MaxRecID);
-- Next auto-generated RecID will be @MaxRecID + 1 (e.g. 1,656,776,248)
```

**Updated complete Step 3 sequence:**
```sql
-- Turn on explicit insert
SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] ON;

-- Bulk insert recent 6 months from old table
INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
       (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
SELECT  RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message
FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old]
WHERE  Process_date >= DATEADD(MONTH, -6, GETDATE());

-- Turn off explicit insert
SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] OFF;

-- Reseed so new auto-inserts continue from the right value
DECLARE @MaxRecID BIGINT;
SELECT @MaxRecID = MAX(RecID) FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old];
DBCC CHECKIDENT('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]', RESEED, @MaxRecID);
```

**One more constraint to be aware of:** Only one table per database can have `IDENTITY_INSERT ON` at a time. If another session tries to do `SET IDENTITY_INSERT [any_table] ON` during your Step 3, it will get an error. Normal inserts without `IDENTITY_INSERT` are unaffected.


* q. I want `RecID` sequentially increase so that I can know bigger `RecID` means that it was inserted later. So after `step2: create a new live table`, can i just reseed eg, 2,000,000,000 so that all concurrent insert will start from 2billon, but old manual insert will keep their `RecID` between 1 and 1656776247?

* a. **Yes — this is an excellent approach and actually better than the previous plan.** Reseeding to 2,000,000,000 immediately after Step 2 (before any app traffic resumes) gives you everything you want:

| RecID range | Source | Meaning |
|---|---|---|
| 1 – 1,656,776,247 | IDENTITY_INSERT from old table | Historical records (original values preserved) |
| 1,656,776,248 – 1,999,999,999 | (gap — intentional buffer) | Empty, reserved |
| 2,000,000,001+ | Normal auto-increment | New live inserts going forward |

**Why this works:**
- After `DBCC CHECKIDENT(..., RESEED, 2000000000)`, SQL Server's internal identity counter is set to 2,000,000,000. The *next* auto-generated value will be **2,000,000,001**.
- `IDENTITY_INSERT ON` lets you supply explicit RecID values (the historical 1–1.6B range). These explicit values do **not** touch the internal counter — the seed stays at 2B.
- Concurrent app inserts (no `IDENTITY_INSERT`) will auto-generate from 2,000,000,001 onwards. No collision possible.
- You no longer need the `DBCC CHECKIDENT` call **after** Step 3 (the old plan needed it to advance the seed past the max inserted value). With 2B pre-seeded, the seed is already well above any historical RecID.

**Updated Step 2 — create new table and reseed immediately:**

```sql
-- Step 2a: Create new empty live table
CREATE TABLE [BLACKBOARD].[dbo].[Banner_Grade_Push_log] (
    [RecID]                    [bigint] IDENTITY(1,1) NOT NULL,
    [StudentID]                [varchar](50)   NULL,
    [ClassID]                  [varchar](50)   NULL,
    [Process_Status]           [varchar](50)   NULL,
    [Process_date]             [datetime2](7)  NULL,
    [Banner_response_Message]  [varchar](1000) NULL,
    CONSTRAINT [PK_Banner_Grade_Push_log] PRIMARY KEY CLUSTERED ([RecID] ASC)
);

-- Step 2b: Reseed to 2 billion — do this BEFORE app traffic resumes
DBCC CHECKIDENT('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]', RESEED, 2000000000);
-- Next auto-insert will get RecID = 2,000,000,001
```

**Step 3 — IDENTITY_INSERT of recent 6-month records (unchanged, no reseed needed after):**

```sql
SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] ON;

INSERT INTO [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
       (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
SELECT  RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message
FROM   [BLACKBOARD].[dbo].[Banner_Grade_Push_log_Old]
WHERE  Process_date >= DATEADD(MONTH, -6, GETDATE());

SET IDENTITY_INSERT [BLACKBOARD].[dbo].[Banner_Grade_Push_log] OFF;

-- No DBCC CHECKIDENT needed here — seed is already at 2B, well above all inserted RecIDs
```

**Verify the seed is correct after Step 3:**

```sql
DBCC CHECKIDENT('[BLACKBOARD].[dbo].[Banner_Grade_Push_log]', NORESEED);
-- Output: "Checking identity information: current identity value '2000000000',
--          current column value '1656776247' (or similar)"
-- The "current identity value" must be >= 2,000,000,000 — confirm before re-enabling app
```

**One caution — order of operations matters:**
1. Step 1: Rename live table → `Banner_Grade_Push_log_Old` (stop new writes to old table)
2. Step 2a: Create new `Banner_Grade_Push_log`
3. **Step 2b: `DBCC CHECKIDENT` reseed to 2B** ← do this before re-enabling app connections
4. Step 3: IDENTITY_INSERT the recent 6 months
5. Re-enable app traffic → new inserts auto-get RecID 2,000,000,001+
6. Background: batch-archive the remaining old records into `Banner_Grade_Push_log_Archive`

If you re-enable the app *before* Step 2b, the first auto-insert gets RecID = 1 (the IDENTITY starts fresh from 1). That would collide with your Step 3 IDENTITY_INSERT. So the reseed must happen before any app write reaches the new table.


* Archive is done. Now I have:
* Banner_Grade_Push_log: now only has 6months data (5milion records). 
* Banner_Grade_Push_log_OLD: has archived records (1billion). 
* q. For ongoing daily maintenance, is it good idea keep inserting more-than-6month-old records into OLD table? The OLD table will keep increasing and it is already hard to run select query in case I need to log at it.

## Ongoing Daily Maintenance — Should You Keep Appending to the OLD Table?

**No. Stop inserting into `Banner_Grade_Push_log_OLD`. It is already 1B rows and hard to query — growing it further makes both problems worse.**

Treat `Banner_Grade_Push_log_OLD` as a **frozen, read-only historical archive**. It will never be touched again except for occasional lookups.

For ongoing daily archiving, use **yearly archive tables** instead:

---

**Recommended strategy — yearly partition tables:**

```
Banner_Grade_Push_log          ← live table, rolling 6 months (~5M rows)
Banner_Grade_Push_log_OLD      ← frozen historical archive, read-only (1B rows)
Banner_Grade_Push_log_2025     ← year-bucket archive for 2025 records
Banner_Grade_Push_log_2026     ← year-bucket archive for 2026 records
...
```

Each year-bucket holds records where `YEAR(Process_date) = N`. When a record in the live table ages past 6 months, it moves to the corresponding year bucket — not into the ever-growing OLD table.

**Daily archive job — move aged records to yearly table:**

```sql
-- Run nightly via SQL Agent Job
-- Creates the yearly table if it doesn't exist, then moves records older than 6 months

DECLARE @ArchiveYear  INT  = YEAR(DATEADD(MONTH, -6, GETDATE()));
DECLARE @TableName    NVARCHAR(200) =
    CONCAT('[BLACKBOARD].[dbo].[Banner_Grade_Push_log_', @ArchiveYear, ']');

-- Create yearly archive table if it doesn't exist
IF OBJECT_ID(@TableName) IS NULL
BEGIN
    DECLARE @SQL NVARCHAR(MAX) = CONCAT('
        CREATE TABLE ', @TableName, ' (
            [RecID]               bigint        NOT NULL,
            [StudentID]           varchar(50)   NULL,
            [ClassID]             varchar(50)   NULL,
            [Process_Status]      varchar(50)   NULL,
            [Process_date]        datetime2(7)  NULL,
            [Banner_response_Message] varchar(1000) NULL,
            [DateArchived]        datetime2(7)  NOT NULL DEFAULT GETDATE(),
            CONSTRAINT [PK_BannerLog_', @ArchiveYear, '] PRIMARY KEY CLUSTERED (RecID ASC)
        );
        CREATE NONCLUSTERED INDEX [IX_BannerLog_', @ArchiveYear, '_ProcessDate]
        ON ', @TableName, ' (Process_date ASC);
    ');
    EXEC sp_executesql @SQL;
    PRINT CONCAT('Created archive table for year ', @ArchiveYear);
END

-- Move records older than 6 months into the yearly table (in one batch — it's daily, small volume)
DECLARE @MovedSQL NVARCHAR(MAX) = CONCAT('
    INSERT INTO ', @TableName, ' (RecID, StudentID, ClassID, Process_Status, Process_date, Banner_response_Message)
    SELECT RecID, StudentID, ClassID, Process_Status, Process_date,
           LEFT(ISNULL(Banner_response_Message, ''''), 1000)
    FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
    WHERE Process_date < DATEADD(MONTH, -6, GETDATE())
      AND YEAR(Process_date) = ', @ArchiveYear, ';
');
EXEC sp_executesql @MovedSQL;
DECLARE @Inserted INT = @@ROWCOUNT;

-- Delete moved records from live table
DELETE FROM [BLACKBOARD].[dbo].[Banner_Grade_Push_log]
WHERE Process_date < DATEADD(MONTH, -6, GETDATE())
  AND YEAR(Process_date) = @ArchiveYear;

PRINT CONCAT('Archived ', @Inserted, ' records to ', @TableName);
```

---

**Why yearly tables are better than one growing OLD table:**

| | Single OLD table | Yearly tables |
|---|---|---|
| Query "show pushes from 2024" | Scan 1B+ rows | Scan only `Banner_Grade_Push_log_2024` |
| Query "show student X history" | Full table scan | Scan one small yearly table |
| Drop data when retention expires | Cannot drop partial rows easily | `DROP TABLE Banner_Grade_Push_log_2022` — instant |
| Table size over time | Grows forever | Each table capped at ~1 year of data |
| Backup/restore | Always huge | Backup only the years you need |

**What to do with `Banner_Grade_Push_log_OLD` now:**
- Leave it as-is — it is your pre-2025 history
- Add a NC index on `Process_date ASC` if you need to query it:
  ```sql
  CREATE NONCLUSTERED INDEX IX_OLD_ProcessDate
  ON [BLACKBOARD].[dbo].[Banner_Grade_Push_log_OLD] (Process_date ASC)
  WITH (ONLINE = ON);
  ```
- When your data retention policy allows (e.g. 3 years), simply `DROP TABLE Banner_Grade_Push_log_OLD`

**Summary of ongoing maintenance schedule:**

| Job | Frequency | Action |
|---|---|---|
| Archive aged records | Nightly | Move records >6 months from live table to yearly table |
| Index maintenance | Weekly | REORGANIZE + UPDATE STATISTICS on live table |
| Fragmentation check | Monthly | Check frag %; REBUILD if >30% |
| Retention cleanup | Yearly | `DROP TABLE Banner_Grade_Push_log_YYYY` for expired years |
