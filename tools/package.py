"""Build an installable addon ZIP from the repository root."""
from pathlib import Path
import re
import zipfile
root = Path(__file__).resolve().parents[1]
addon = root / 'DuckMooPlanner'
version = re.search(r'^## Version:\s*(\S+)', (addon / 'DuckMooPlanner.toc').read_text(), re.M).group(1)
output = root / 'dist' / f'DuckMooPlanner-{version}.zip'
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(addon.rglob('*')):
        if path.is_file() and not any(part in ('tests', '__pycache__') for part in path.relative_to(addon).parts):
            archive.write(path, path.relative_to(root))
    archive.write(root / 'LICENSE', 'DuckMooPlanner/LICENSE')
print(output)
