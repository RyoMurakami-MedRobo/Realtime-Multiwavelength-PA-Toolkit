# Implementation Notes (Public Minimal)

## What is intentionally stubbed

- Verasonics resource/transducer setup
- Real TCP receive loop implementation on server
- Production beamforming/decomposition/ablation detection pipeline
- Hardware-level safety checks

## Why this is still useful

This skeleton preserves key software boundaries and function contracts used in the lab setup:
- serial trigger interface
- frame metadata propagation
- package handoff between MATLAB instances
- processed/unprocessed lifecycle handling
- offline demo mode by default
- DAT memory-mapped backend stored under the system temp folder
- client drains until the queue is empty, then exits after a short idle grace period

## Suggested replacement points

1. Replace `verasonics/run_verasonics_host_template.m` TODO block with your licensed sequence setup.
2. Replace server TODO branch with packet parser and package builder.
3. Replace `process_package_stub` in client with your algorithm chain.
4. Replace the fixed-size DAT backend with a richer protocol if required.

## Security and Privacy

- No fixed private IPs are included.
- No fixed local absolute paths are included.
- No experiment logs/results are bundled.
- Arduino is disabled by default until a user enables it in the config.
