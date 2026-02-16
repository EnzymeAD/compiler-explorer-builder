import os
import re
import shutil
from pathlib import Path

# --- Configuration ---
CLANG_VERSIONS_FILE = "data/clang-versions.txt"
TRUNK_VERSION_FILE = "data/trunk-llvm-version.txt"
SOURCE_CONFIG_DIR = Path("frontend/files/etc/config")
TEMP_DIR = Path("/tmp/ce")
BRANCHES = ["main"]

# Map of internal group keys to their respective property files
FILES_MAP = {
    "cuda": "cuda.enzyme.properties",
    "cpp":  "c++.enzyme.properties",
    "c":    "c.enzyme.properties",
    "llvm": "llvm.enzyme.properties"
}

def set_property(filepath, key, value):
    """Updates or appends a key=value pair in a .properties file."""
    if not filepath.exists():
        print(f"Warning: {filepath} not found. Creating new.")
        filepath.write_text(f"{key}={value}\n")
        return

    lines = filepath.read_text().splitlines()
    found = False
    new_lines = []
    
    # Simple key matching: looks for key= at start of line
    pattern = re.compile(f"^\s*{re.escape(key)}\s*=")

    for line in lines:
        if pattern.match(line):
            new_lines.append(f"{key}={value}")
            found = True
        else:
            new_lines.append(line)

    if not found:
        print(f"APPENDING {key} to {filepath.name}")
        new_lines.append(f"{key}={value}")
    else:
        print(f"SETTING {key} in {filepath.name}")

    filepath.write_text("\n".join(new_lines) + "\n")

def get_compiler_info(raw_name, trunk_val):
    """Extracts version and semver from strings like 'clang-15.0.0' or 'clang-assertions-trunk'."""
    # Matches digits or 'trunk'
    version_match = re.search(r'(\d+|trunk)', raw_name)
    version = version_match.group(1) if version_match else "unknown"
    
    if version == "trunk":
        version = trunk_val
    
    # Remove leading zeros if any
    version = version.lstrip('0')
    semver = raw_name.replace("clang-", "")
    
    return version, semver

