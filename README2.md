# TmdbMovies

A small PowerShell module for searching and looking up movie details via [TMDb](https://www.themoviedb.org/)'s free API.

## Setup

1. Get a free API key: https://www.themoviedb.org/settings/api
   (either the **API Key (v3 auth)** or **API Read Access Token (v4 auth)** works - the module auto-detects which one you give it).
2. Set it as an environment variable so you don't have to pass it every call:
   ```powershell
   setx TMDB_API_KEY "your-key-here"
   # restart your terminal after setx
   ```
   Or just pass `-ApiKey <key>` on any command.
3. Import the module:
   ```powershell
   Import-Module .\TmdbMovies.psd1
   ```

## Usage

**Search:**
```powershell
Find-TmdbMovie "star wars"
Find-TmdbMovie "dune" -Year 2021
Find-TmdbMovie "matrix" -Page 2
```

**Details (by TMDb id or IMDb id - both work):**
```powershell
Get-TmdbMovie -Id 11
Get-TmdbMovie -Id tt0076759
Get-TmdbMovie -Id tt0076759 -Verbose    # adds full cast, writers, budget, revenue, keywords, etc.
```

**Pipe search straight into details:**
```powershell
Find-TmdbMovie "star wars" | Select-Object -First 1 | ForEach-Object { Get-TmdbMovie -Id $_.Id }
```

## Notes

- One HTTP request per detail lookup either way - `-Verbose` just surfaces more fields from the same response, it doesn't make extra calls.
- IMDb (`tt...`) ids are resolved to a TMDb id via TMDb's `/find` endpoint before the details call, since TMDb's own detail endpoint only accepts its own numeric ids.
- `Search-TmdbMovie` is available as an alias for `Find-TmdbMovie` if you prefer that name.
