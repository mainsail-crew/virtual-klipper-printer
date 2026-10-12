# gcc -shared -fPIC -o hardware_bridge_hook.so hardware_bridge_hook.c -ldl

# This Makefile is used to build the hardware_bridge_hook shared library, which simulates the hardware interface for testing purposes.
CC = gcc
CFLAGS = -shared -fPIC -Wall -Wextra
LDFLAGS = -ldl
TARGET = hardware_bridge_hook.so
SRCS = hardware_bridge_hook.c

.PHONY: all clean lint format typecheck

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)

lint:
	ruff check --config pyproject.toml .

format:
	ruff format --config pyproject.toml .

typecheck:
	mypy --config-file pyproject.toml .
