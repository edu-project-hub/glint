import os
import pathlib
import subprocess
import tempfile


ROOT = pathlib.Path(os.getcwd())
if ROOT.name == "tools":
    ROOT = ROOT.parent

# Fixes some issues with different command lines
ROOT = ROOT.relative_to(pathlib.Path(os.getcwd()))

SHADERS_DIR = ROOT / "shaders"
GENERATED_SHADERS_DIR = ROOT / "glint/shaders"
SOKOL_SHDC = ROOT / "vendor/sokol-tools-bin/bin/linux/sokol-shdc"


def get_shader_files():
    return SHADERS_DIR.glob("*.glsl")


# Later use "glsl430:hlsl5:metal_macos" for full platform support
BACKEND = "glsl410"


def prepend_to_file(file_path, string_to_add, chunk_size=1024):
    # I had to pass `dir` here else I got the error that cross-device link
    # was not permitted
    with tempfile.NamedTemporaryFile(
        mode="w", dir=os.path.dirname(file_path), delete=False
    ) as temp_file:
        temp_file.write(string_to_add)
        with open(file_path, "r") as original_file:
            while chunk := original_file.read(chunk_size):
                temp_file.write(chunk)
        temp_file_path = temp_file.name
    os.replace(temp_file_path, file_path)


def generate_shader(shader: pathlib.Path, backend: str):
    output = GENERATED_SHADERS_DIR / (shader.name + ".odin")
    subprocess.run(
        [
            str(SOKOL_SHDC),
            "--input",
            str(shader),
            "--output",
            str(output),
            "--slang",
            backend,
            "-f",
            "sokol_odin",
        ],
        check=True,
    )
    prepend_to_file(output, 'package shaders\nimport sg "sokol:gfx"\n')


def main():
    GENERATED_SHADERS_DIR.mkdir(exist_ok=True)
    for shader in get_shader_files():
        generate_shader(shader=shader, backend=BACKEND)


if __name__ == "__main__":
    main()
