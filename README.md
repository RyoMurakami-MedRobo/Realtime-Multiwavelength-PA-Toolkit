# AblationControl Public Minimal Skeleton

This directory is a public-safe minimal repository draft for a real-time ablation experiment workflow.

The repository direction is general-purpose real-time workflow tooling.
As an initial example, the first reference path is described around an OPOTEK-laser and Verasonics-host setup.

It mirrors the current lab architecture with three systems:
1. Arduino trigger monitor
2. Verasonics host script
3. TCP receiver + two MATLAB instances (server and client)

The purpose is to show required implementation elements and interfaces. The public draft runs in offline demo mode by default, and can be expanded with local hardware and a licensed Verasonics SDK.

## Scope

Included:
- Minimal MATLAB and Arduino scaffolds for end-to-end data flow
- Configuration templates for network, serial, and DAT memory-mapped backend settings
- Public attribution and licensing package
- Tiny mock dataset for non-hardware dry-run documentation

Not included:
- Verasonics SDK redistribution
- Probe-specific production parameter sets
- Fully validated hardware timing and safety guarantees

## Repository Layout

```text
AblationControl_public/
  arduino/trigger_monitor_minimal/
  verasonics/
  server/
  client/
  shared_memory/
  config/
  sample_data/
  docs/
  notices/
  LICENSE
  CREDITS.md
```

## Quick Start (Structure Verification)

1. Edit configuration templates in `config/`.
2. Start MATLAB server script first:
   - `server/run_tcp_server.m`
   - This creates the temporary backend file under the system temp folder.
3. Start MATLAB client script in another MATLAB instance:
   - `client/run_processing_client.m`
   - The client drains all currently available packages and exits after a short idle grace period.
4. Prepare Verasonics-side adaptation:
   - `verasonics/run_verasonics_host_template.m`
5. Upload Arduino sketch:
   - `arduino/trigger_monitor_minimal/trigger_monitor_minimal.ino`

Default behavior in this draft:
- Arduino communication is disabled until `cfg.hardware.enable_arduino` is set to `true`.
- The Verasonics template falls back to offline demo mode if no TCP server is available.
- Shared state is stored in a temporary DAT file named `shared_image_data_public.dat`.

## Interface Contract (Minimal)

- Verasonics host sends frame packets to TCP server:
  - Payload: int16 RF image (`image_width x image_height`) + metadata
  - Metadata: `success_count`, timestamp, sequence counters
- Verasonics host also talks to Arduino over serial:
   - `RESET` initializes the counter state
   - `R` returns the latest `success_count`
   - The returned counter is included in the TCP packet metadata
- Server aggregates into package tensor and writes to the DAT shared-memory file.
- Client polls the same DAT file, drains available packages, and marks them as processed.
- Arduino responds to serial commands:
  - `R` -> returns current success count
  - `RESET` -> resets internal counters

## Current Release Decisions

- Energy compensation is intentionally disabled in this public draft.
- Verasonics probe-specific values are masked with TODO placeholders.
- Network and hardware values are template-driven; no fixed local IP/COM is required.
- Arduino is off by default so the public demo can run without hardware.
- Shared-memory handoff uses a fixed-size memmapfile DAT layout, not a MAT file.
- The client exits after the queue stays empty for a short grace period, so the public demo does not run forever.

## Important Disclaimer

- Performance optimization for high-throughput real-time operation is not fully implemented in this sample code.
- Correct execution in every environment is not guaranteed.
- This repository is a public minimal reference and should be validated by users on their own hardware and software stack.

## Credits and Legal

- Authors: Ryo Murakami, Yichuan Tang, Shun Katayose, Haichong Kai Zhang
- Institution: Medical FUSION Laboratory, Worcester Polytechnic Institute
- License: MIT (see `LICENSE`)
- Verasonics notice: see `notices/NOTICE.md`

## Citation

If you use this repository structure or adapt this workflow in your research, please cite the associated archive paper.

Note:
- The current archive paper is focused on an OPOTEK + Verasonics-specific implementation.
- This repository is intentionally organized to remain broader than that single hardware combination.

- Citation guidance and template: [docs/CITATION.md](docs/CITATION.md)

This repository intentionally keeps citation metadata in one place so it can be updated when archive information changes.

## Vision

This repository is planned to evolve from a minimal reference into a broader open-source real-time ultrasound and photoacoustic utility repository:

- support for multiple probe configurations
- reusable real-time pipeline utilities beyond a single device setup
- broader laser-device interoperability over time, beyond the initial OPOTEK-focused reference path

## Start Here

If you want the smallest possible overview first, read [docs/MINIMAL_IDEA.md](docs/MINIMAL_IDEA.md).

## Next Implementation Steps

1. Replace TODO sections in Verasonics template with your licensed SDK setup.
2. Set `cfg.hardware.enable_arduino = true` and fill in the COM port when running with hardware.
3. Replace placeholder processing function in client with your beamforming and decomposition pipeline.
4. Add hardware validation tests (serial timing, network latency, synchronization).
