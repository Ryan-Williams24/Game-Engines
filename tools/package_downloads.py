"""Package the current Meadow Hop project for the GitHub Pages download."""

from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def main():
    root = Path(__file__).resolve().parents[1]
    project = root / "GodotProjects" / "MeadowHop"
    destination = project.parent / "MeadowHop.zip"
    files = [project / "project.godot", project / "README.md"]

    for folder in ("scenes", "scripts", "tests"):
        files.extend(
            path for path in (project / folder).rglob("*")
            if path.is_file() and path.suffix in (".tscn", ".gd", ".uid")
        )

    for path in files:
        if not path.is_file():
            raise FileNotFoundError(path)

    with ZipFile(destination, "w", ZIP_DEFLATED) as archive:
        for path in sorted(files):
            archive.write(path, path.relative_to(project.parent))

    print(f"Created {destination.relative_to(root)} ({len(files)} files)")


if __name__ == "__main__":
    main()
