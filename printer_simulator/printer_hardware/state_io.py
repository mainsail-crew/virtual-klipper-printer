import json
import os
import tempfile
import time
from typing import Any, cast

from .axis import Axis
from .pin_handler import PinHandler

STATE_FILE_PATH = "/home/printer/printer_data/printer_state.json"


def _axis_key(axis_name: str) -> str:
    if axis_name.startswith("axis-") and len(axis_name) > len("axis-"):
        return axis_name[len("axis-") :]
    return axis_name


def build_printer_state(hardware_components: list[PinHandler]) -> dict[str, Any]:
    component_states: dict[str, Any] = {}
    axis_states: dict[str, Any] = {}

    for component in hardware_components:
        component_name = component.get_name()
        component_states[component_name] = component.state()
        if isinstance(component, Axis):
            axis_states[_axis_key(component.name)] = {
                "name": component.name,
                "position": component.position,
                "min_pos": component.min_pos,
                "max_pos": component.max_pos,
            }

    return {
        "timestamp": time.time(),
        "axes": axis_states,
        "components": component_states,
    }


def atomic_write_json(path: str, payload: dict[str, Any]) -> None:
    parent_dir = os.path.dirname(path) or "."
    os.makedirs(parent_dir, exist_ok=True)
    fd, temp_path = tempfile.mkstemp(prefix=".printer_state_", suffix=".json", dir=parent_dir)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as temp_file:
            json.dump(payload, temp_file, separators=(",", ":"))
        os.replace(temp_path, path)
    finally:
        if os.path.exists(temp_path):
            os.unlink(temp_path)


def read_state(path: str) -> dict[str, Any] | None:
    try:
        with open(path, encoding="utf-8") as state_file:
            return cast(dict[str, Any], json.load(state_file))
    except FileNotFoundError:
        return None
    except json.JSONDecodeError:
        return None
