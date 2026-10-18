# PINOUT Documentation

Documentation of pins and their usage in the virtual Klipper printer.

## Pin Aliases

The addons in `example-configs/addons/` don't use real pin names. They use the aliases
from the `[board_pins]` section of the MCU config included by `printer.cfg`:

- [example-configs/mcu_linux.cfg](./example-configs/mcu_linux.cfg) for `MCU_TYPE=linux` (the default)
- [example-configs/mcu_avr.cfg](./example-configs/mcu_avr.cfg) for `MCU_TYPE=avr` (atmega644p in simulavr)

Klipper does not allow two aliases of the same pin in one config. On AVR some
aliases share a pin, but only between addons that can't be active at the same time.

## Pin Naming (Linux MCU)

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

| Alias | Klipper section / option | Linux pin | Runtime key | Simulator component | AVR pin |
|---|---|---|---|---|---|
| `X_STEP` | `stepper_x` `step_pin` | `gpiochip1/gpio0` | `chip1_gpio0` | `Axis(name="axis-x").step_pin` | `PD7` |
| `X_DIR` | `stepper_x` `dir_pin` | `gpiochip1/gpio1` | `chip1_gpio1` | `Axis(name="axis-x").dir_pin` | `PC5` |
| `X_ENABLE` | `stepper_x` `enable_pin` | `gpiochip1/gpio2` | `chip1_gpio2` | `Axis(name="axis-x").enable_pin` | `PD6` |
| `X_STOP` | `stepper_x` `endstop_pin` | `gpiochip1/gpio3` | `chip1_gpio3` | `Axis(name="axis-x").endstop_pin` | `PC2` |
| `Y_STEP` | `stepper_y` `step_pin` | `gpiochip2/gpio0` | `chip2_gpio0` | `Axis(name="axis-y").step_pin` | `PC6` |
| `Y_DIR` | `stepper_y` `dir_pin` | `gpiochip2/gpio1` | `chip2_gpio1` | `Axis(name="axis-y").dir_pin` | `PC7` |
| `Y_ENABLE` | `stepper_y` `enable_pin` | `gpiochip2/gpio2` | `chip2_gpio2` | `Axis(name="axis-y").enable_pin` | `PA0` |
| `Y_STOP` | `stepper_y` `endstop_pin` | `gpiochip2/gpio3` | `chip2_gpio3` | `Axis(name="axis-y").endstop_pin` | `PC3` |
| `Z_STEP` | `stepper_z` `step_pin` | `gpiochip3/gpio0` | `chip3_gpio0` | `Axis(name="axis-z").step_pin` | `PB3` |
| `Z_DIR` | `stepper_z` `dir_pin` | `gpiochip3/gpio1` | `chip3_gpio1` | `Axis(name="axis-z").dir_pin` | `PB2` |
| `Z_ENABLE` | `stepper_z` `enable_pin` | `gpiochip3/gpio2` | `chip3_gpio2` | `Axis(name="axis-z").enable_pin` | `PA5` |
| `Z_STOP` | `stepper_z` `endstop_pin` | `gpiochip3/gpio3` | `chip3_gpio3` | `Axis(name="axis-z").endstop_pin` | `PC4` |
| `E0_STEP` | `extruder` `step_pin` | `gpiochip4/gpio0` | `chip4_gpio0` | `Extruder(name="extruder").step_pin` | `PB1` |
| `E0_DIR` | `extruder` `dir_pin` | `gpiochip4/gpio1` | `chip4_gpio1` | `Extruder(name="extruder").dir_pin` | `PB0` |
| `E0_ENABLE` | `extruder` `enable_pin` | `gpiochip4/gpio2` | `chip4_gpio2` | `Extruder(name="extruder").enable_pin` | `PA2` |
| `E0_HEATER` | `extruder` `heater_pin` | `gpiochip4/gpio3` | `chip4_gpio3` | `Extruder(name="extruder").heater_pin` | `PD5` |
| `E0_TEMP` | `extruder` `sensor_pin` | `analog1` | `analog1` | `Extruder(name="extruder").sensor_pin` | `PA7` |
| `BED_HEATER` | `heater_bed` `heater_pin` | `gpiochip0/gpio0` | `chip0_gpio0` | `Heatbed(name="heatbed").heater_pin` | `PD4` |
| `BED_TEMP` | `heater_bed` `sensor_pin` | `analog0` | `analog0` | `Heatbed(name="heatbed").sensor_pin` | `PA6` |
| `FAN_PART` | `fan` `pin` | `gpiochip6/gpio0` | `chip6_gpio0` | `OutputPin(name="fan").pin` | `PB4` |
| `FAN_HEATER` | `heater_fan` `pin` | `gpiochip6/gpio1` | `chip6_gpio1` | `OutputPin(name="heater_fan").pin` | `PB5` |
| `FAN_CONTROLLER` | `controller_fan` `pin` | `gpiochip6/gpio2` | `chip6_gpio2` | `OutputPin(name="controller_fan").pin` | `PB6` |
| `FILAMENT_SENSOR` | `filament_motion_sensor runout_sensor` `switch_pin` | `gpiochip6/gpio3` | `chip6_gpio3` | `InputPin(name="filament_sensor").pin` | `PC1` |
| `OUTPUT_PIN` | `output_pin output_pin` `pin` | `gpiochip6/gpio4` | `chip6_gpio4` | `OutputPin(name="output_pin").pin` | `PC0` |

Reference implementation: [printer_simulator.py](./printer_simulator/printer_simulator.py)

## Optional Example Config Pins

The following aliases appear in optional addon configs. On the Linux MCU they are not
instantiated by default in `printer_simulator.py`:

| Alias | Used by | Linux pin | AVR pin |
|---|---|---|---|
| `E1_STEP` | second extruder / extruder stepper (`dual_extruder.cfg`, `dual_extruder_stepper.cfg`) | `gpiochip5/gpio0` | `PD3` |
| `E1_DIR` | second extruder / extruder stepper | `gpiochip5/gpio1` | `PD2` |
| `E1_ENABLE` | second extruder / extruder stepper | `gpiochip5/gpio2` | `PA3` |
| `E1_HEATER` | second extruder heater (`dual_extruder.cfg`) | `gpiochip5/gpio3` | `PB7` |
| `E1_TEMP` | second extruder sensor (`dual_extruder.cfg`) | `analog2` | `PA1` |
| `TEMP_SENSOR` | `temperature_sensor endstop` (`temp_sensors.cfg`) | `analog3` | `PA4` |
| `CHAMBER_FAN` | `temperature_fan chamber_heater` (commented out in `temp_sensors.cfg`) | `gpiochip0/gpio6` | `PD2` |
| `CHAMBER_TEMP` | `temperature_fan chamber_heater` sensor | `analog4` | `PA6` |
| `CHAMBER_TACH` | `temperature_fan chamber_heater` tachometer | `gpiochip0/gpio7` | `PD3` |
| `NEOPIXEL` | `neopixel` (`led_neopixel.cfg`) | `gpiochip0/gpio1` | `PC0` |
| `LED_RED` | `led` red | `gpiochip0/gpio2` | `PB4` |
| `LED_GREEN` | `led` green | `gpiochip0/gpio3` | `PB5` |
| `LED_BLUE` | `led` blue | `gpiochip0/gpio4` | `PB6` |

## Notes

- Prefixes like `^` and `!` in Klipper config affect pullups/inversion on Klipper side, but the simulator key itself is still based on the raw pin identity.
- The state dump (`printer_state.json`) is produced by `FakeHardwareServer` from all registered pin handlers.
