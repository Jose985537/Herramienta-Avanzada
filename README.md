# Herramienta Avanzada v5.0

Suite de administracion de Windows en PowerShell con 18 modulos funcionales.
Creado por: NEXUS_CALDERON

## Requisitos

- Windows 7/8/8.1/10/11 (x64)
- PowerShell 5.1+
- Permisos de administrador (elevacion automatica via UAC)

## Instalacion

```
git clone <repo> HerramientaAvanzada
cd HerramientaAvanzada
.\"Herramienta Avanzada.bat"
```

O directamente via PowerShell:

```
powershell -NoProfile -ExecutionPolicy Bypass -File launcher.ps1
```

## Estructura del proyecto

```
HerramientaAvanzada/
  Herramienta Avanzada.bat   Entry point (verifica admin, lanza PowerShell)
  launcher.ps1               Orquestador principal (UAC, carga modulos, menu)
  config/
    settings.ini             Configuracion centralizada (rutas, logging, colores)
  lib/
    MenuHelpers.ps1          Funciones de UI compartidas (menus, log, config)
    Read-Config.ps1          Parser de archivos INI a JSON
    Backup.ps1               Copia de seguridad de controladores
    ConfigSys.ps1            Configuracion del sistema (nombre, workgroup, env vars)
    DriveMapping.ps1         Mapeo de unidades de red
    Hosts.ps1                Editor de archivo Hosts
    Info.ps1                 Informacion del sistema (hardware, OS, redes)
    Maintenance.ps1          Mantenimiento (temp, SFC, CHKDSK, USB, restore points)
    Network.ps1              Red (ipconfig, DNS, puertos, shares)
    Power.ps1                Apagar/Reiniciar/Bloqueo/Cerrar sesion
    PowerPlan.ps1            Planes de energia (listar, activar, crear)
    Processes.ps1            Gestor de procesos (listar, matar)
    RDP.ps1                  Escritorio Remoto (activar/desactivar, firewall)
    SecurityPlus.ps1         Seguridad (firewall, reglas, takeown)
    Services.ps1             Servicios (iniciar, detener, reiniciar, startup apps)
    TaskScheduler.ps1        Tareas programadas (listar, crear, habilitar)
    Users.ps1                Cuentas de usuario, grupos, contrasenas, perfiles
    WiFi.ps1                 Gestion de perfiles WiFi
    WindowsFeatures.ps1      Caracteristicas de Windows (DISM)
  test/
    Functional-Tests.ps1     Tests funcionales (40 tests)
    Validate-Phase1.ps1      Validacion de infraestructura (10 tests)
    Validate-Phase2.ps1      Validacion de modulos (88 tests)
  logs/
    app.log                  Bitacora de ejecucion
  backups/                   Destino de copias de seguridad
```

## Modulos

| # | Modulo | Descripcion |
|---|--------|-------------|
| 1 | Maintenance | Limpieza temporal, SFC, CHKDSK, hibernacion, restore points, USB |
| 2 | Network | ipconfig, DNS flush, puertos, carpetas compartidas |
| 3 | SecurityPlus | Firewall, reglas, takeown |
| 4 | Info | Sistema, hardware, OS, variables de entorno, discos |
| 5 | Power | Apagar, reiniciar, bloquear, cerrar sesion |
| 6 | ConfigSys | Nombre PC, workgroup, explorer, env vars, startup |
| 7 | Users | Cuentas, grupos, contrasenas, perfiles |
| 8 | Services | Servicios, aplicaciones de inicio |
| 9 | Backup | Copia/restauracion de controladores |
| 10 | Processes | Gestor de procesos |
| 11 | Hosts | Editor de archivo hosts |
| 12 | WiFi | Perfiles WiFi |
| 13 | RDP | Escritorio Remoto |
| 14 | PowerPlan | Planes de energia |
| 15 | TaskScheduler | Tareas programadas |
| 16 | WindowsFeatures | Caracteristicas de Windows (DISM) |
| 17 | DriveMapping | Unidades de red |

