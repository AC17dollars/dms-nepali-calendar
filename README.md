# Nepali Calendar Widget for DankMaterialShell

A DankMaterialShell widget to display the current Nepali date (Bikram Sambat) with a
click-to-open monthly calendar view showing Nepali holidays and events.

## Screenshots
![Horizontal Layout](./assets/horizontal.png)

## Features

- **Bar pill** — shows the current BS date in your configured format (horizontal & vertical bar)
- **Calendar popout** — click the pill to open a monthly calendar view:
  - Navigate months with `‹` / `›` arrows
  - Today's date highlighted in the primary theme colour
  - Sundays and public holidays shown in red
  - Small dot indicator on days that have events
  - Click any date to see its events/holidays in a detail panel
  - "Events this month" list at the bottom with all events
  - Devanagari/English label toggle respects the *Show Devanagari* setting
- **Live holiday data** — fetched automatically from
  [casualsnek/npEventsAPI](https://github.com/casualsnek/npEventsAPI) (no API key needed)

## Installation

### Manual Installation
1. Clone or download this repository.
2. Move or symlink the folder to your DankMaterialShell plugins directory (e.g. `~/.config/DankMaterialShell/plugins/`).
3. Enable the **Nepali Calendar** plugin and then add the widget.


### From Dank Linux Plugins
1. Go to [danklinux.com/plugins](https://danklinux.com/plugins).
2. Search for **Nepali Calendar**.
3. Click **Install**.

### From DMS Settings
1. Open **DMS Settings** -> **Plugins**.
2. Enable **Show 3rd party**.
3. Search for **Nepali Calendar**.
4. Click **Install**.

### Using CLI
```bash
dms plugins install nepaliCalendar
```

## Configuration

You can configure the date format through the plugin settings:

- **Show Devanagari**
  - Enable to display Nepali characters instead of English

- **Format Options**:
  - `2082 Jestha 12` (YYYY Month dd)
  - `2082/02/12` (YYYY/MM/dd)
  - `82-02-12` (YY-MM-dd)
  - `82/02/12` (YY/MM/dd)
  - `2082-02-12` (YYYY-MM-dd)
  - `Jestha 12` (Month dd)

## Credits

Special thanks to [Prastav54/ad-bs-converter](https://github.com/Prastav54/ad-bs-converter) for the main conversion logic used in `nepali-date.js`.

Holiday and event data is sourced from [casualsnek/npEventsAPI](https://github.com/casualsnek/npEventsAPI) (MIT licence).