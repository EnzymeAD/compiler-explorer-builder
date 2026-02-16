#!/usr/bin/env python3

import os
import re
import shutil
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, ChoiceLoader

import sys

if len(sys.argv) < 4:
    print("Usage: update-versions.py <data dir> <template dir> <source config dir>")
    sys.exit(1)

# --- Configuration ---
CLANG_VERSIONS_FILE = Path(sys.argv[1] + "/clang-versions.txt")
TRUNK_VERSION_FILE = Path(sys.argv[1] + "/trunk-llvm-version.txt")
SOURCE_CONFIG_DIR = Path(sys.argv[3])
TEMPLATE_DIR = Path(sys.argv[2])
BRANCHES = ["main"]

# Map of internal group keys to their respective property files
FILES_MAP = {
    "cuda": "cuda.enzyme.properties",
    "cpp":  "c++.enzyme.properties",
    "c":    "c.enzyme.properties",
    "llvm": "llvm.enzyme.properties"
}

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

    # 3. Generate context for templates
    env = Environment(loader=ChoiceLoader([
        FileSystemLoader(str(TEMPLATE_DIR)),
        FileSystemLoader(sys.argv[1])
    ]))
    
    for branch in BRANCHES:
        compiler_data = []
        for c_raw in compilers_raw:
            v, sv = get_compiler_info(c_raw, trunk_val)
            compiler_data.append({
                "raw_name": c_raw,
                "version": v,
                "semver": sv,
                "enzyme_commit": "<unknown>"
            })

        context = {
            "compilers": compiler_data,
            "branches": BRANCHES,
            "trunk_val": trunk_val
        }
        
        # 4. Render and write properties files
        for f_key, f_name in FILES_MAP.items():
            template_name = f"{f_name}.j2"
            template = env.get_template(template_name)
            rendered_content = template.render(context)
            
            output_path = SOURCE_CONFIG_DIR / f_name
            output_path.write_text(rendered_content)

    print("Successfully updated all configurations using Jinja2 templates.")

if __name__ == "__main__":
    main()