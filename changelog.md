# Changelog

## 1.0.0 (27-01-2023)

- First stable release!
- Added this changelog.
- Moved todo list to dedicated branch.
- Created more github actions to automate releases and docker build updates.
- Updated Readme with more sections.
- Swapped OpenJDK for Temurin, reducing docker image size by 57.52%!
- Switched default provider to `purpur`.
- Completely reworked the main script:
    - New providers support: `vanilla`, `purpur`, `fabric`.
    - New settings recap on script start
    - Server configuration state gets stored in server_cfg.txt
    - Better error handling.
    - Added "disabled" option to disable Lazymc.
    - A lot more minor stuff and bug fixes.
