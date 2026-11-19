# Breather

A Mac menu bar app that makes you take a break. Every 50 minutes it covers every screen with a calm, slowly moving gradient and a dotted ring that counts down a 5-minute break. When the break is over, the screen fades away and the next 50 minutes start.

**[Try the live demo](https://romario333.github.io/breather/)**

[![Break screen](docs/break-screen.png)](https://romario333.github.io/breather/)

There is one kind of break. No short and long breaks, no Pomodoro.

## Using it

- **Esc** or **Postpone 5 min** hides the break and brings it back in 5 minutes.
- **Skip break** starts a new 50-minute work cycle.
- The menu bar icon is a ring. The bright arc, clockwise from the top, is the work left before the next break. The faint arc is the work already done.
- The menu has **Take a Break Now**, **Restart Work Cycle**, **Pause for 1 Hour** and **Pause Until Tomorrow**.
- **Settings** sets the work and break lengths and turns on **Open Breather at login**.
- Time away from the Mac counts as a break if it lasts at least as long as one: lunch, a locked screen or a sleeping Mac start a fresh cycle when you come back.
- A break starts on one of four color themes and fades through the others while it runs: sunset, lavender dusk, deep blue and forest.

## Install

There is no prebuilt download yet, so you build it from source. You need macOS 15 or later, Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
brew install xcodegen
git clone https://github.com/romario333/breather.git
cd breather
make install
```

`make install` puts a release build in `~/Applications` and starts it.

The project signs with my Apple developer team. Put your own team ID in `DEVELOPMENT_TEAM` in `project.yml` before you build.

## Development

```sh
make build      # Debug build into build/
make run        # build and start the debug app
make install    # release build into ~/Applications, then starts it
make test       # timing rules tests
```

Or run `xcodegen generate` and open `Breather.xcodeproj`.

Open at login uses `SMAppService`, so it works best from the copy in `~/Applications`.

The timing rules live in the `BreatherCore` package.

Debug builds take two launch arguments:

- `-BreatherBreakNow YES` starts a break a second after launch.
- `-BreatherSnapshot <folder>` renders the break screen and settings to PNGs, then quits.

The website lives in `docs/` and GitHub Pages serves it from there. `docs/assets/breather.js` is a WebGL port of the break screen's gradient.

## Inspiration

Breather is modeled on [Tadama](https://apps.apple.com/us/app/tadama-workflow-timer/id1415817706?mt=12), a workflow timer for Mac. It keeps Tadama's full-screen break and has only one kind of break.

## License

[MIT](LICENSE)
