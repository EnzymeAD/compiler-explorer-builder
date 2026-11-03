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

print("Called update-versions.py with ", sys.argv)

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

reactant_commit = None
if len(sys.argv) > 6:
    reactant_commit = sys.argv[6]
    if reactant_commit == "None":
        reactant_commit = None

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
            for lib in ["ClangEnzyme", "LLVMEnzyme", "LLDEnzyme"]:
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

            if version >= 20:
                flang_filename = f"FlangEnzyme-{version}.so"
                flang_url = f"https://github.com/EnzymeAD/Enzyme/releases/download/nightly/{flang_filename}"
                flang_tmp = Path("/tmp") / flang_filename
                flang_dest = Path(f"/opt/compiler-explorer/{branch}") / flang_filename
                lld_dest = Path(f"/opt/compiler-explorer/{branch}") / f"LLDEnzyme-{version}.so"

                print(f"Downloading {flang_url} to {flang_tmp}")
                try:
                    urllib.request.urlretrieve(flang_url, flang_tmp)
                    print(f"Moving {flang_tmp} to {flang_dest}")
                    shutil.move(str(flang_tmp), str(flang_dest))
                except Exception as e:
                    print(f"FlangEnzyme download unavailable ({e}); falling back to LLDEnzyme-{version}.so")
                    if lld_dest.exists():
                        shutil.copy2(str(lld_dest), str(flang_dest))

                cfg_filename = f"FlangEnzyme-{version}.cfg"
                cfg_url = f"https://github.com/EnzymeAD/Enzyme/releases/download/nightly/{cfg_filename}"
                cfg_tmp = Path("/tmp") / cfg_filename
                cfg_dest = Path(f"/opt/compiler-explorer/{branch}") / cfg_filename
                try:
                    urllib.request.urlretrieve(cfg_url, cfg_tmp)
                    shutil.move(str(cfg_tmp), str(cfg_dest))
                except Exception:
                    cfg_dest.write_text(
                        f"-fpass-plugin=<CFGDIR>/FlangEnzyme-{version}.so\n"
                        f"-fuse-ld=lld\n"
                        f"-Wl,-mllvm,-load=<CFGDIR>/LLDEnzyme-{version}.so\n"
                        f"-Wl,--load-pass-plugin=<CFGDIR>/LLDEnzyme-{version}.so\n"
                    )

        if ejaxcommit is not None:
            os.makedirs(f"/opt/compiler-explorer/{branch}", exist_ok=True)

            for (filename, target) in [
                ("enzymexlamlir-opt", "enzyme-opttrunk"),
                ("hlo-translate", "hlo-translate"),
            ]:
                url = f"https://github.com/EnzymeAD/Enzyme-JAX/releases/download/nightly/{filename}"
                tmp_path = Path("/tmp") / filename
                dest_path = Path(f"/opt/compiler-explorer/{branch}") / target

                print(f"Downloading {url} to {tmp_path}")
                try:
                    urllib.request.urlretrieve(url, tmp_path)
                    os.chmod(str(tmp_path), 0o755)
                    print(f"Moving {tmp_path} to {dest_path}")
                    shutil.move(str(tmp_path), str(dest_path))
                except Exception as e:
                    print(f"Error handling {filename}: {e}")

        if reactant_commit is not None:
            os.makedirs(f"/opt/compiler-explorer/{branch}", exist_ok=True)

            for (filename, target) in [
                ("reactant-clang", "reactant-clang"),
            ]:
                url = f"https://github.com/EnzymeAD/Reactant/releases/download/nightly/{filename}"
                tmp_path = Path("/tmp") / filename
                dest_path = Path(f"/opt/compiler-explorer/{branch}") / target

                print(f"Downloading {url} to {tmp_path}")
                try:
                    urllib.request.urlretrieve(url, tmp_path)
                    os.chmod(str(tmp_path), 0o755)
                    print(f"Moving {tmp_path} to {dest_path}")
                    shutil.move(str(tmp_path), str(dest_path))
                except Exception as e:
                    print(f"Error handling {filename}: {e}")

    if commit is not None:
        fortran_src_dir = Path("/app/Enzyme/enzyme/Fortran")
        if fortran_src_dir.is_dir():
            fortran_dest_dir = Path(f"/opt/compiler-explorer/{branch}/fortran")
            fortran_dest_dir.mkdir(parents=True, exist_ok=True)
            for f90_name in ["enzyme_function_hooks.f90", "enzyme.f90"]:
                src_f90 = fortran_src_dir / f90_name
                if src_f90.is_file():
                    shutil.copy2(str(src_f90), str(fortran_dest_dir / f90_name))

    flang_compilers = [c for c in compiler_data if c["version"] >= 20]

    context = {
        "compilers": compiler_data,
        "flang_compilers": flang_compilers,
        "julia_versions": julia_versions,
        "trunk_val": trunk_val,
        "enzymejax_commit": ejaxcommit if ejaxcommit is not None else "<unknown>",
        "reactant_commit": reactant_commit if reactant_commit is not None else "<unknown>"
    }


    # Map of internal group keys to their respective property files
    FILES_MAP = []

    if commit is not None or reactant_commit is not None or len(sys.argv) == 4:
        FILES_MAP.append(("cuda",    "cuda.enzyme.properties"))
        FILES_MAP.append(("cpp",     "c++.enzyme.properties"))
        FILES_MAP.append(("c",       "c.enzyme.properties"))
        FILES_MAP.append(("fortran", "fortran.enzyme.properties"))
        FILES_MAP.append(("llvm",    "llvm.enzyme.properties"))
    
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
