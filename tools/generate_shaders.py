import os
import pathlib
import subprocess
import tempfile

ROOT: pathlib.Path = pathlib.Path(os.getcwd())
if ROOT.name == "tools":
    ROOT = ROOT.parent


SHADERS_DIR = ROOT / "shaders"
GENERATED_SHADERS_DIR = ROOT / "glint/shaders"
SOKOL_SHDC = ROOT / "vendor/sokol-tools-bin/bin/linux/sokol-shdc"


def get_shader_files():
    return SHADERS_DIR.glob("*.glsl")


# Later use "glsl430:hlsl5:metal_macos" for full platform support
BACKEND = "glsl410"


def prepend_to_file(file_path, string_to_add, chunk_size=1024):
    # Create a temporary file
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as temp_file:
        # Write the string to prepend
        temp_file.write(string_to_add)

        # Open the original file and read/write in chunks
        with open(file_path, 'r') as original_file:
            while chunk := original_file.read(chunk_size):
                temp_file.write(chunk)

        # Get the name of the temporary file
        temp_file_path = temp_file.name

    # Replace the original file with the temporary file
    os.replace(temp_file_path, file_path)


def generate_shader(shader: pathlib.Path, backend: str):
    output = GENERATED_SHADERS_DIR / (shader.name + ".odin")
    subprocess.run([SOKOL_SHDC, "--input", shader,
                   "--output", output, "--slang", backend, "-f", "sokol_odin"])
    prepend_to_file(output, "package shaders\nimport sg \"sokol:gfx\"\n")


def main():
    if not GENERATED_SHADERS_DIR.exists():
        GENERATED_SHADERS_DIR.mkdir()

    for shader in get_shader_files():
        generate_shader(shader=shader, backend=BACKEND)


if __name__ == "__main__":
    main()
