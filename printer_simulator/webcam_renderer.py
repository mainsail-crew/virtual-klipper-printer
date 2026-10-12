import time

from printer_hardware.axis import Axis
from printer_hardware.renderer import PrinterRenderer
from printer_hardware.state_io import STATE_FILE_PATH, read_state

IMAGE_SIZE = (512, 512)
RENDER_INTERVAL = 1.0
OUTPUT_PATH = "/home/printer/mjpg_streamer_images/image0.jpg"


def create_axis_state(axis_key: str, axis_data: dict) -> Axis:
    return Axis(
        name=axis_data.get("name", f"axis-{axis_key}"),
        position=axis_data["position"],
        min_pos=axis_data["min_pos"],
        max_pos=axis_data["max_pos"],
        step_pin=f"{axis_key}_step_pin",
        dir_pin=f"{axis_key}_dir_pin",
        enable_pin=f"{axis_key}_enable_pin",
        endstop_pin=f"{axis_key}_endstop_pin",
        endstop_pos=axis_data["min_pos"],
    )


def load_axes(state_payload: dict) -> tuple[Axis, Axis, Axis] | None:
    axes = state_payload.get("axes", {})
    required_keys = ("x", "y", "z")
    if any(key not in axes for key in required_keys):
        return None
    return (
        create_axis_state("x", axes["x"]),
        create_axis_state("y", axes["y"]),
        create_axis_state("z", axes["z"]),
    )


def load_data(state_file_path: str) -> tuple[Axis, Axis, Axis] | None:
    state_payload = read_state(state_file_path)
    if state_payload is None:
        return None

    return load_axes(state_payload)


if __name__ == "__main__":
    while True:
        loaded_axes = load_data(STATE_FILE_PATH)
        if loaded_axes is not None:
            break
        print(f"Waiting for valid printer state data at {STATE_FILE_PATH}...")
        time.sleep(1.0)

    x_axis, y_axis, z_axis = loaded_axes
    renderer = PrinterRenderer(IMAGE_SIZE[0], IMAGE_SIZE[1], OUTPUT_PATH, x_axis, y_axis, z_axis)
    renderer.render()
    while True:
        loaded_axes = load_data(STATE_FILE_PATH)
        if loaded_axes is None:
            print(f"Waiting for valid printer state data at {STATE_FILE_PATH}...")
            time.sleep(1.0)
            continue
        loaded_x_axis, loaded_y_axis, loaded_z_axis = loaded_axes
        if (
            loaded_x_axis.position != x_axis.position
            or loaded_y_axis.position != y_axis.position
            or loaded_z_axis.position != z_axis.position
        ):
            # only render if there is a change in position to avoid unnecessary rendering
            x_axis.position = loaded_x_axis.position
            y_axis.position = loaded_y_axis.position
            z_axis.position = loaded_z_axis.position

            renderer.render()
        time.sleep(RENDER_INTERVAL)
