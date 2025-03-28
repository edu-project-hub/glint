import os
import sys
import subprocess
from typing import Tuple


def get_sokol_backend() -> Tuple[str, str]:
    print(
        "No MacOS and Windows support yet. @Robaertschi probably adds MacOS support and @Fabbboy adds Windows support."
    )
    return "SOKOL_GLCORE", "gl"

def get_c_compiler():
    compiler = os.environ.get("CC")
    if compiler:
        return compiler

    return "gcc"

C_COMPILER = get_c_compiler()
BACKEND = get_sokol_backend()

def build_static_lib(build_type, src, dst, backend_macro, root_path):
    sokol_dir = os.path.join(root_path, "vendor", "sokol-odin", "sokol")
    c_dir = os.path.join(sokol_dir, "c")
    src_c_file = os.path.join(c_dir, f"{src}.c")
    dst_a_file = os.path.join(sokol_dir, f"{dst}.a")
    obj_file = os.path.join(sokol_dir, f"{src}.o")
    if not os.path.isfile(src_c_file):
        print(f"Source file not found: {src_c_file}")
        return

    if os.path.exists(dst_a_file):
        print(f"Skipping {dst_a_file} [{build_type}] — already exists.")
        return

    print(f"Building {dst_a_file} [{build_type}]")

    try:
        if build_type == "release":
            compile_cmd = [
                C_COMPILER,
                "-pthread",
                "-c",
                "-O2",
                "-DNDEBUG",
                "-DIMPL",
                f"-D{backend_macro}",
                src_c_file,
                "-o",
                obj_file,
            ]
        elif build_type == "debug":
            compile_cmd = [
                C_COMPILER,
                "-pthread",
                "-c",
                "-g",
                "-DIMPL",
                f"-D{backend_macro}",
                src_c_file,
                "-o",
                obj_file,
            ]
        else:
            raise ValueError("Invalid build type.")

        subprocess.run(compile_cmd, check=True)
        subprocess.run(["ar", "rcs", dst_a_file, obj_file], check=True)

    finally:
        if os.path.exists(obj_file):
            os.remove(obj_file)


def main():
    if len(sys.argv) != 2:
        print(f"Usage: python3 {sys.argv[0]} /absolute/path/to/project_root")
        sys.exit(1)

    root = sys.argv[1]
    if not os.path.isabs(root):
        print("Error: Please provide an absolute path.")
        sys.exit(1)

    modules = [
        ("sokol_gfx", f"gfx/sokol_gfx_linux_x64_{BACKEND[1]}", BACKEND[0]),
        # insert all libs as we need them
    ]

    for src, dst_base, backend in modules:
        build_static_lib("release", src, f"{dst_base}_release", backend, root)
        build_static_lib("debug", src, f"{dst_base}_debug", backend, root)

    print("Static build complete. No shared libs. No survivors.")


if __name__ == "__main__":
    main()
