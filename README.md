# UserspaceEmulator

Currently, a very basic 32bit x86 emulator.

The plan is for this to be used with ZystemOS to emulate applications build for Zystem but running on the wrong architecture. So can run a x86 application on a ARM build of Zystem.

## Build

```sh
zig build
```

## Run

```sh
./zig-cache/bin/UserspaceEmulator
```