## Configuracion

Editar `config/settings.ini`:

```ini
[Paths]
BackupSourceDrivers=%SYSTEMROOT%\System32\Drivers
BackupSourceDriverStore=%SYSTEMROOT%\System32\DriverStore\FileRepository
BackupSourceInf=%SYSTEMROOT%\inf
BackupDest=.\backups\drivers\
LogDir=.\logs\
TempDir=%TEMP%\HerramientaAvanzada\

[Logging]
Level=INFO
RetentionDays=30
```

Las variables `%SYSTEMROOT%` y `%TEMP%` se expanden automaticamente.

## Compatibilidad

- Nombres de grupo: usa SID (`S-1-5-32-544` para Administrators) -- funciona en ES/EN/otros idiomas
- Planes de energia: busca por nombre en espanol E ingles -- funciona en Windows ES/EN
- Firewall RDP: intenta "Escritorio remoto" y "Remote Desktop"

## Desarrollo

Ejecutar tests:

```powershell
.\test\Validate-Phase1.ps1    # 10 tests de infraestructura
.\test\Validate-Phase2.ps1    # 88 tests de modulos
.\test\Functional-Tests.ps1   # 40 tests funcionales
```

## Licencia

Uso interno / distribucion libre.

## Introduccion

Herramienta Avanzada es una suite de administracion remota y local para sistemas Windows, desarrollada en PowerShell 5.1. Disenada para tecnicos de soporte, administradores de sistemas y usuarios avanzados que necesitan realizar tareas de mantenimiento, configuracion, diagnostico y reparacion desde una unica interfaz unificada. La herramienta integra 18 modulos funcionales que cubren desde la gestion de usuarios y servicios hasta el mapeo de unidades de red y plan de energia, todo accesible desde un menu principal navegable.

## Uso

Ejecutar el archivo batch:

```powershell
.\"Herramienta Avanzada.bat"
```

