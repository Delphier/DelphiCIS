# DelphiCIS

**Delphi Component Install Scripts** — a small collection of PowerShell scripts that automate installing (and uninstalling) popular Delphi component libraries into one or more Embarcadero RAD Studio / Delphi IDE installations, including the Community edition.

## How it works

Every script in this repository follows the same pattern:

1. It is meant to be copied into (or run from) the **root folder of the component**.
2. It validates that it is being run from a valid component folder.
3. It calls the [`RAD Studio CLI`](https://github.com/Delphier/radstudio) command-line tool to discover IDE installations, build projects, register packages, and manage library/environment paths.
4. Each script accepts an `-uninstall` switch to reverse everything it did on install.

## Prerequisites

- **PowerShell 7+**
- **[`RAD Studio CLI`](https://github.com/Delphier/radstudio) command-line tool**, installed and available on your `PATH`.

## Usage

Install:

```powershell
.\JCL.ps1
```

You'll be prompted to pick which installed RAD Studio / Delphi IDE to install the component into (via `radstudio select`).

Uninstall:

```powershell
.\JCL.ps1 -uninstall
```

## Notes

- These scripts don't download or fetch component source code themselves — you need to obtain the component's source separately and run the corresponding script from within it.

## Related project

- [`RAD Studio CLI`](https://github.com/Delphier/radstudio) — the underlying command-line tool.
