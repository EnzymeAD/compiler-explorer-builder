#!/usr/bin/env python3

import os
import re
import shutil
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, ChoiceLoader

import sys
import urllib.request

if len(sys.argv) < 4:
    print("Usage: update-versions.py <data dir> <template dir> <source config dir>")
    sys.exit(1)

# --- Configuration ---
CLANG_VERSIONS_FILE = Path(sys.argv[1]) / "clang-versions.txt"
JULIA_VERSIONS_FILE = Path(sys.argv[1]) / "julia-versions.txt"
TRUNK_VERSION_FILE = Path(sys.argv[1]) / "trunk-llvm-version.txt"
SOURCE_CONFIG_DIR = Path(sys.argv[3])
TEMPLATE_DIR = Path(sys.argv[2])
commit = None
if len(sys.argv) > 4:
    commit = sys.argv[4]
    if commit == "None":
        commit = None

ejaxcommit = None
if len(sys.argv) > 5:
    ejaxcommit = sys.argv[5]
    if ejaxcommit == "None":
        ejaxcommit = None

def get_compiler_info(raw_name, trunk_val):
    """Extracts version and semver from strings like 'clang-15.0.0' or 'clang-assertions-trunk'."""
    # Matches digits or 'trunk'
    version_match = re.search(r'(\d+|trunk)', raw_name)
    major_version = version_match.group(1) if version_match else "unknown"
    
    if major_version == "trunk":
        major_version = trunk_val
    
    # Remove leading zeros if any
    major_version = major_version.lstrip('0')
    semver = raw_name.replace("clang-", "")
    
    return int(major_version), semver

def main():
    # Read input files
    trunk_val = TRUNK_VERSION_FILE.read_text().strip()
    compilers_raw = [c.strip() for c in CLANG_VERSIONS_FILE.read_text().splitlines() if c.strip()]
    julia_versions = [c.strip() for c in JULIA_VERSIONS_FILE.read_text().splitlines() if c.strip()]

    # 3. Generate context for templates
    env = Environment(loader=ChoiceLoader([
        FileSystemLoader(str(TEMPLATE_DIR)),
        FileSystemLoader(sys.argv[1])
    ]))
    
    branch = "main"
    compiler_data = []
    for c_raw in compilers_raw:
        version, semver = get_compiler_info(c_raw, trunk_val)
        compiler_data.append({
            "raw_name": c_raw,
            "version": version,
            "semver": semver,
            "enzyme_commit": commit if commit is not None else "<unknown>",
        })

        if commit is not None:
            os.makedirs(f"/opt/compiler-explorer/{branch}", exist_ok=True)
            for lib in ["ClangEnzyme", "LLVMEnzyme"]:
                filename = f"{lib}-{version}.so"
                url = f"https://github.com/EnzymeAD/Enzyme/releases/download/nightly/{filename}"
                tmp_path = Path("/tmp") / filename
                dest_path = Path(f"/opt/compiler-explorer/{branch}") / filename
                
                print(f"Downloading {url} to {tmp_path}")
                try:
                    urllib.request.urlretrieve(url, tmp_path)
                    print(f"Moving {tmp_path} to {dest_path}")
                    shutil.move(str(tmp_path), str(dest_path))
                except Exception as e:
                    print(f"Error handling {filename}: {e}")

        if ejaxcommit is not None:
            os.makedirs(f"/opt/compiler-explorer/{branch}", exist_ok=True)
            filename = "enzymexlamlir-opt"
            url = f"https://github.com/EnzymeAD/Enzyme-JAX/releases/download/nightly/{filename}"
            tmp_path = Path("/tmp") / filename
            dest_path = Path(f"/opt/compiler-explorer/{branch}") / "enzyme-opttrunk"

            print(f"Downloading {url} to {tmp_path}")
            try:
                urllib.request.urlretrieve(url, tmp_path)
                os.chmod(str(tmp_path), 0o755)
                print(f"Moving {tmp_path} to {dest_path}")
                shutil.move(str(tmp_path), str(dest_path))
            except Exception as e:
                print(f"Error handling {filename}: {e}")

    context = {
        "compilers": compiler_data,
        "julia_versions": julia_versions,
        "trunk_val": trunk_val,
        "enzymejax_commit": ejaxcommit if ejaxcommit is not None else "<unknown>"
    }


    # Map of internal group keys to their respective property files
    FILES_MAP = []

    if commit is not None or len(sys.argv) == 4:
        FILES_MAP.append(("cuda", "cuda.enzyme.properties"))
        FILES_MAP.append(("cpp",  "c++.enzyme.properties"))
        FILES_MAP.append(("c",    "c.enzyme.properties"))
        FILES_MAP.append(("llvm", "llvm.enzyme.properties"))
    
    if ejaxcommit is not None or len(sys.argv) == 4:
        FILES_MAP.append(("mlir", "mlir.enzyme.properties"))
        FILES_MAP.append(("julia", "julia.enzyme.properties"))

    # 4. Render and write properties files
    for f_key, f_name in FILES_MAP:
        template_name = f"{f_name}.j2"
        template = env.get_template(template_name)
        rendered_content = template.render(context)
        
        output_path = SOURCE_CONFIG_DIR / f_name
        output_path.write_text(rendered_content)

    print("Successfully updated all configurations using Jinja2 templates.")

if __name__ == "__main__":
    main()