O directamente con PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File launcher.ps1
```

Al iniciar, la herramienta:
1. Verifica que se ejecute con permisos de administrador (elevacion automatica via UAC si es necesario)
2. Carga los 18 modulos desde la carpeta `lib/`
3. Lee la configuracion desde `config/settings.ini`
4. Muestra el menu principal con las categorias disponibles
5. El usuario selecciona un modulo y accede a sus opciones especificas
6. Cada modulo presenta su propio submenu con acciones como listar, crear, eliminar, configurar, etc.

Navegacion: usar las teclas numericas para seleccionar opciones, `0` para regresar al menu anterior, y `X` para salir.

## Propositos

- Centralizar herramientas de administracion de Windows en un solo punto de acceso
- Automatizar tareas repetitivas de mantenimiento y configuracion del sistema
- Proporcionar una interfaz uniforme y predecible para tecnicos de soporte
- Reducir el tiempo de diagnostico y reparacion de problemas comunes
- Facilitar la gestion remota de equipos mediante scripts portables
- Estandarizar procedimientos de configuracion post-instalacion
- Permitir la personalizacion via archivo de configuracion INI
- Mantener un registro centralizado de todas las operaciones realizadas

## Logica del sistema

La aplicacion sigue un flujo de ejecucion en capas:

1. **Capa de entrada** (`Herramienta Avanzada.bat`): verifica que el usuario sea administrador usando `fltmc.exe` y lanza PowerShell con `-ExecutionPolicy Bypass`.

2. **Capa orquestadora** (`launcher.ps1`): define el versionado, eleva privilegios via UAC si es necesario, ejecuta el parseo de configuracion, carga secuencialmente los 18 modulos desde `lib/`, y presenta el bucle del menu principal con manejo de opciones via `switch`.

3. **Capa de configuracion** (`Read-Config.ps1`, `settings.ini`): parsea el archivo INI a un objeto JSON en `$global:Config`, expandiendo variables de entorno (`%SYSTEMROOT%`, `%TEMP%`), con resolucion de rutas relativas contra el directorio del script.

4. **Capa de utilidades compartidas** (`MenuHelpers.ps1`): proporciona funciones reutilizables como `Write-Menu`, `Get-ConfigValue`, `Invoke-Log`, `Read-SecurePassword`, `Write-Result`, `Get-ScriptDirectory`, usadas por todos los modulos.

5. **Capa funcional** (18 modulos en `lib/`): cada modulo implementa sus propias funciones y submenus, heredando las utilidades compartidas. La comunicacion entre modulos se realiza via funciones exportadas con `-Scope Global`.

6. **Capa de persistencia** (`logs/app.log`, `backups/`): registro de operaciones con rotacion automatica por antiguedad y destino de copias de seguridad.

## Ventajas, desventajas y limitaciones

### Ventajas

- **Portable**: no requiere instalacion, se ejecuta desde cualquier directorio
- **Modular**: cualquier modulo puede modificarse o reemplazarse sin afectar a los demas
- **Autocontenido**: 18 modulos en un solo directorio, sin dependencias externas
- **Configurable**: comportamiento ajustable via `settings.ini` sin modificar codigo
- **Multilingue**: compatible con Windows en espanol e ingles (grupos por SID, planes de energia bilingues)
- **Auto-elevacion**: solicita permisos de administrador solo cuando es necesario
- **Logging centralizado**: todas las operaciones quedan registradas con timestamp y nivel
- **Probado**: 138 tests automatizados en 3 suites de validacion con 100% de aprobacion
- **Documentado**: todas las funciones incluyen ayuda para `Get-Help`
- **Codigo 100% ASCII**: sin problemas de encoding entre sistemas

### Desventajas

- **Solo Windows**: no funciona en Linux o macOS (depende de cmdlets y binarios nativos de Windows)
- **PowerShell 5.1 requerido**: no compatible con PowerShell Core sin modificaciones
- **Interfaz de consola**: sin interfaz grafica, puede resultar menos intuitiva para usuarios no tecnicos
- **Sin manejo de errores avanzado**: los errores se muestran en pantalla pero no siempre se registran con detalle de stack trace
- **Sin soporte para ejecucion remota nativa**: no incluye capacidades de WinRM o PSRemoting incorporadas
- **Sin sistema de plugins**: agregar funcionalidad requiere modificacion directa del launcher

### Limitaciones

- Requiere permisos de administrador para la mayoria de las operaciones
- Algunas funciones (como CHKDSK) requieren reinicio del sistema para completarse
- La expansion de variables de entorno en `settings.ini` solo soporta `%VAR%` (no `$env:VAR`)
- Los backups de controladores pueden consumir varios gigabytes de espacio en disco
- La rotacion de logs solo considera antiguedad, no tamano del archivo
- Sin soporte para configuracion por perfiles de usuario o por equipo
- Las pruebas funcionales requieren ejecucion manual (no hay CI/CD integrado)
- Sin encriptacion de configuracion: las rutas y credenciales en `settings.ini` se almacenan en texto plano

---

## MEJORAS Y ACTUALIZACIONES (v5.0)

### Documentacion de funciones
Todas las funciones en los 18 modulos y el launcher incluyen ayuda comentada (`<# .SYNOPSIS #>`) para uso con `Get-Help`:
```powershell
Get-Help Invoke-Log
Get-Help Get-ConfigValue
Get-Help Show-UsersMenu
```

### Encoding y parsing
- Todos los archivos `.ps1` normalizados a UTF-8 con BOM, contenido 100% ASCII
- Eliminados todos los caracteres no-ASCII (acentos, caracteres especiales) del codigo fuente
- Errores de parsing corregidos en 5 modulos por corrupcion de encoding

