**Huge Disclaimer! ⚠️** All credit for the idea behind this app goes to [Ellen Li](https://ellen.li). In almost all ways this is a direct copy of her [Up Next app](https://ellen.li/up-next/). I created this copy because I'm a long time user of her app and wanted to make some tweaks for my specific use-case. Making the tweaks also allowed me to advance my knowledge of Swift.

---

<img src="assets/promo.png" width="500px" />

![Top bar with menu showing that display all meetings for the day](assets/preview.png)

[Download](https://github.com/kvendrik/next-up/releases/download/2.1.0-alpha.1/Next.Up.zip)

## How is this different from [Up Next](https://ellen.li/up-next/)?
- Added multi-calendar support
- Added Open at Login option
- Remembers selected calendars between startups
- Changed when the button text changes to the next event to 1/3 of the event's duration (e.g. if your current event takes 1 hour then the app will show the next event in the button after 20 minutes)
- Left out the "Present via Google Meet" option

## Roadmap
- [ ] Make Command + J hotkey work globally (currently only works when menu is open)
- [ ] Optimize memory consumption
- [ ] Add v1 release

## Contibuting
1. Fork & clone this repository
1. `carthage build` to install dependencies
1. Open `Next Up.xcodeproj` in Xcode
1. Make your changes
1. Open up a PR
