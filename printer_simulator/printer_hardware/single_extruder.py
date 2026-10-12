from .pin_handler import PinHandler
from .thermals import ThermalMass, calc_adc_value


class Extruder(PinHandler):
    """
    Simulates a single extruder with a thermal mass. Temperature is updated based on heater state and cooling over time.
    Extrusion and according cooling isn't implemented

    Sample Config:
        [adc_temperature extruder_adc]
    temperature1: 0
    voltage1: 0
    temperature2: 500
    voltage2: 3.3

    [extruder]
    step_pin: gpiochip4/gpio0
    dir_pin: gpiochip4/gpio1
    enable_pin: gpiochip4/gpio2
    heater_pin: gpiochip4/gpio3
    sensor_pin: analog1
    sensor_type: extruder_adc
    adc_voltage: 3.3
    control: watermark
    microsteps: 1

    Don't use any invertions for pins
    """

    def __init__(
        self,
        name: str,
        step_pin: str,
        dir_pin: str,
        enable_pin: str,
        heater_pin: str,
        sensor_pin: str,
    ):
        self.name = name
        self.step_pin = step_pin
        self.dir_pin = dir_pin
        self.enable_pin = enable_pin
        self.heater_pin = heater_pin
        self.sensor_pin = sensor_pin
        self.direction = 0
        self.enabled = True
        self.heater_enabled = False
        self.thermal_mass = ThermalMass(
            mass_kg=0.005, heating_power_watts=100
        )  # Simulate 5g of water as thermal mass for the extruder (this is just a rough estimate for simulation purposes)

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return [self.sensor_pin]

    @property
    def write_pins(self) -> list[str]:
        return [self.step_pin, self.dir_pin, self.enable_pin, self.heater_pin]

    def set(self, key: str, value: int) -> None:
        if key == self.enable_pin:
            self.enabled = bool(value)
        elif key == self.step_pin:
            # simulate extrusion by changing the thermal mass temperature based on steps
            pass
        elif key == self.dir_pin:
            self.direction = value
        elif key == self.heater_pin:
            self.heater_enabled = bool(value)
            self.thermal_mass.set_heater(
                self.heater_enabled
            )  # Turn on/off the heater based on the value of the heater pin
        else:
            print(f"[{self.name}] unknown pin: {key}")

    def get(self, key: str) -> int:
        if key == self.sensor_pin:
            return calc_adc_value(self.thermal_mass.get())
        print(f"[{self.name}] unknown pin: {key}")
        return 0

    def state(self) -> dict[str, float | int | bool | str]:
        return {
            "type": "extruder",
            "enabled": self.enabled,
            "direction": self.direction,
            "heater_enabled": self.heater_enabled,
            "temperature_c": self.thermal_mass.get(),
        }