### Arquitectura
- `#Requires -RunAsAdministrator` eliminado; elevacion UAC explicita via `ProcessStartInfo.Verb = "runas"`
- `cacls.exe` (deprecado) reemplazado por `fltmc.exe` para verificacion de admin en batch
- Variables `$global:Config` y `$global:AppVersion` con ambito explicito
- `Read-Config.ps1`: expansion de `%SYSTEMROOT%`, `%TEMP%` via `[Environment]::ExpandEnvironmentVariables()`
- Logging centralizado: `Invoke-Log` usa `LogDir` de `settings.ini`, con rotacion por antiguedad (configurable via `RetentionDays`)
- .gitignore agregado (excluye logs/, backups/, *.tmp, *.vbs)

### Correcciones en modulos
- **PowerPlan**: duplicacion de plan corregida (`Select-Object -Last 1` en vez de `-Skip 1 -First 1`); nombres bilingues ES/EN; regex escapado con `[regex]::Escape()`
- **Users**: grupos por SID (`S-1-5-32-544`, `S-1-5-32-545`) en vez de nombres localizados; `Set-LocalUser` con `-ErrorAction Stop` en vez de `SilentlyContinue`; `>nul` reemplazado por `*>$null`; comparacion exacta de usuario (`-eq` en vez de `-match`)
- **Maintenance**: USBEject usa `Win32_Volume.Dismount()` en vez de `Remove-Partition` (que destruia datos); CHKDSK con pipe `echo Y |` para evitar colgarse esperando input
- **Hosts**: eliminacion por IP+hostname (whitespace-agnostic); solo elimina 1 entrada a la vez (no todas las coincidencias)
- **WindowsFeatures**: `Sort-Object` antes de `Select-Object -First 50`; `[Math]::Max(0, ...)` para evitar numeros negativos
- **DriveMapping**: muestra mensaje de error en vez de re-ejecutar `net use`
- **Backup**: `Get-ConfigSourcePaths` usa `Get-ConfigValue` (no reimplementa parsing INI)
- **Network**: puertos filtrados con `findstr /C:"` para evitar falsos positivos (ej. puerto 4430 no coincide con 443)
- **RDP**: estado del firewall ahora se muestra correctamente (antes se descartaba a `$null`)
- **WiFi**: `Select-Object -First 1` antes de `-match` para evitar bug de `$matches` con arrays
- **SecurityPlus**: `$env:USERNAME` quoteado correctamente en icacls (rutas con espacios)

### Codigo muerto eliminado
- `Write-Log.ps1` (reemplazado por `Invoke-Log` en MenuHelpers)
- `Read-Password.ps1` (reemplazado por `Read-SecurePassword` en MenuHelpers)
- `Read-SecureInput` (nunca usado)
- `$wifiProfiles` (nunca usado)
- `$exitRequested` en launcher (ramas identicas)
- `Validate-Phase2.ps1` raiz (archivo de 0 bytes)

### Test suite actualizada
- `Validate-Phase1.ps1`: reescrito para reflejar el codigo actual (eliminados tests de modulos huerfanos, agregados tests de funciones compartidas: `Invoke-Log`, `Get-ConfigValue`, `Read-SecurePassword`, `Write-Result`)
- `Validate-Phase2.ps1`: actualizado para incluir todos los modulos (88 tests)
- `Functional-Tests.ps1`: cubre los 17 menus, config, branding, colisiones (40 tests)
- Total: 138 tests | 3 suites | 100% pass rate

### Notas tecnicas
- `Get-ScriptDirectory` usa `Get-PSCallStack` como fallback robusto cuando `$PSScriptRoot` no esta disponible
- Configuracion en `$global:Config` se construye desde `Read-Config.ps1` (JSON); `Get-ConfigValue` consulta `$global:Config` primero, con fallback a lectura directa del INI
- `$global:Config` inicializado a `$null` antes del bloque try en launcher (evita estado residual)
