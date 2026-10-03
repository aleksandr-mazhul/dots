"""Ctrl+V/Cmd+V that pastes text like kitty does, but hands an image clipboard to the app.

Claude Code attaches a clipboard image when it receives a raw ^V, while kitty's own
paste_from_clipboard only handles text. Bound in kitty.conf as
`map ctrl+v kitten smart_paste.py` (Linux) / macos.conf `map cmd+v kitten smart_paste.py`
(macOS).
"""
import subprocess
import sys
from typing import Any, List

from kittens.tui.handler import result_handler
from kitty.clipboard import get_clipboard_string

# macOS `osascript -e 'clipboard info'` prints one (class-or-descriptor, size) pair per
# representation the clipboard owner advertises, e.g. for a plain-text copy:
#   «class utf8», 22, «class ut16», 46, string, 22, Unicode text, 44
# and for an image (Preview/Finder "Copy" of a PNG):
#   «class PNGf», 69, «class AVIF», 417, «class 8BPS», 3324, GIF picture, 49, ...
# Some formats show up as `«class XXXX»`, others as a human descriptor ("GIF picture",
# "JPEG picture", "TIFF picture"), so match on plain substrings, not the «class » form.
_MACOS_IMAGE_MARKERS = (
    'PNGf', 'TIFF', 'JPEG', 'GIF', '8BPS', 'BMP', 'TPIC', 'jp2', 'AVIF', 'PICT', 'PDF ',
)
_MACOS_TEXT_MARKERS = (
    'utf8', 'ut16', 'utxt', 'string', 'Unicode text',
    'public.utf8-plain-text', 'public.utf16-plain-text',
)


def main(args: List[str]) -> str:
    return ''


def _clipboard_is_image_only_linux() -> bool:
    try:
        out = subprocess.run(['wl-paste', '--list-types'], capture_output=True, text=True, timeout=1).stdout
    except (OSError, subprocess.SubprocessError):
        return False
    types = out.split()
    return any(t.startswith('image/') for t in types) and not any(t.startswith('text/') for t in types)


def _clipboard_is_image_only_macos() -> bool:
    try:
        out = subprocess.run(['osascript', '-e', 'clipboard info'], capture_output=True, text=True, timeout=1).stdout
    except (OSError, subprocess.SubprocessError):
        return False
    has_image = any(marker in out for marker in _MACOS_IMAGE_MARKERS)
    has_text = any(marker in out for marker in _MACOS_TEXT_MARKERS)
    return has_image and not has_text


def clipboard_is_image_only() -> bool:
    if sys.platform == 'darwin':
        return _clipboard_is_image_only_macos()
    return _clipboard_is_image_only_linux()


@result_handler(no_ui=True)
def handle_result(args: List[str], answer: str, target_window_id: int, boss: Any) -> None:
    w = boss.window_id_map.get(target_window_id)
    if w is None:
        return
    if clipboard_is_image_only():
        w.write_to_child(b'\x16')
        return
    if w.send_paste_event():
        return
    text = get_clipboard_string()
    if text:
        w.paste_with_actions(text)