def run_update():
    # 1. Setup Directories
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    
    # 2. Read input files
    trunk_val = Path(TRUNK_VERSION_FILE).read_text().strip()
    compilers = Path(CLANG_VERSIONS_FILE).read_text().splitlines()
    compilers = [c.strip() for c in compilers if c.strip()]

    # 3. Copy original files to Temp
    for f in FILES_MAP.values():
        shutil.copy(SOURCE_CONFIG_DIR / f, TEMP_DIR / f)

    for branch in BRANCHES:
        # Paths for this iteration
        p_cuda = TEMP_DIR / FILES_MAP["cuda"]
        p_cpp  = TEMP_DIR / FILES_MAP["cpp"]
        p_c    = TEMP_DIR / FILES_MAP["c"]
        p_llvm = TEMP_DIR / FILES_MAP["llvm"]

        # 4. Generate Dynamic Lists
        compiler_lists = { "cuclang": [], "clang": [], "cclang": [], "irclang": [], "opt": [] }
        
        compiler_data = []
        for c_raw in compilers:
            v, sv = get_compiler_info(c_raw, trunk_val)
            compiler_data.append((c_raw, v, sv))
            
            compiler_lists["cuclang"].append(f"cuclang{v}-enzyme-{branch}")
            compiler_lists["clang"].append(f"clang{v}-enzyme-{branch}")
            compiler_lists["cclang"].append(f"cclang{v}-enzyme-{branch}")
            compiler_lists["irclang"].append(f"irclang{v}-enzyme-{branch}")
            compiler_lists["opt"].append(f"opt{v}-enzyme-{branch}")

        # 5. Apply Group Properties
        set_property(p_cuda, f"group.cuclang-enzyme-{branch}.compilers", ":".join(compiler_lists["cuclang"]))
        set_property(p_cpp,  f"group.clang-enzyme-{branch}.compilers",  ":".join(compiler_lists["clang"]))
        set_property(p_c,    f"group.clang-enzyme-{branch}.compilers",  ":".join(compiler_lists["cclang"]))
        set_property(p_llvm, f"group.clang-enzyme-{branch}.compilers",  ":".join(compiler_lists["irclang"]))
        set_property(p_llvm, f"group.opt-enzyme-{branch}.compilers",    ":".join(compiler_lists["opt"]))

        # Common group settings
        for p in [p_cpp, p_c, p_llvm]:
            set_property(p, f"group.clang-enzyme-{branch}.intelAsm", "-mllvm --x86-asm-syntax=intel")
            set_property(p, f"group.clang-enzyme-{branch}.compilerType", "clang")
            set_property(p, f"group.clang-enzyme-{branch}.supportsExecute", "true")
            set_property(p, f"group.clang-enzyme-{branch}.isSemVer", "true")
            set_property(p, f"group.clang-enzyme-{branch}.groupName", f"CLANG + ENZYME ({branch})")
            set_property(p, f"group.clang-enzyme-{branch}.options", "-fno-discard-value-names")

        # Specific Overrides
        set_property(p_cuda, f"group.cuclang-enzyme-{branch}.compilerType", "clang-cuda")
        set_property(p_cuda, f"group.cuclang-enzyme-{branch}.supportsExecute", "false")
        set_property(p_cuda, "group.cuclang.groupName", f"CUCLANG + ENZYME ({branch})")

        set_property(p_llvm, f"group.opt-enzyme-{branch}.compilerType", "opt")
        set_property(p_llvm, f"group.opt-enzyme-{branch}.supportsExecute", "false")
        set_property(p_llvm, f"group.opt-enzyme-{branch}.isSemVer", "true")
        set_property(p_llvm, f"group.opt-enzyme-{branch}.groupName", f"OPT + ENZYME ({branch})")

        # 6. Apply Individual Compiler Properties
        for c_raw, v, sv in compiler_data:
            # Executables
            set_property(p_cuda, f"compiler.cuclang{v}-enzyme-{branch}.exe", f"/opt/compiler-explorer/{c_raw}/bin/clang++")
            set_property(p_cpp,  f"compiler.clang{v}-enzyme-{branch}.exe",   f"/opt/compiler-explorer/{c_raw}/bin/clang++")
            set_property(p_c,    f"compiler.cclang{v}-enzyme-{branch}.exe",  f"/opt/compiler-explorer/{c_raw}/bin/clang")
            set_property(p_llvm, f"compiler.irclang{v}-enzyme-{branch}.exe", f"/opt/compiler-explorer/{c_raw}/bin/clang")
            set_property(p_llvm, f"compiler.opt{v}-enzyme-{branch}.exe",     f"/opt/compiler-explorer/{c_raw}/bin/opt")

            # Plugins/Options
            plugin_base = f"/opt/compiler-explorer/{branch}"
            set_property(p_cuda, f"compiler.cuclang{v}-enzyme-{branch}.options", f"-fplugin={plugin_base}/ClangEnzyme-{v}.so")
            set_property(p_cpp,  f"compiler.clang{v}-enzyme-{branch}.options",   f"-fplugin={plugin_base}/ClangEnzyme-{v}.so")
            set_property(p_c,    f"compiler.cclang{v}-enzyme-{branch}.options",  f"-fplugin={plugin_base}/ClangEnzyme-{v}.so")
            set_property(p_llvm, f"compiler.irclang{v}-enzyme-{branch}.options", f"-fpass-plugin={plugin_base}/ClangEnzyme-{v}.so")

            # Opt specific logic
            v_int = int(v) if v.isdigit() else 0
            if v_int >= 17:
                opt_opts = f"-load-pass-plugin={plugin_base}/LLVMEnzyme-{v}.so -load={plugin_base}/LLVMEnzyme-{v}.so -passes=enzyme --enzyme-attributor=0"
            elif v_int >= 16:
                opt_opts = f"-load-pass-plugin={plugin_base}/LLVMEnzyme-{v}.so -load={plugin_base}/LLVMEnzyme-{v}.so -passes=enzyme -opaque-pointers=0 --enzyme-attributor=0"
            else:
                opt_opts = f"-load-pass-plugin={plugin_base}/LLVMEnzyme-{v}.so -load={plugin_base}/LLVMEnzyme-{v}.so -enzyme --enzyme-attributor=0"
            
            set_property(p_llvm, f"compiler.opt{v}-enzyme-{branch}.options", opt_opts)

            # Semver
            set_property(p_cpp,  f"compiler.cuclang{v}-enzyme-{branch}.semver", sv)
            set_property(p_cpp,  f"compiler.clang{v}-enzyme-{branch}.semver", sv)
            set_property(p_c,    f"compiler.cclang{v}-enzyme-{branch}.semver", sv)
            set_property(p_llvm, f"compiler.irclang{v}-enzyme-{branch}.semver", sv)
            set_property(p_llvm, f"compiler.opt{v}-enzyme-{branch}.semver", sv)

    # 7. Final Copy Back
    for f in FILES_MAP.values():
        shutil.copy(TEMP_DIR / f, SOURCE_CONFIG_DIR / f)
    print("Successfully updated all configurations.")

if __name__ == "__main__":
    run_update()