# Session Storage Fix

## Problem
You were getting an "Invalid session ID" error when trying to generate embeddings. This happened because:

1. Flask runs in debug mode with auto-reload enabled
2. When any file changes, the server restarts
3. The in-memory `processed_data` dictionary was cleared on restart
4. Your session ID became invalid

## Solution
Replaced in-memory storage with **file-based session storage**:

- Sessions are now saved to disk using Python's `pickle` module
- Storage location: `%TEMP%/embedding_tool_sessions/`
- Sessions persist across server restarts
- Each session is saved as a `.pkl` file

## Changes Made

### Updated `server.py`:
1. Added file-based storage functions:
   - `save_session_data()` - Saves session to disk
   - `load_session_data()` - Loads session from disk
   - `session_exists()` - Checks if session exists

2. Updated all endpoints to use file storage:
   - `/api/upload` - Saves CSV data to disk
   - `/api/generate` - Loads data from disk, saves results to disk
   - `/api/download/<format>` - Loads results from disk

3. Better error messages:
   - "Invalid session ID. Please upload your CSV file again."
   - "Session data not found. Please upload your CSV file again."

## How It Works Now

1. **Upload CSV** → Session saved to: `{temp}/embedding_tool_sessions/{session_id}.pkl`
2. **Generate Embeddings** → Results saved to: `{temp}/embedding_tool_sessions/{session_id}_results.pkl`
3. **Download** → Results loaded from disk and formatted

## Benefits

✅ Sessions survive server restarts
✅ No more "invalid session ID" errors
✅ Better error messages with helpful instructions
✅ Automatic cleanup (temp folder is cleared on system restart)

## Try It Now

The fix is already applied! Just:
1. Refresh your browser at http://localhost:5000
2. Upload your CSV file
3. Generate embeddings - it should work now!

The server will no longer lose your session when files are modified.
