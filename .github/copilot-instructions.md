# KnoxRPG Digital Terrain App

This repository contains the code for the KnoxRPG Digital Terrain App, a web application designed to help tabletop RPG players create and manage their game maps. It is built using NodeJS, Express, and React and must follow best practices.

## LLM/AI Instructions
- AI/CoPilot MUST only generate code that is relevant to the requirements outlined in this document.
- AI/CoPilot MUST follow the directions under .github/copilot-instructions.md when generating code.
- AI/CoPilot MUST not make assumptions about the requirements or implementation details that are not explicitly stated in this document. If there is ambiguity or missing information, AI/CoPilot MUST ask for clarification before generating code.
- AI/CoPilot MUST not use LLM/AI sounding phases and emojis in Code/Comments or Docmemtation.
- AI/CoPilot MUST NOT run, restart, deploy, or otherwise alter the Raspberry Pi runtime, services, or browser display unless the user explicitly asks for that step.
- AI/CoPilot MUST NOT make code changes on remote systems. All fixes must be made in the repository first; any remote runtime action must be explicitly approved by the user.
- AI/CoPilot MUST update the repository changelog and semantic version information whenever code changes are made.
- Semantic version bumps must follow the usual convention: patch for bug fixes, minor for new features, major for breaking changes.
- Any code change that affects behavior or deployment must be documented in CHANGELOG.md before the task is considered complete.
- If runtime verification is needed on the Pi, AI/CoPilot must ask for explicit approval before any command that starts, stops, restarts, deploys, or modifies Pi services or files.

## Hardware Requirements
- The Application will run on a Raspberry Pi with at least 2GB of RAM.
- The OS will be RaspbianOS
- Monitors will be connected to the Raspberry Pi via HDMI and will be used to display the maps created and managed through the Admin Interface. The monitors will come in various sizes. 

## ApplicationRequirements
- The Application will display a digital map on main screen. It will display in Full Screen mode with no UI elements.
- The Applications primary Admin Interface will be be web based and will allow users to create and manage maps. 
- The supported file types for maps are [Image] JPEG and PNG and for [VIDEO] MP4 and WEBM.
- The Admin interface supports the following features:
  - Control Zoom in and out of the map on the main screen
  - Upload a map image or video file to local storage on the Raspberry Pi [SD Card]
  - Delete map
  - Set the map's name and description
  - Set Map as Active so it can be displayed on the main screen
  - View a list of all maps with their name, description, and file type
  - For Video maps, the Admin interface should allow users to play, pause, and loop/repeat the video on the main screen.

## Code Style
- Use ES6+ syntax and features where appropriate.
- Must use latest stable versions of NodeJS, Express, and React.
- follow best practices for file structure, naming conventions, and code organization.
- Use meaningful variable and function names that clearly indicate their purpose.

## Raspberry Pi Setup
- Use `scripts/setup.sh` for first-time provisioning of a Pi: installs Node.js, Chromium, npm dependencies, builds the React client, installs the HDMI CEC ignore udev rule (kills the kiosk-display mouse cursor), and creates the two systemd services (`knoxrpg-digital-terrain`, `knoxrpg-digital-terrain-display`). Run with `sudo bash scripts/setup.sh`, then `sudo reboot`.
- Use `scripts/restart.sh` after each `git pull` to refresh npm dependencies, rebuild the client, self-heal OS-level config, and restart both services. Run with `sudo bash scripts/restart.sh`.
- `scripts/start_display.sh` is invoked by the display systemd unit; do not run it manually.