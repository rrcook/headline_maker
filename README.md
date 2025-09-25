# Headline Maker 

Headline Maker is a command-line program to collect news stories and prepare them for publishing in the Prodigy Service client application.
It uses news stories to make a headline and story, then creates Prodigy object files that is put in the Prodigy Reloaded database to be served by the Prodigy Reloaded server.

Different news services are picked with "pluggable" built-in news gathering libraries. 

## Usage

```sh
headline_maker [options]
```

## Options

| Option                | Alias | Type    | Description                                                                                  |
|-----------------------|-------|---------|----------------------------------------------------------------------------------------------|
| `--input`             | `-i`  | string  | Input file or URL for the news feed. Default: `https://memeorandum.com/feed.xml`              |
| `--output`            | `-o`  | string  | Output file name. Default: `NH00A000.BDY`                                                    |
| `--directory`         | `-d`  | string  | Output directory. Default: `.`                                                               |
| `--help`              | `-h`  | boolean | Show help message and exit.                                                                  |
| `--feedstyle`         | `-f`  | string  | Feed style module name (without `Elixir.` prefix). Default: `MemeorandumFeed`                |
| `--retroguide`        | `-r`  | string  | Retroguide identifier. Default: `511-1234`                                                   |
| `--debugoutput`       |       | string  | Debug output file (no alias).                                                                |
| `--debuginput`        |       | string  | Debug input file (no alias). If specified, overrides feedstyle with `DebugFeed`.             |

## Example

```sh
headline_maker --input "https://example.com/feed.xml" --output "output.bdy" --directory "/tmp" --feedstyle "CustomFeed" --retroguide "123-4567"
```

## Help

To display the help message, use:

```sh
headline_maker --help
```

## Notes

- All options except `--help` have sensible defaults.
- Debug options do not have short aliases.
- If `--debuginput` is specified, the feed style is overridden to use `DebugFeed`.
