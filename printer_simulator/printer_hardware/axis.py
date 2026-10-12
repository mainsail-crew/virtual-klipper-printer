from .pin_handler import PinHandler


class Axis(PinHandler):
    """
    Simulates a single axis with stepper motor and endstop.
    Position is updated based on step and direction signals,
    and endstop state is determined by position.
    Sample Config:

    [stepper_x]
    step_pin: gpiochip1/gpio0
    dir_pin: gpiochip1/gpio1
    enable_pin: gpiochip1/gpio2
    endstop_pin: ^gpiochip1/gpio3

    microsteps: 1
    rotation_distance: 40
    position_endstop: 0
    position_max: 300
    position_min: -15

    Don't use any invertions for pins
    """

    def __init__(
        self,
        name: str,
        position: float,
        min_pos: float,
        max_pos: float,
        step_pin: str,
        dir_pin: str,
        enable_pin: str,
        endstop_pin: str,
        endstop_pos: float,
        distance_mm_per_rotation: float = 40,
        full_steps_per_rotation: int = 200,
    ):
        self.name = name
        self.position = position
        self.min_pos = min_pos
        self.max_pos = max_pos
        self.step_pin = step_pin
        self.dir_pin = dir_pin
        self.endstop_pin = endstop_pin
        self.endstop_pos = endstop_pos
        self.enable_pin = enable_pin
        self.direction = 0
        self.enabled = True
        self.distance_mm_per_rotation = distance_mm_per_rotation
        self.full_steps_per_rotation = full_steps_per_rotation

    def update_position(self, value: float) -> None:
        self.position = value

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return [self.endstop_pin]

    @property
    def write_pins(self) -> list[str]:
        return [self.step_pin, self.dir_pin, self.enable_pin]

    def set(self, key: str, value: int) -> None:
        if key == self.enable_pin:
            self.enabled = bool(value)
        elif key == self.step_pin:
            if self.enabled and value == 1:
                direction_multiplier = 1 if self.direction else -1
                step_size = self.distance_mm_per_rotation / self.full_steps_per_rotation
                new_position = self.position + direction_multiplier * step_size
                self.update_position(max(self.min_pos, min(self.max_pos, new_position)))
        elif key == self.dir_pin:
            self.direction = value
        else:
            print(f"[{self.name}] unknown pin: {key}")

    def get(self, key: str) -> int:
        if key == self.endstop_pin:
            return 1 if self.position <= self.endstop_pos else 0
        print(f"[{self.name}] unknown pin: {key}")
        return 0

    def state(self) -> dict[str, float | int | bool | str]:
        return {
            "type": "axis",
            "position": self.position,
            "min_pos": self.min_pos,
            "max_pos": self.max_pos,
            "endstop_pos": self.endstop_pos,
            "direction": self.direction,
            "enabled": self.enabled,
        }
