"""Talos download engine entry points for the embedded Python runtime.

This module runs inside the Android app. It executes yt-dlp in-process and
forwards raw CLI lines to a Java bridge object provided by the host. The
Dart side parses those lines with the same parser used on desktop.
"""

import io
import sys
import json
import shlex
import traceback


class DownloadCancelled(Exception):
    pass


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


def run(task_id, argv_json, bridge):
    """Execute yt-dlp CLI with the given arguments.

    bridge is a Java object with methods: onLine(String), onDone(),
    onCancelled(), onError(String) and isCancelled() (boolean).
    """

    def on_line(line):
        if bridge.isCancelled():
            raise DownloadCancelled()
        bridge.onLine(line)

    try:
        argv = json.loads(argv_json)
    except Exception:
        bridge.onError('Invalid engine arguments')
        return

    try:
        _run(argv, on_line, bridge.isCancelled)
        bridge.onDone()
    except DownloadCancelled:
        bridge.onCancelled()
    except SystemExit as exc:
        if exc.code in (0, None):
            bridge.onDone()
        else:
            bridge.onError('yt-dlp exited with code %s' % exc.code)
    except Exception:
        bridge.onError(traceback.format_exc(limit=3))
