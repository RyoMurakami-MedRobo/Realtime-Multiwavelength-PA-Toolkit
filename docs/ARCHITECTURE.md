# Architecture

## Runtime Components

1. Verasonics host script
- Acquires RF frame data
- Opens Arduino serial connection
- Sends `RESET` at startup
- Queries Arduino with `R` for the current success counter
- Sends frame packet to TCP server
- Runs in offline demo mode if the TCP server is unavailable

2. TCP server MATLAB instance
- Receives packets
- Aggregates frames into package tensor
- Writes package to a fixed-size DAT memory-mapped file in the system temp folder

3. Processing client MATLAB instance
- Polls the shared DAT file
- Runs ablation-processing pipeline (stub in this release)
- Marks package as processed
- Reads the same DAT backend created by the server
- Drains all available packages, then exits after a short idle grace period in the public demo

4. Arduino microcontroller
- Monitors trigger timing
- Exposes success counter over serial

## Launch Order

1. Start MATLAB server script
2. Start MATLAB client script in a second MATLAB instance
3. Start Verasonics host workflow
4. Optionally upload and enable the Arduino sketch when hardware is available

## Data Contract (Minimal Example)

Header int32 values:
- image_height
- image_width
- success_count
- frame_index

Body:
- int16 RF image flattened in column-major order

## DAT File Layout

The shared-memory file is a fixed-size `memmapfile` layout with:

- one global header containing package counters and layout metadata
- one fixed-size slot per package
- one ready/processed flag per slot
- one raw int16 payload per slot

This keeps the public sample simple while still showing a fast file-backed handoff between MATLAB instances.

## Arduino Serial Protocol

Commands sent from Verasonics host:
- `RESET`: clear Arduino counters before acquisition starts
- `R`: request the latest success counter value

Responses from Arduino:
- integer count for `R`
- `RESET_OK` for `RESET`

## Notes

- This public release keeps energy compensation disabled.
- Verasonics probe setup is intentionally omitted and must be filled by licensed users.
