"""Talos download engine entry points for the embedded Python runtime.

This module runs inside the Android app. It executes yt-dlp in-process and
buffers raw CLI lines per task. The host polls `drain(task_id)` to fetch
pending events and decides on cancellation through `cancel(task_id)`, so
no Java object is ever used from Python except inside the merge step.
The Dart side parses the lines with the same parser used on desktop.
"""

import io
import os
import re
import sys
import json
import shlex
import threading
import traceback


class DownloadCancelled(Exception):
    pass


_tasks = {}
_cancel_requested = set()
_tasks_lock = threading.Lock()

_DEST_RE = re.compile(r'^\[download\]\s+Destination:\s*(.+)$', re.IGNORECASE)
_F_PART = re.compile(r'^(.*?)\.f\d+\.([A-Za-z0-9]+)$')


def init(task_id):
    """Create the event buffer for a task, honoring a pending cancel."""
    with _tasks_lock:
        cancel = task_id in _cancel_requested
        _cancel_requested.discard(task_id)
        _tasks[task_id] = {'pending': [], 'cancel': cancel, 'files': []}
    return 'ok'


def drain(task_id):
    """Return the buffered events as a JSON array and clear the buffer."""
    with _tasks_lock:
        state = _tasks.get(task_id)
        if state is None:
            return '[]'
        items = state['pending']
        state['pending'] = []
    return json.dumps(items)


def cancel(task_id):
    """Request cancellation. Safe to call before init or after run."""
    with _tasks_lock:
        state = _tasks.get(task_id)
        if state is not None:
            state['cancel'] = True
        else:
            _cancel_requested.add(task_id)
    return 'ok'


def cleanup(task_id):
    """Drop the task buffer to keep the map bounded."""
    with _tasks_lock:
        _tasks.pop(task_id, None)
        _cancel_requested.discard(task_id)
    return 'ok'


class _LineWriter(io.TextIOBase):
    def __init__(self, on_line, is_cancelled, on_destination=None):
        super().__init__()
        self._on_line = on_line
        self._is_cancelled = is_cancelled
        self._on_destination = on_destination
        self._buf = ''

    def writable(self):
        return True

    def write(self, s):
        self._buf += s
        while '\n' in self._buf:
            line, self._buf = self._buf.split('\n', 1)
            self._emit(line)
        return len(s)

    def flush(self):
        if self._buf:
            self._emit(self._buf)
            self._buf = ''

    def _emit(self, line):
        line = line.rstrip('\r').rstrip('\n')
        if self._is_cancelled():
            raise DownloadCancelled()
        if self._on_destination:
            match = _DEST_RE.match(line)
            if match:
                self._on_destination(match.group(1).strip())
        self._on_line(line)


def _run(argv, on_line, is_cancelled, on_destination=None):
    import yt_dlp

    writer = _LineWriter(on_line, is_cancelled, on_destination)
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout, sys.stderr = writer, writer
    try:
        yt_dlp.main(list(argv))
        writer.flush()
        return 0
    finally:
        sys.stdout, sys.stderr = old_out, old_err


def version():
    try:
        import yt_dlp
        inner = getattr(yt_dlp, 'version', None)
        return str(getattr(yt_dlp, '__version__', getattr(inner, '__version__', 'unknown')))
    except Exception:
        return 'unknown'


def probe(url, proxy):
    argv = ['--dump-single-json', '--flat-playlist', '--skip-download', '--no-warnings']
    if proxy:
        argv += ['--proxy', proxy]
    argv += [url]

    buffer = io.StringIO()
    try:
        _run(argv, lambda line: buffer.write(line + '\n'), lambda: False)
    except SystemExit as exc:
        if exc.code not in (0, None):
            raise RuntimeError('yt-dlp exited with code %s' % exc.code)
    except Exception:
        traceback.print_exc()
        raise
    return buffer.getvalue()


def custom(template, url):
    parts = []
    for token in shlex.split(template or ''):
        parts.append(token.replace('{url}', url))
    buffer = io.StringIO()
    if not parts:
        return 'The command template is empty.'
    try:
        _run(parts, lambda line: buffer.write(line + '\n'), lambda: False)
    except SystemExit as exc:
        if exc.code not in (0, None):
            buffer.write('yt-dlp exited with code %s\n' % exc.code)
    return buffer.getvalue()


