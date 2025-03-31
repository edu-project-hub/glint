## Glint

### What to do when not working?
- App crashes on resize?
  - Are you calling `app.window_update` in the resize event?
    - If yes, did you run `gdb`?
      - Still no fix? Contact me.