# PINOUT Documentation

Documentation of pins and their usage in the virtual Klipper printer.

## Pin Naming

Klipper config uses pins like `gpiochipN/gpioM` and `analogX`.
The hardware bridge sends GPIO keys to the simulator as:

- `gpiochip1/gpio0` -> `chip1_gpio0`
- `gpiochip6/gpio3` -> `chip6_gpio3`
- `analog0` stays `analog0`

## Active Default Pin Map

This table reflects the default includes in [example-configs/printer.cfg](./example-configs/printer.cfg):

- `addons/basic_cartesian_kinematics.cfg`
- `addons/single_extruder.cfg`
- `addons/heater_bed.cfg`
- `addons/miscellaneous.cfg`

| Klipper section | Config pin | Runtime key | Simulator component |
|---|---|---|---|
| `stepper_x` | `step_pin: gpiochip1/gpio0` | `chip1_gpio0` | `Axis(name="axis-x").step_pin` |
| `stepper_x` | `dir_pin: gpiochip1/gpio1` | `chip1_gpio1` | `Axis(name="axis-x").dir_pin` |
| `stepper_x` | `enable_pin: gpiochip1/gpio2` | `chip1_gpio2` | `Axis(name="axis-x").enable_pin` |
| `stepper_x` | `endstop_pin: ^gpiochip1/gpio3` | `chip1_gpio3` | `Axis(name="axis-x").endstop_pin` |
| `stepper_y` | `step_pin: gpiochip2/gpio0` | `chip2_gpio0` | `Axis(name="axis-y").step_pin` |
| `stepper_y` | `dir_pin: gpiochip2/gpio1` | `chip2_gpio1` | `Axis(name="axis-y").dir_pin` |
| `stepper_y` | `enable_pin: gpiochip2/gpio2` | `chip2_gpio2` | `Axis(name="axis-y").enable_pin` |
| `stepper_y` | `endstop_pin: ^gpiochip2/gpio3` | `chip2_gpio3` | `Axis(name="axis-y").endstop_pin` |
| `stepper_z` | `step_pin: gpiochip3/gpio0` | `chip3_gpio0` | `Axis(name="axis-z").step_pin` |
| `stepper_z` | `dir_pin: gpiochip3/gpio1` | `chip3_gpio1` | `Axis(name="axis-z").dir_pin` |
| `stepper_z` | `enable_pin: gpiochip3/gpio2` | `chip3_gpio2` | `Axis(name="axis-z").enable_pin` |
| `stepper_z` | `endstop_pin: ^gpiochip3/gpio3` | `chip3_gpio3` | `Axis(name="axis-z").endstop_pin` |
| `extruder` | `step_pin: gpiochip4/gpio0` | `chip4_gpio0` | `Extruder(name="extruder").step_pin` |
| `extruder` | `dir_pin: gpiochip4/gpio1` | `chip4_gpio1` | `Extruder(name="extruder").dir_pin` |
| `extruder` | `enable_pin: gpiochip4/gpio2` | `chip4_gpio2` | `Extruder(name="extruder").enable_pin` |
| `extruder` | `heater_pin: gpiochip4/gpio3` | `chip4_gpio3` | `Extruder(name="extruder").heater_pin` |
| `extruder` | `sensor_pin: analog1` | `analog1` | `Extruder(name="extruder").sensor_pin` |
| `heater_bed` | `heater_pin: gpiochip0/gpio0` | `chip0_gpio0` | `Heatbed(name="heatbed").heater_pin` |
| `heater_bed` | `sensor_pin: analog0` | `analog0` | `Heatbed(name="heatbed").sensor_pin` |
| `fan` | `pin: gpiochip6/gpio0` | `chip6_gpio0` | `OutputPin(name="fan").pin` |
| `heater_fan` | `pin: gpiochip6/gpio1` | `chip6_gpio1` | `OutputPin(name="heater_fan").pin` |
| `controller_fan` | `pin: gpiochip6/gpio2` | `chip6_gpio2` | `OutputPin(name="controller_fan").pin` |
| `filament_motion_sensor runout_sensor` | `switch_pin: gpiochip6/gpio3` | `chip6_gpio3` | `InputPin(name="filament_sensor").pin` |
| `output_pin output_pin` | `pin: gpiochip6/gpio4` | `chip6_gpio4` | `OutputPin(name="output_pin").pin` |

Reference implementation: [printer_simulator.py](./printer_simulator/printer_simulator.py)

## Optional Example Config Pins

The following pins appear in optional addon configs but are not instantiated by default in `printer_simulator.py`:

- `gpiochip0/gpio1` (`chip0_gpio1`) - `neopixel`
- `gpiochip0/gpio2` (`chip0_gpio2`) - `led.red_pin`
- `gpiochip0/gpio3` (`chip0_gpio3`) - `led.green_pin`
- `gpiochip0/gpio4` (`chip0_gpio4`) - `led.blue_pin`
- `gpiochip0/gpio5` (`chip0_gpio5`) - `temperature_sensor endstop.sensor_pin`
- `gpiochip0/gpio6` (`chip0_gpio6`) - `temperature_fan chamber_heater.pin`
- `gpiochip0/gpio7` (`chip0_gpio7`) - `temperature_fan chamber_heater.tachometer_pin`
- `analog2` - second extruder sensor in `dual_extruder.cfg`
- `analog3` - chamber heater sensor in `temp_sensors.cfg`
- `gpiochip4/gpio4..6` (`chip4_gpio4..6`) - extra extruder stepper pins in `dual_extruder_stepper.cfg`
- `gpiochip5/gpio0..7` (`chip5_gpio0..7`) - dual extruder pins in `dual_extruder.cfg`

## Notes

- Prefixes like `^` and `!` in Klipper config affect pullups/inversion on Klipper side, but the simulator key itself is still based on the raw pin identity.
- The state dump (`printer_state.json`) is produced by `FakeHardwareServer` from all registered pin handlers.
