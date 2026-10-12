from .pin_handler import PinHandler
from .thermals import ThermalMass, calc_adc_value


class Heatbed(PinHandler):
    """
    Simulates a heatbed with a thermal mass. Temperature is updated based on heater state and cooling over time.
    [adc_temperature heater_bed_adc]
    temperature1: 0
    voltage1: 0
    temperature2: 500
    voltage2: 3.3

    [heater_bed]
    heater_pin: gpiochip0/gpio0
    sensor_pin: analog0
    sensor_type: heater_bed_adc
    adc_voltage: 3.3
    control: watermark
    min_temp: 0
    max_temp: 130

    """

    def __init__(self, name: str, heater_pin: str, sensor_pin: str):
        self.name = name
        self.heater_pin = heater_pin
        self.sensor_pin = sensor_pin
        self.enabled = False
        self.thermal_mass = ThermalMass(mass_kg=0.2, heating_power_watts=500)

    def get_name(self) -> str:
        return self.name

    @property
    def read_pins(self) -> list[str]:
        return [self.sensor_pin]

    @property
    def write_pins(self) -> list[str]:
        return [self.heater_pin]

    def set(self, key: str, value: int) -> None:
        if key == self.heater_pin:
            self.enabled = bool(value)
            self.thermal_mass.set_heater(self.enabled)
        else:
            print(f"[{self.name}] unknown pin: {key}")

    def get(self, key: str) -> int:
        if key == self.sensor_pin:
            return calc_adc_value(self.thermal_mass.get())  # Simulate temperature as ADC value
        print(f"[{self.name}] unknown pin: {key}")
        return 0

    def state(self) -> dict[str, float | bool | str]:
        return {
            "type": "heatbed",
            "enabled": self.enabled,
            "temperature_c": self.thermal_mass.get(),
        }
