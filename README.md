# ISNA63 Tech Rota

Drag-and-drop volunteer scheduler for the ISNA63 tech team covering breakouts, film festival, and Qira'at on Sat 5 & Sun 6 September. Assignments sync live across every viewer through a self-hosted ASP.NET Core API + SQLite.

## Deploy on Windows (IIS)

### Prerequisites

- Windows Server or Windows 10/11
- IIS enabled (Turn Windows Features On → Internet Information Services)
- [.NET 8 Hosting Bundle](https://dotnet.microsoft.com/en-us/download/dotnet/8.0) (includes both runtime and ASP.NET Core module for IIS)

### 1. Publish the app

On the Windows machine (with .NET 8 SDK installed):

```powershell
cd api
dotnet publish -c Release -o C:\inetpub\isna-rota
```

This compiles the API and copies `index.html` into `wwwroot\` automatically.

### 2. Create the IIS site

1. Open **IIS Manager** (`inetmgr`).
2. Right-click **Sites** → **Add Website**.
   - **Site name:** `ISNA-Rota`
   - **Physical path:** `C:\inetpub\isna-rota`
   - **Binding:** pick a port (e.g. `8080`) or use a hostname.
3. Click the **Application Pool** for the site → **Basic Settings** → set **.NET CLR Version** to **No Managed Code**.
4. Make sure the app pool identity has read/write access to `C:\inetpub\isna-rota` (for the SQLite database file).

### 3. Open the firewall

If other devices on the network need access:

```powershell
netsh advfirewall firewall add rule name="ISNA Rota" dir=in action=allow protocol=tcp localport=8080
```

### 4. Use it

Open `http://<your-machine-ip>:8080` on any device. Enter passcode `isna2026`. All assignments sync across every browser in ~3 seconds.

## How it works

- **Backend:** ASP.NET Core minimal API with two endpoints (`GET /api/rota`, `POST /api/rota`). State is a single JSON blob stored in SQLite (`rota.db`, created automatically on first run).
- **Frontend:** Single `index.html` with drag-and-drop (desktop) and tap-to-assign (mobile). Polls the API every 3 seconds for cross-device sync.
- **Passcode:** Soft gate in the client — keeps casual visitors out but isn't a security boundary. Change it in `index.html`.
- **Offline fallback:** If the API can't be reached, assignments still save to `localStorage` so you can keep working. The sync pill in the header shows the current status (`Live`, `Saving`, `Offline`).

## Local development (no IIS)

```powershell
cd api
dotnet run
```

Opens on `http://localhost:5000`. No build step, no npm, no dependencies beyond .NET 8.
