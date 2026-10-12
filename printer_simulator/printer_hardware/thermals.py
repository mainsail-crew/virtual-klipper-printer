import time


def calc_adc_value(temperature_c: float) -> int:
    """
    Converts a temperature in Celsius to a corresponding ADC value for a 12-bit ADC (0-4095) and a 3.3V reference.
    According to this sample config for a heater

    [adc_temperature heater_bed_adc]
    temperature1: 0
    voltage1: 0
    temperature2: 500
    voltage2: 3.3

    [heater_bed]
    heater_pin: ...
    sensor_pin: ...
    sensor_type: heater_bed_adc
    adc_voltage: 3.3
    """
    adc_max = 4095
    voltage = (temperature_c / 500) * 3.3
    adc_value = int((voltage / 3.3) * adc_max)
    return max(0, min(adc_max, adc_value))


class ThermalMass:
    """
    Simplified model of a thermal mass for simulating heatbed and extruder temperatures.
    Simulates a water-based thermal mass.

    Heat input:    dT = (P * dt) / (m * c)
    Cooling:       Newton's law of cooling
                    dT = -k * (T - T_ambient) * dt
    """

    SPECIFIC_HEAT_WATER = 4182  # J / (kg * K)

    def __init__(
        self,
        mass_kg: float,
        heating_power_watts: float,
        ambient_temp: float = 20.0,
        cooling_coefficient: float = 0.01,  # k, higher = faster cooling
        initial_temp: float = 20.0,
    ):
        self._mass_kg = mass_kg
        self._ambient_temp = ambient_temp
        self._cooling_coefficient = cooling_coefficient
        self._temperature = initial_temp
        self._heating_power_watts = heating_power_watts
        self._is_active = False
        self._time = time.monotonic()

    def __update_temperature(self) -> None:
        current_time = time.monotonic()
        dt = current_time - self._time
        self._time = current_time
        heat_capacity = self._mass_kg * self.SPECIFIC_HEAT_WATER

        # Heat input from heater
        if self._is_active:
            self._temperature += (self._heating_power_watts * dt) / heat_capacity

        # Cooling according to Newton's law of cooling
        self._temperature -= (
            self._cooling_coefficient * (self._temperature - self._ambient_temp) * dt
        )

    def set_heater(self, on: bool) -> None:
        self._is_active = on
        self.__update_temperature()

    def get(self) -> float:
        self.__update_temperature()
        return self._temperature