_MP4_EXTENSIONS = ('.mp4', '.m4a', '.mov', '.3gp', '.3g2')


def _safe_merge(parts, on_line):
    """Merge separate video and audio files with the bundled FFmpeg.

    The Android build has no `ffmpeg` executable on PATH, so yt-dlp downloads
    the streams separately and leaves them there. This merges them with the
    in-app FFmpegKit (dynamic link, LGPL-3.0) and deletes the parts.
    Returns the merged path, or None when there is nothing to merge or it is
    not safe to try.
    """
    if len(parts) != 2:
        return None

    parsed = [_F_PART.match(p) for p in parts]
    if not all(parsed):
        return None
    if parsed[0].group(1) != parsed[1].group(1):
        return None

    base, ext = parsed[0].group(1), parsed[0].group(2).lower()
    # The video stream may come second; the largest file is almost always video.
    exts = [parsed[0].group(2).lower(), parsed[1].group(2).lower()]
    mp4_out = all(e in ('mp4', 'm4a', 'mov', '3gp', '3g2') for e in exts)
    out_ext = 'mp4' if mp4_out else 'mkv'
    out_path = '%s.%s' % (base, out_ext)

    on_line('[Merger] Merging formats into "%s"' % out_path)
    try:
        from com.arthenica.ffmpegkit import FFmpegKit, ReturnCode

        args = ['-y', '-i', parts[0], '-i', parts[1], '-c', 'copy']
        if out_ext == 'mp4':
            args += ['-movflags', '+faststart']
        args.append(out_path)
        session = FFmpegKit.executeWithArguments(args)
        if not ReturnCode.isSuccess(session.getReturnCode()):
            on_line('[Merger] Merge failed (exit / logs below):\n%s' % session.getAllLogsAsString())
            return None
    except Exception:
        on_line('[Merger] Merge failed (exception below):\n%s' % traceback.format_exc(limit=3))
        return None

    for p in parts:
        try:
            os.remove(p)
        except OSError:
            on_line('[Merger] Could not delete part file %s' % p)
    return out_path


def run(task_id, argv_json, merge=False):
    """Execute yt-dlp CLI, buffering output for the host to poll.

    The host must call `init(task_id)` before this and `drain(task_id)`
    after it returns (as well as periodically) to receive `(['line', s],)`
    events. Returns a JSON status object:
      {"status": "done"[, "outputs": [...]]} | {"status": "cancelled"} |
      {"status": "error", "message": "..."}
    """
    state = _tasks.get(task_id)
    if state is None:
        with _tasks_lock:
            state = {'pending': [], 'cancel': False, 'files': []}
            _tasks[task_id] = state

    def is_cancelled():
        return state['cancel']

    def on_line(line):
        if state['cancel']:
            raise DownloadCancelled()
        with _tasks_lock:
            state['pending'].append(['line', line])

    def on_destination(path):
        with _tasks_lock:
            if path not in state['files']:
                state['files'].append(path)

    try:
        argv = json.loads(argv_json)
        if not isinstance(argv, list):
            raise ValueError('argv must be a list')
    except Exception:
        return json.dumps({'status': 'error', 'message': 'Invalid engine arguments'})

    try:
        _run(argv, on_line, is_cancelled, on_destination if merge else None)
    except DownloadCancelled:
        return json.dumps({'status': 'cancelled'})
    except SystemExit as exc:
        if exc.code in (0, None):
            pass
        else:
            return json.dumps({'status': 'error', 'message': 'yt-dlp exited with code %s' % exc.code})
    except Exception:
        return json.dumps({'status': 'error', 'message': traceback.format_exc(limit=3)})

    parts = state.get('files') or []
    if merge and len(parts) >= 2:
        merged = _safe_merge(parts, on_line)
        if merged is not None:
            return json.dumps({'status': 'done', 'outputs': [merged]})

    return json.dumps({'status': 'done', 'outputs': parts})
