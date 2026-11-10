"""Talos download engine entry points for the embedded Python runtime.

This module runs inside the Android app. It executes yt-dlp in-process and
buffers raw CLI lines per task. The host polls `drain(task_id)` to fetch
pending events and decides on cancellation through `cancel(task_id)`, so
no Java object is ever used from Python. The Dart side parses the lines
with the same parser used on desktop.
"""

import io
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


def init(task_id):
    """Create the event buffer for a task, honoring a pending cancel."""
    with _tasks_lock:
        cancel = task_id in _cancel_requested
        _cancel_requested.discard(task_id)
        _tasks[task_id] = {'pending': [], 'cancel': cancel}
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
    def __init__(self, on_line, is_cancelled):
        super().__init__()
        self._on_line = on_line
        self._is_cancelled = is_cancelled
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
        self._on_line(line)


def _run(argv, on_line, is_cancelled):
    import yt_dlp

    writer = _LineWriter(on_line, is_cancelled)
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


def run(task_id, argv_json):
    """Execute yt-dlp CLI, buffering output for the host to poll.

    The host must call `init(task_id)` before this and `drain(task_id)`
    after it returns (as well as periodically) to receive `(['line', s],)`
    events. Returns a JSON status object:
      {"status": "done"} | {"status": "cancelled"} |
      {"status": "error", "message": "..."}
    """
    state = _tasks.get(task_id)
    if state is None:
        with _tasks_lock:
            state = {'pending': [], 'cancel': False}
            _tasks[task_id] = state

    def is_cancelled():
        return state['cancel']

    def on_line(line):
        if state['cancel']:
            raise DownloadCancelled()
        with _tasks_lock:
            state['pending'].append(['line', line])

    try:
        argv = json.loads(argv_json)
        if not isinstance(argv, list):
            raise ValueError('argv must be a list')
    except Exception:
        return json.dumps({'status': 'error', 'message': 'Invalid engine arguments'})

    try:
        _run(argv, on_line, is_cancelled)
        return json.dumps({'status': 'done'})
    except DownloadCancelled:
        return json.dumps({'status': 'cancelled'})
    except SystemExit as exc:
        if exc.code in (0, None):
            return json.dumps({'status': 'done'})
        return json.dumps({'status': 'error', 'message': 'yt-dlp exited with code %s' % exc.code})
    except Exception:
        return json.dumps({'status': 'error', 'message': traceback.format_exc(limit=3)})
