# Neighborhood weather

[Actual game preview](forecast-preview.png)

Click the weather icon/temperature at the upper right of the main garden screen. It opens today's conditions and the next five days (tomorrow through day five). Each forecast row shows weekday/date, condition, high/low temperatures and rain chance. Today's details also show wind speed. The module can switch between Fahrenheit and Celsius. Escape or Return to garden closes it and restores camera input.

This is **simulated garden weather**, not a real-world forecast or location service. It needs no API key or network access. Every garden in a neighborhood reads the same provider.

`weather_system.gd` generates each day deterministically from the exported neighborhood seed, UTC day index and a versioned generator identifier. Temperate seasonal baselines determine high/low temperatures. Today's temperature follows a daily curve between those values; the HUD refreshes hourly. The same daily generation drives the forecast and later current conditions, so reopening the module does not reroll weather and tomorrow's forecast matches tomorrow's generated weather.

The default garden clock follows UTC system time. Future authoritative game-time integration can call `set_simulation_time(unix_seconds)`; all HUD/module subscribers refresh through `weather_changed`. A different persisted neighborhood can supply its own stable `neighborhood_seed` and display name. Weather does not yet change plant growth, water soil, spawn rain particles or override the existing day/night lighting.

Files:

- `weather_system.gd`: shared neighborhood provider and deterministic generation.
- `weather_panel.gd` / `screen.tscn`: current weather and forecast module.
- `main.tscn`: GardenWeather node; `ui/game_hud.gd` subscribes the weather display and passes the provider to the module.
- `tests/verify_weather.gd`: forecast consistency, year/date rollover, temperature conversion, main-screen updates, shared UI state and dismissal.

Run from the project directory:

```
godot --headless --script res://tests/verify_weather.gd
godot --headless --script res://ui/verify_hud.gd
```

Preview the main scene with F6, or use F5 and continue through the welcome-flow preview. The module uses the existing detailed weather illustration as its category icon; text identifies the actual generated condition. Validation was performed with Godot 4.6.3, including a capture of the running forecast module.
