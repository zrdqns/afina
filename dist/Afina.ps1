# Afina 0.3.0: análisis y optimización de Windows. Generado por build.ps1; no editar a mano.
# Iconos: Phosphor Icons (https://phosphoricons.com), licencia MIT.
param(
    [switch]$Scan,
    [switch]$Json,
    [string]$Snapshot,
    [switch]$NoElevate
)
$ErrorActionPreference = 'Stop'

# Antes de cargar nada: con PowerShell limitado (Smart App Control o App Control) el código de Afina no llega a cargar.
# Todavía no hay T ni configuración: el aviso sale en el idioma de Windows.
if ([string]$ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { Write-Host 'Afina no puede correr aquí: PowerShell está limitado por Smart App Control o App Control.' }
    else { Write-Host "Afina can't run here: PowerShell is restricted by Smart App Control or App Control." }
    # Con "irm … | iex", exit cerraría la ventana antes de leer el aviso.
    if ($PSCommandPath) { exit 2 } else { return }
}

$Global:AfCodeBlock = {
function Get-AfVersion { '0.3.0' }

# Traducciones al inglés. Cada línea: el texto en español tal cual está en el código (distingue mayúsculas), "==>" y su traducción.
# Lo usa Get-AfText (alias T) en Core\Localization.ps1; tests\Translations.Tests.ps1 vigila que no falte ninguna.
$script:AfStringsEn = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
$script:AfStringsEnText = @'
# Revisiones y categorías
y==>and
{0} (no se puede reinstalar)==>{0} (can't be reinstalled)
{0} a {1} × {2}, de {3} a {4} Hz. Pregunta si se ve bien y vuelve sola al modo anterior a los 15 s si nadie responde.==>{0} at {1} × {2}, from {3} to {4} Hz. Asks whether it looks right and goes back to the previous mode after 15 s if nobody answers.
{0} apps con actualización==>{0} apps with updates
{0} del adaptador {1} pasan a apagado.==>{0} on the {1} adapter are turned off.
{0} GB en un módulo==>{0} GB in one module
{0} módulos==>{0} modules
{0} no está al día==>{0} is out of date
{0} programas arrancan con Windows; ninguno sobra==>{0} programs start with Windows; none are extra
{0} programas menos al arrancar==>{0} fewer programs at startup
{0} programas sin firma arrancan solos==>{0} unsigned programs start on their own
1 amenaza activa==>1 active threat
1 app con actualización==>1 app with an update
1 Gbps==>1 Gbps
1 opción activa==>1 option on
1 programa menos al arrancar==>1 fewer program at startup
1 programa sin firma arranca solo==>1 unsigned program starts on its own
2,4 GHz==>2.4 GHz
Abre {0} y busca actualizaciones.==>Open {0} and check for updates.
Abre {0}.==>Open {0}.
Abre Afina con la cuenta del dueño para quitarlas==>Open Afina with the owner's account to remove them
Abre AMD Software: Adrenalin Edition.==>Open AMD Software: Adrenalin Edition.
Abre Configuración, Sistema, Pantalla, Gráficos.==>Open Settings > System > Display > Graphics.
Abre Configuración, Windows Update, Opciones avanzadas, Actualizaciones opcionales, e instala el driver de pantalla.==>Open Settings > Windows Update > Advanced options > Optional updates and install the display driver.
Abre Intel Driver & Support Assistant, o descárgalo de intel.com.==>Open Intel Driver & Support Assistant, or download it from intel.com.
Abre NVIDIA App.==>Open NVIDIA App.
Abre Seguridad de Windows > Seguridad del dispositivo > Aislamiento del núcleo.==>Open Windows Security > Device security > Core isolation.
Abre Seguridad de Windows, Protección contra virus y amenazas, y actívala.==>Open Windows Security > Virus & threat protection and turn it on.
Abre Seguridad de Windows, Protección contra virus y amenazas.==>Open Windows Security > Virus & threat protection.
Activa==>On
Activa XMP (Intel) o EXPO (AMD) en las opciones de memoria.==>Turn on XMP (Intel) or EXPO (AMD) in the memory settings.
Activada==>On
Activadas==>On
Activado==>On
Actualiza las apps elegidas con winget, sin ventanas.==>Updates the selected apps with winget, silently.
Actualizaciones de Windows==>Windows updates
Actualizadas==>Updated
Ahorro bajo==>Low Power Saving
Ahorro de energía==>Power saver
Ahorro máximo==>Maximum Power Saving
Ahorro medio==>Medium Power Saving
Al día==>Up to date
Almacenamiento==>Storage
Amenazas activas==>Active threats
Antivirus activo==>Antivirus on
Apaga la protección de Windows contra drivers maliciosos. Pide reiniciar.==>Turns off the Windows protection against malicious drivers. Requires a restart.
Apagada==>Off
Apagadas==>Off
Apagado==>Off
Apagado en {0}==>Off on {0}
Apagados==>Off
Apps==>Apps
Apps con actualización==>Apps with updates
Apps promocionales preinstaladas==>Preinstalled promotional apps
AutoGameModeEnabled pasa de 0 a 1.==>AutoGameModeEnabled goes from 0 to 1.
Banda de la conexión Wi-Fi actual==>Band of the current Wi-Fi connection
Bloqueada por UEFI o por una directiva==>Locked by UEFI or by a policy
Bloqueo de aplicaciones no deseadas==>Blocking of unwanted apps
Borra los temporales (abajo) y desinstala los juegos que ya no usas.==>Delete temporary files (below) and uninstall the games you no longer play.
Borrar archivos temporales==>Delete temporary files
Busca el modo de rendimiento y elige {0}.==>Find the performance mode and choose {0}.
Buscando actualizaciones de apps…==>Checking for app updates…
Buscando actualizaciones…==>Checking for updates…
Cada programa que arranca solo alarga el encendido y ocupa memoria mientras juegas.==>Every program that starts on its own makes startup longer and uses memory while you play.
Cambia el cable por uno Cat 5e o mejor: los de 100 Mbps solo tienen 4 hilos.==>Replace the cable with a Cat 5e or better one: 100 Mbps cables only have 4 wires.
Casi todo el software legítimo está firmado; lo que arranca solo y sin firma merece una mirada.==>Almost all legitimate software is signed; anything unsigned that starts on its own deserves a look.
Centro de seguridad de Windows==>Windows Security Center
Cierra las apps antes de actualizarlas==>Close the apps before updating them
Compra un módulo igual al actual: {0} GB a {1} MT/s.==>Buy a module identical to the current one: {0} GB at {1} MT/s.
Con cargador==>Plugged in
Con dos módulos la RAM trabaja en doble canal.==>With two modules, the RAM runs in dual channel.
Con el ahorro de energía, el adaptador inalámbrico se duerme entre paquetes y sube la latencia.==>With power saving, the wireless adapter sleeps between packets and latency goes up.
Con el cargador puesto, Windows deja trabajar al procesador y a la gráfica sin recortes.==>When plugged in, Windows lets the processor and the graphics run without cutbacks.
Con experiencias personalizadas==>With tailored experiences
Con firmas viejas, Defender no reconoce las amenazas recientes.==>With old definitions, Defender doesn't recognize recent threats.
Con la grabación de fondo, Xbox Game Bar graba todo el tiempo y le quita rendimiento a la gráfica.==>With background recording, Xbox Game Bar records all the time and takes performance away from the graphics.
Con poca RAM, Windows usa el disco como memoria y los juegos se traban.==>With little RAM, Windows uses the disk as memory and games stutter.
Con TRIM, el SSD sabe qué bloques puede limpiar y mantiene su velocidad con el tiempo.==>With TRIM, the SSD knows which blocks it can clean and keeps its speed over time.
Con un solo módulo la RAM rinde la mitad: en juegos se nota, sobre todo con gráficos integrados.==>With a single module, the RAM delivers half its bandwidth: it shows in games, especially with integrated graphics.
Conecta el cargador para jugar y para que este análisis refleje el rendimiento real.==>Plug in the charger to play, and so this scan reflects real performance.
Configuración de módulos de memoria==>Memory module configuration
Configuración de privacidad de Windows==>Windows privacy settings
Control de cuentas de usuario==>User Account Control
Datos de diagnóstico al mínimo==>Diagnostic data at the minimum
Datos de diagnóstico obligatorios (el mínimo que ofrece Configuración) y sin experiencias personalizadas.==>Required diagnostic data (the minimum Settings offers) and no tailored experiences.
Datos EDID del monitor==>Monitor EDID data
Defender en tiempo real==>Defender real-time protection
Defender encontró algo que sigue en la PC.==>Defender found something that is still on the PC.
Defender frena los instaladores que meten adware o barras en el navegador.==>Defender stops installers that sneak in adware or browser toolbars.
Déjalo así mientras juegas con el cargador puesto.==>Leave it that way while you play plugged in.
Descarga AMD Software: Adrenalin Edition desde amd.com; detecta la gráfica sola.==>Download AMD Software: Adrenalin Edition from amd.com; it detects the graphics on its own.
Descarga e instala las actualizaciones que Windows instalaría solo, con su avance. No incluye versiones nuevas de Windows.==>Downloads and installs the updates Windows would install on its own, showing progress. Doesn't include new versions of Windows.
Descarga el driver más reciente desde el sitio del fabricante de la gráfica.==>Download the latest driver from the graphics maker's website.
Descarga Intel Driver & Support Assistant desde intel.com.==>Download Intel Driver & Support Assistant from intel.com.
Descarga NVIDIA App desde nvidia.com.==>Download NVIDIA App from nvidia.com.
DisableDeleteNotify de NTFS pasa de 1 a 0.==>NTFS DisableDeleteNotify goes from 1 to 0.
djdallmann, investigación de red==>djdallmann, network research
Dominio==>Domain
Dos módulos iguales==>Two matching modules
Driver básico de Windows==>Basic Windows driver
Driver de {0} de hace {1} meses==>{0} driver from {1} months ago
Driver de gráficos al día==>Graphics driver up to date
Driver del fabricante==>Manufacturer driver
el actualizador de Adobe==>the Adobe updater
El adaptador puede ir a 1 Gbps o más, pero el cable o el puerto lo limitan.==>The adapter can do 1 Gbps or more, but the cable or the port is holding it back.
El ahorro de energía del adaptador renegocia el enlace y puede meter pausas en la conexión.==>The adapter's power saving renegotiates the link and can add pauses to the connection.
El cable o el puerto limita la pantalla==>The cable or port is limiting the display
El monitor anuncia más Hz de los que Windows puede usar con esta conexión.==>The monitor supports more Hz than Windows can use over this connection.
El plan pasa de Ahorro de energía a Equilibrado, y el modo con cargador a Mejor rendimiento. Con batería no cambia nada.==>The plan goes from Power saver to Balanced, and the plugged-in mode to Best performance. Nothing changes on battery.
Elige cada juego y márcalo en Alto rendimiento.==>Choose each game and set it to High performance.
En Amenazas actuales, quita o pon en cuarentena cada una.==>Under Current threats, remove or quarantine each one.
En batería==>On battery
En batería, Windows y el fabricante recortan la potencia para que dure más.==>On battery, Windows and the manufacturer cut power so it lasts longer.
En estas laptops, los límites de potencia y los ventiladores los maneja la herramienta del fabricante, no Windows.==>On these laptops, power limits and fans are handled by the manufacturer's tool, not by Windows.
En la próxima versión==>In the next version
En laptops, conecta el monitor al puerto que va a la gráfica dedicada (suele ser el HDMI o un USB-C con DisplayPort).==>On laptops, connect the monitor to the port wired to the dedicated graphics (usually HDMI or a USB-C port with DisplayPort).
En NVIDIA App o en el panel de la gráfica, revisa que la dedicada sea la preferida.==>In NVIDIA App or the graphics control panel, make sure the dedicated graphics is the preferred one.
EnableLUA pasa de 0 a 1. Pide reiniciar.==>EnableLUA goes from 0 to 1. Requires a restart.
Energía==>Power
Entra a Controladores y software.==>Go to Drivers & Software.
Entra a Controladores.==>Go to Drivers.
Entra a la BIOS: suele ser con Supr o F2 al encender.==>Enter the BIOS: usually with Del or F2 at power-on.
Equilibrado==>Balanced
Espacio libre del disco del sistema==>Free space on the system drive
Esta laptop tiene dos gráficas==>This laptop has two GPUs
Estado de la batería==>Battery status
Ethernet sin ahorro de energía==>Ethernet without power saving
Fabricante de la gráfica==>Graphics maker
Firewall de Windows==>Windows Firewall
Firewall de Windows activado==>Windows Firewall on
Firmas Authenticode de los ejecutables==>Authenticode signatures of the executables
Firmas de Microsoft Defender al día==>Microsoft Defender definitions up to date
Grabación en segundo plano apagada==>Background recording off
Guarda y reinicia.==>Save and restart.
Hace {0} días==>{0} days ago
Hace {0} meses==>{0} months ago
Hace 1 día==>1 day ago
Hardware==>Hardware
Herramienta del fabricante del equipo==>The computer maker's tool
HwSchMode pasa de {0} a 2. Pide reiniciar.==>HwSchMode goes from {0} to 2. Requires a restart.
Inicio==>Startup
Inicio, pantalla de bloqueo y Configuración==>Start, lock screen and Settings
Instala el driver de gráficos que proponga.==>Install the graphics driver it suggests.
Instala el driver Game Ready que proponga.==>Install the Game Ready driver it suggests.
Instala el driver recomendado.==>Install the recommended driver.
Instala el Game Ready más reciente sin instalación limpia.==>Install the latest Game Ready driver without a clean install.
Instala la versión recomendada.==>Install the recommended version.
Instaladas==>Installed
Instalado==>Installed
Instálalo en la ranura libre.==>Install it in the free slot.
Integridad de memoria apagada==>Memory integrity off
Juegos y gráficos==>Gaming and graphics
La banda de 5 GHz es más rápida y tiene menos interferencia, aunque llega un poco menos lejos.==>The 5 GHz band is faster and has less interference, although its range is a bit shorter.
La conexión por cable va a 100 Mbps==>The wired connection runs at 100 Mbps
La conexión se corta unos segundos al aplicar==>The connection drops for a few seconds when applying
la gráfica==>Graphics
La gráfica de {0} no tiene su driver==>The {0} graphics has no driver
La gráfica no tiene su driver==>The graphics has no driver
La gráfica organiza su propio trabajo y baja la latencia; DLSS Frame Generation la necesita.==>The graphics schedules its own work and lowers latency; DLSS Frame Generation requires it.
La RAM está trabajando más lento de lo que permite: el perfil de velocidad se activa en la BIOS.==>The RAM is running slower than it can: the speed profile is turned on in the BIOS.
Laptop en batería==>Laptop on battery
Las apps al día corrigen fallos y huecos de seguridad.==>Up-to-date apps fix bugs and security holes.
Liberados==>Freed up
Lista cerrada de apps promocionales==>Closed list of promotional apps
Lo fija una directiva de la organización==>Set by an organization policy
Los drivers nuevos traen mejoras de rendimiento y arreglos para los juegos recientes.==>New drivers bring performance improvements and fixes for recent games.
Los juegos DirectX 10 y 11 en ventana o sin bordes usan el mismo camino rápido que en pantalla completa: menos latencia.==>DirectX 10 and 11 games in windowed or borderless mode use the same fast path as full screen: lower latency.
Los límites de potencia y los ventiladores los maneja {0}==>Power limits and fans are handled by {0}
Mejor eficiencia energética==>Best power efficiency
Mejor rendimiento==>Best performance
Memoria instalada==>Installed memory
Menos de 100 MB==>Less than 100 MB
Microsoft Defender==>Microsoft Defender
Microsoft Defender: actualizaciones de firmas==>Microsoft Defender: security intelligence updates
Microsoft Defender: amenazas detectadas==>Microsoft Defender: detected threats
Microsoft Defender: protección contra aplicaciones potencialmente no deseadas==>Microsoft Defender: potentially unwanted app protection
Microsoft DirectX: programación de GPU por hardware==>Microsoft DirectX: hardware-accelerated GPU scheduling
Microsoft reconoce que en algunos equipos baja el rendimiento en juegos.==>Microsoft acknowledges that on some PCs it lowers gaming performance.
Microsoft reconoce que junto con la integridad de memoria puede bajar el rendimiento en juegos.==>Microsoft acknowledges that, together with memory integrity, it can lower gaming performance.
Microsoft, blog de Xbox: grabación en segundo plano==>Microsoft, Xbox blog: background recording
Microsoft: ahorro de energía del Wi-Fi==>Microsoft: Wi-Fi power saving
Microsoft: apps de inicio==>Microsoft: startup apps
Microsoft: Control de cuentas de usuario==>Microsoft: User Account Control
Microsoft: datos de diagnóstico de Windows==>Microsoft: Windows diagnostic data
Microsoft: frecuencia de actualización de la pantalla==>Microsoft: display refresh rate
Microsoft: fsutil behavior DisableDeleteNotify==>Microsoft: fsutil behavior DisableDeleteNotify
Microsoft: liberar espacio en el disco==>Microsoft: free up drive space
Microsoft: modo de juego==>Microsoft: Game Mode
Microsoft: modos de energía de Windows==>Microsoft: Windows power modes
Microsoft: optimizaciones para juegos en ventana==>Microsoft: optimizations for windowed games
Microsoft: preferencia de gráficos por app==>Microsoft: graphics preference per app
Microsoft: virtualización y rendimiento en juegos==>Microsoft: virtualization and gaming performance
Mínimo==>Minimum
Modo {0} en {1}==>{0} mode in {1}
Modo de energía con cargador, de {0} a Mejor rendimiento. Con batería no cambia nada.==>Plugged-in power mode, from {0} to Best performance. Nothing changes on battery.
Modo de energía en Mejor rendimiento==>Power mode on Best performance
Modo de juego activado==>Game Mode on
Modo de rendimiento del fabricante==>Manufacturer's performance mode
Muchas pantallas de 144 Hz o más vienen puestas a 60 Hz; con más Hz el juego se ve y se siente más fluido.==>Many 144 Hz or faster displays come set to 60 Hz; with more Hz, games look and feel smoother.
Ninguna==>None
No cambia nada==>Changes nothing
No hay antivirus activo==>No active antivirus
No se deshace: solo descarga firmas nuevas==>Not undone: it only downloads new definitions
No se puede deshacer==>Can't be undone
No se puede deshacer desde Afina==>Can't be undone from Afina
No se puede deshacer desde Afina; se desinstalan en Configuración==>Can't be undone from Afina; uninstall them in Settings
No se puede deshacer: solo borra temporales==>Can't be undone: it only deletes temporary files
Opcional==>Optional
Optimizaciones para juegos en ventana==>Optimizations for windowed games
Otro modo==>Another mode
Pantalla {0}==>Display {0}
Pantalla a su frecuencia máxima==>Display at its highest refresh rate
Pantalla principal==>Main display
Para jugar hoy se recomiendan 16 GB.==>For gaming today, 16 GB is recommended.
Pide reiniciar==>Needs a restart
Plan de alto rendimiento==>High performance plan
Plan de energía, adaptador inalámbrico con cargador: de {0} a Rendimiento máximo.==>Power plan, wireless adapter when plugged in: from {0} to Maximum Performance.
Plataforma de máquina virtual apagada==>Virtual Machine Platform off
Poca memoria RAM==>Low RAM
Poco espacio libre en el disco==>Low free disk space
Privado==>Private
Programación de GPU por hardware==>Hardware-accelerated GPU scheduling
Programas que arrancan con Windows==>Programs that start with Windows
Programas sin firma que arrancan solos==>Unsigned programs that start on their own
Prueba otro puerto del router o del switch.==>Try another port on the router or switch.
PUAProtection pasa a 1: Defender bloquea instaladores con adware.==>PUAProtection goes to 1: Defender blocks installers with adware.
Público==>Public
Puede dar más FPS, pero baja la seguridad==>Can give more FPS, but lowers security
Puede tardar unos minutos==>May take a few minutes
Quitadas==>Removed
RAM en un solo canal==>RAM in single channel
Red==>Network
Reinicia la PC.==>Restart the PC.
Rendimiento==>Performance
Rendimiento máximo==>Maximum Performance
Revisa en el menú del monitor que la entrada no esté en un modo de compatibilidad.==>In the monitor's menu, check that the input isn't in a compatibility mode.
Revisa la lista: si no reconoces alguno, consúltalo en VirusTotal desde "Analizar seguridad".==>Check the list: if you don't recognize one, look it up on VirusTotal from "Scan security".
Se activa al reiniciar==>Turns on after a restart
Se activa el Firewall de Windows en: {0}.==>Windows Firewall gets turned on for: {0}.
Se agrega SwapEffectUpgradeEnable=1 a la configuración de DirectX, sin tocar lo demás.==>SwapEffectUpgradeEnable=1 is added to the DirectX settings, leaving the rest untouched.
Se apaga "Grabar lo que pasó" de Xbox Game Bar. Las capturas manuales siguen funcionando.==>Xbox Game Bar's "Record what happened" gets turned off. Manual captures keep working.
Se apaga al reiniciar==>Turns off after a restart
Se apagan las sugerencias, las apps promocionadas que se instalan solas y el ID de publicidad.==>Turns off suggestions, promoted apps that install on their own, and the advertising ID.
Se desactiva la característica VirtualMachinePlatform. Pide reiniciar.==>Turns off the VirtualMachinePlatform feature. Requires a restart.
Se desactivan igual que en el Administrador de tareas los programas marcados abajo. Los demás siguen arrancando.==>The programs checked below get disabled, just like in Task Manager. The rest keep starting.
Se descargan las firmas nuevas de Microsoft Defender.==>Downloads the latest Microsoft Defender definitions.
Se enciende la protección en tiempo real de Microsoft Defender.==>Turns on Microsoft Defender real-time protection.
Se puede deshacer==>Can be undone
Se quitan para esta cuenta con Remove-AppxPackage.==>They're removed for this account with Remove-AppxPackage.
Se vuelven a instalar; algunas desde la Microsoft Store, con internet==>They get reinstalled; some from the Microsoft Store, with internet
Seguridad==>Security
Si el interruptor está gris, la activó una directiva de la organización: se quita desde ahí.==>If the switch is grayed out, an organization policy turned it on: it's removed from there.
Si el router solo tiene puertos de 100 Mbps, ese es el límite.==>If the router only has 100 Mbps ports, that's the limit.
Si el router tiene una red de 5 GHz, conéctate a esa para jugar.==>If the router has a 5 GHz network, connect to it to play.
Si no aparece, descárgalo del sitio del fabricante de la PC.==>If it doesn't show up, download it from the PC maker's website.
Si tiene bloqueo UEFI, Microsoft indica que para apagarla hay que desactivar el arranque seguro desde la BIOS.==>If it has a UEFI lock, Microsoft says Secure Boot has to be turned off in the BIOS to turn it off.
Si un juego corre en la gráfica integrada, rinde mucho menos.==>A game running on the integrated graphics performs much worse.
Si usas otro antivirus, revisa que esté encendido y al día.==>If you use another antivirus, make sure it's on and up to date.
Sin ahorro de energía==>No power saving
Sin amenazas activas==>No active threats
Sin anuncios ni sugerencias de Windows==>No Windows ads or suggestions
Sin él, cualquier programa puede hacer cambios de administrador sin pedir permiso.==>Without it, any program can make administrator changes without asking.
Sin firewall, cualquier programa o equipo de la red puede intentar conectarse a la PC.==>Without a firewall, any program or device on the network can try to connect to the PC.
Sin protección activa==>No active protection
Sin protección en tiempo real, cualquier descarga o mod puede infectar la PC.==>Without real-time protection, any download or mod can infect the PC.
Sin su driver, Windows usa uno básico: los juegos casi no funcionan y la pantalla no llega a sus Hz.==>Without its driver, Windows uses a basic one: games barely work and the display can't reach its Hz.
sin valor==>no value
Solo con el cargador puesto==>Only when plugged in
Temporales de Windows y del usuario, y cachés de Windows Update y de Optimización de distribución.==>Windows and user temporary files, plus the Windows Update and Delivery Optimization caches.
Temporales y cachés viejas ocupan espacio que Windows y los juegos necesitan.==>Old temporary files and caches take up space that Windows and games need.
Todos firmados==>All signed
Traen arreglos de seguridad y a veces drivers nuevos.==>They bring security fixes and sometimes new drivers.
TRIM del SSD activado==>SSD TRIM on
Usa un cable DisplayPort, o HDMI 2.0 o superior.==>Use a DisplayPort cable, or HDMI 2.0 or newer.
Velocidad de enlace del adaptador==>Adapter link speed
Velocidad de la memoria contra su número de parte==>Memory speed compared to its part number
Vienen con Windows, ocupan espacio y algunas se actualizan solas en segundo plano.==>They come with Windows, take up space, and some update themselves in the background.
Wi-Fi en la banda de 2,4 GHz==>Wi-Fi on the 2.4 GHz band
Wi-Fi sin ahorro de energía==>Wi-Fi without power saving
Windows da prioridad al juego y frena tareas de fondo como las actualizaciones mientras juegas.==>Windows prioritizes the game and holds back background tasks such as updates while you play.
Windows manda menos datos de uso a Microsoft y deja de personalizar sugerencias con ellos.==>Windows sends less usage data to Microsoft and stops tailoring suggestions with it.
Windows muestra sugerencias en Inicio, la pantalla de bloqueo y Configuración, e instala apps promocionadas.==>Windows shows suggestions in Start, on the lock screen and in Settings, and installs promoted apps.
Windows Update==>Windows Update
Windows y los juegos necesitan espacio libre para actualizarse y para su memoria virtual.==>Windows and games need free space to update and for virtual memory.
winget==>winget
winget no está instalado==>winget isn't installed
winget no respondió a tiempo==>winget didn't respond in time
WSL, Docker y los emuladores de Android dejarían de funcionar==>WSL, Docker and Android emulators would stop working
Xbox Game Bar graba todo el tiempo==>Xbox Game Bar is recording all the time
XMP o EXPO apagado==>XMP or EXPO off
{0} opciones activas==>{0} options on
{0} disponibles==>{0} available
{0} apps promocionales==>{0} promotional apps
{0} amenazas activas==>{0} active threats
{0} GB libres==>{0} GB free
Opcionales==>Optional
# Motor, piezas, punto de restauración e inventario
Actualizando {0} de {1}: {2}==>Updating {0} of {1}: {2}
Afina no sabe deshacer este cambio==>Afina doesn't know how to undo this change
Buscando actualizaciones==>Checking for updates
Centro de opiniones==>Feedback Hub
conecta el cargador y vuelve a aplicar==>plug in the charger and apply again
Creando punto de restauración…==>Creating a restore point…
Descargando {0} de {1}==>Downloading {0} of {1}
DISM no aceptó el cambio (código {0})==>DISM didn't accept the change (code {0})
DISM no pudo leer {0} (código {1})==>DISM couldn't read {0} (code {1})
DISM no respondió==>DISM didn't respond
DISM no terminó a tiempo==>DISM didn't finish in time
el adaptador {0} no respondió==>the {0} adapter didn't respond
el Firewall de Windows no aceptó el cambio==>Windows Firewall didn't accept the change
el Firewall de Windows no respondió==>Windows Firewall didn't respond
El registro del cambio necesita Kind.==>The change record needs a Kind.
el servicio de Windows Update está desactivado==>the Windows Update service is turned off
este cambio todavía no se aplica desde Afina==>this change can't be applied from Afina yet
Firmas al día==>Definitions up to date
Firmas al día.==>Definitions up to date.
fsutil no aceptó el cambio==>fsutil didn't accept the change
fsutil no respondió==>fsutil didn't respond
hay otra instalación en curso==>another installation is in progress
hay que reiniciar la PC antes==>the PC has to be restarted first
Instalando {0} de {1}==>Installing {0} of {1}
la app está abierta==>the app is open
la app está fijada en su versión==>the app is pinned to its version
la protección contra alteraciones no dejó encenderla; actívala en Seguridad de Windows, Protección contra virus y amenazas==>Tamper Protection didn't allow turning it on; turn it on in Windows Security > Virus & threat protection
La revisión no devolvió resultado.==>The check returned no result.
Microsoft Defender no aceptó el cambio==>Microsoft Defender didn't accept the change
Microsoft Defender no respondió==>Microsoft Defender didn't respond
ninguna app se pudo actualizar==>no app could be updated
No es un respaldo de Afina: {0}==>Not an Afina backup: {0}
no hay conexión a internet==>there's no internet connection
no hay conexión con Windows Update==>there's no connection to Windows Update
no queda espacio en el disco==>the disk is out of space
no se encontró dónde desactivar {0}==>couldn't find where to disable {0}
no se encontró el adaptador {0}==>the {0} adapter wasn't found
no se encontró el plan de energía activo==>the active power plan wasn't found
no se encontró esa pantalla==>that display wasn't found
no se pudieron descargar las firmas; revisa la conexión a internet==>the definitions couldn't be downloaded; check the internet connection
No se pudieron: {0}.==>Couldn't install: {0}.
no se pudo abrir una conexión segura con Windows Update==>couldn't open a secure connection to Windows Update
No se pudo aplicar: {0}. No se cambió nada.==>Couldn't apply: {0}. Nothing was changed.
No se pudo aplicar: {0}. Una parte quedó aplicada y se puede deshacer desde Historial.==>Couldn't apply: {0}. Part of it was applied and can be undone from History.
No se pudo aplicar: no se pudo guardar el respaldo. No se cambió nada.==>Couldn't apply: the backup couldn't be saved. Nothing was changed.
No se pudo con {0}: {1}.==>Couldn't update {0}: {1}.
No se pudo deshacer: {0}.==>Couldn't undo: {0}.
no se pudo guardar el respaldo en ProgramData\Afina\respaldos==>the backup couldn't be saved in ProgramData\Afina\respaldos
No se pudo guardar el respaldo y una parte quedó aplicada.==>The backup couldn't be saved and part of it was applied.
no se pudo reinstalar {0} desde la Microsoft Store: {1}==>{0} couldn't be reinstalled from the Microsoft Store: {1}
no se puede actualizar como administrador; se actualiza desde la propia app==>it can't be updated as administrator; update it from the app itself
Noticias==>News
Obtener ayuda==>Get Help
Portal de realidad mixta==>Mixed Reality Portal
Restaurar sistema está apagado en {0}:==>System Restore is turned off on {0}:
Se actualizaron {0} de {1}==>Updated {0} of {1}
Se instalaron {0} de {1}==>Installed {0} of {1}
Se liberaron {0}==>Freed up {0}
Se volvió a {0} Hz==>Went back to {0} Hz
Se volvió a {0} Hz porque nadie confirmó la pantalla==>Went back to {0} Hz because nobody confirmed the display
Solitario==>Solitaire
Sugerencias==>Tips
una directiva de la organización lo impide==>an organization policy prevents it
Windows no aceptó {0} Hz en esa pantalla==>Windows didn't accept {0} Hz on that display
Windows no aceptó el ajuste de energía==>Windows didn't accept the power setting
Windows no aceptó el cambio==>Windows didn't accept the change
Windows no aceptó el modo anterior de la pantalla==>Windows didn't accept the display's previous mode
Windows no aceptó el modo de energía==>Windows didn't accept the power mode
Windows no dejó escribir en el registro==>Windows didn't allow writing to the registry
Windows no dejó quitar {0}==>Windows didn't allow removing {0}
Windows no mostró ese ajuste de energía==>Windows didn't expose that power setting
Windows no permitió crearlo==>Windows didn't allow creating it
Windows no respondió a tiempo==>Windows didn't respond in time
Windows Update dejó de responder==>Windows Update stopped responding
Windows Update dejó de responder; lo que falta sigue en Configuración.==>Windows Update stopped responding; what's left is still in Settings.
Windows Update devolvió el código 0x{0:X8}==>Windows Update returned code 0x{0:X8}
Windows Update está instalando otra cosa o espera un reinicio==>Windows Update is installing something else or waiting for a restart
Windows Update no respondió a tiempo==>Windows Update didn't respond in time
Windows Update no respondió como se esperaba==>Windows Update didn't respond as expected
Windows Update se detuvo==>Windows Update stopped
Windows Update se detuvo ({0}); lo que falta sigue en Configuración.==>Windows Update stopped ({0}); what's left is still in Settings.
winget devolvió el código 0x{0:X8}==>winget returned code 0x{0:X8}
winget no terminó en {0} min==>winget didn't finish within {0} min
winget no terminó en 15 min==>winget didn't finish within 15 min
winget no tiene un instalador para esta PC==>winget has no installer for this PC
ya estaba al día==>it was already up to date
Ya estaba al día.==>It was already up to date.
ya no está en la PC; se reinstala desde la Microsoft Store==>it's no longer on the PC; reinstall it from the Microsoft Store
# Interfaz
, {0} para hacer a mano y {1} en orden.==>, {0} to do by hand and {1} all good.
, un canal==>, single channel
{0} {1} GB, {2} GB libres==>{0} {1} GB, {2} GB free
{0} cambios==>{0} changes
{0} cambios aplicados==>{0} changes applied
{0} cambios bajan la seguridad de Windows.==>{0} changes lower Windows security.
{0} cambios listos==>{0} changes ready
{0}, sin driver==>{0}, no driver
¿Se ve bien la pantalla? Vuelve sola al modo anterior en {0} s.==>Does the display look right? It goes back to the previous mode in {0} s.
1 cambio==>1 change
1 cambio aplicado==>1 change applied
1 cambio baja la seguridad de Windows.==>1 change lowers Windows security.
1 cambio listo==>1 change ready
Activar Restaurar sistema en C:==>Turn on System Restore on C:
Afinación==>Tune-up
Afinada==>Tuned up
Afinado==>In tune
Al final pide reiniciar.==>A restart is needed at the end.
Analizando esta PC==>Scanning this PC
Animaciones==>Animations
Aplicada==>Applied
Aplicado==>Applied
Aplicado, no se puede deshacer==>Applied, can't be undone
Aplicando {0} de {1}==>Applying {0} of {1}
Aplicar==>Apply
Automático==>Automatic
Automático sigue la opción Efectos de animación de Windows.==>Automatic follows the Windows Animation effects setting.
Blanco==>White
Cada sesión guarda los valores originales. Se puede deshacer completa o cambio por cambio.==>Each session saves the original values. It can be undone entirely or change by change.
cambio==>change
cambios==>changes
Cancelar==>Cancel
Cerrar==>Close
Comparando con lo recomendado…==>Comparing with what's recommended…
Demostración==>Demo
Desafinado==>Out of tune
Deshacer==>Undo
Deshaciendo {0} de {1}==>Undoing {0} of {1}
Deshaciendo con los valores originales guardados…==>Undoing with the saved original values…
Deshaciendo…==>Undoing…
Deshecha==>Undone
Deshecha en parte==>Partly undone
Deshecho==>Undone
Disco==>Disk
El análisis no pudo terminar. Revisa el registro en ProgramData\Afina.==>The scan couldn't finish. Check the log in ProgramData\Afina.
Elige qué optimizar==>Choose what to optimize
En la demostración no se reinicia la PC.==>The demo doesn't restart the PC.
En orden==>All good
Escritorio==>Desktop
Espera a que termine: hay cambios a medio aplicar.==>Wait until it finishes: some changes are half applied.
Esta PC==>This PC
Fuente==>Source
Gráfica sin driver==>Graphics without driver
Historial==>History
Impacto alto==>High impact
Impacto bajo==>Low impact
Impacto medio==>Medium impact
Incluir este cambio==>Include this change
La pantalla cambia y pide confirmar.==>The display changes and asks you to confirm.
La red se cortará unos segundos.==>The network will drop for a few seconds.
Laptop==>Laptop
Las actualizaciones pueden tardar varios minutos.==>Updates can take several minutes.
Los respaldos quedan en ProgramData\Afina\respaldos.==>Backups are kept in ProgramData\Afina\respaldos.
Mantener==>Keep
Más tarde==>Later
Maximizar==>Maximize
Minimizar==>Minimize
Negro==>Black
Ningún cambio aplicado==>No changes applied
No se pudo aplicar==>Couldn't apply
No se pudo aplicar: {0}. Lo que no aparece como hecho no se cambió.==>Couldn't apply: {0}. Anything not shown as done wasn't changed.
No se pudo crear el punto de restauración: {0}. Los valores originales igual se guardan en Afina.==>The restore point couldn't be created: {0}. The original values are still saved in Afina.
No se pudo deshacer==>Couldn't undo
Nunca==>Never
Optimizar==>Optimize
Para aplicar cambios, abre Afina como administrador.==>To apply changes, open Afina as administrator.
Preferencias==>Preferences
Preparando…==>Preparing…
Programas==>Programs
Punto de restauración creado a las {0}.==>Restore point created at {0}.
Qué cambia==>What changes
Queda 1 para hacer a mano.==>1 left to do by hand.
Quedan {0} para hacer a mano.==>{0} left to do by hand.
Reinicia para terminar 1.==>1 needs a restart to finish.
Reinicia para terminar {0}.==>{0} need a restart to finish.
Afina necesita permisos de administrador. Abre PowerShell como administrador (clic derecho en Inicio) y vuelve a pegar la línea.==>Afina needs administrator rights. Open PowerShell as administrator (right-click Start) and paste the line again.
Reiniciar ahora==>Restart now
Restaurar sistema está bloqueado en esta PC; los valores originales igual se guardan.==>System Restore is blocked on this PC; the original values are still saved.
Revisando el almacenamiento…==>Checking storage…
Revisando el hardware…==>Checking hardware…
Revisando la configuración de Windows…==>Checking Windows settings…
Revisando la energía…==>Checking power…
Revisando la red…==>Checking the network…
Revisando la seguridad…==>Checking security…
Revisando las pantallas…==>Checking displays…
Revisando lo que arranca con Windows…==>Checking what starts with Windows…
Se activa Restaurar sistema y se crea un punto antes.==>System Restore gets turned on and a restore point is created first.
Se aplicará 1 cambio.==>1 change will be applied.
Se aplicarán {0} cambios.==>{0} changes will be applied.
Se crea un punto de restauración antes de aplicar==>A restore point is created before applying
Se crea un punto de restauración antes.==>A restore point is created first.
Seguir sin punto==>Continue without it
Sesiones anteriores y deshacer==>Past sessions and undo
Siempre==>Always
Sin cambios==>No changes
Sin punto de restauración: Restaurar sistema está apagado. Los valores originales igual se guardan.==>No restore point: System Restore is off. The original values are still saved.
Sin punto de restauración; los valores originales se guardan en Afina.==>No restore point; the original values are saved in Afina.
Sistema==>System
Tema==>Theme
Todavía no se aplicaron cambios en esta PC.==>No changes have been applied on this PC yet.
Todo==>All
Todo lo que Afina puede ajustar ya está en orden. {0} para hacer a mano.==>Everything Afina can adjust is already in order. {0} to do by hand.
Valores originales guardados. Se puede deshacer desde Historial.==>Original values saved. It can be undone from History.
Volver==>Back
Volver a analizar==>Scan again
Volver al anterior==>Go back
Volvió al valor anterior==>Went back to the previous value
y {0} no se pudieron==>and {0} couldn't be applied
y 1 no se pudo==>and 1 couldn't be applied
Deshacer todo==>Undo all
Idioma==>Language
Automático sigue el idioma de Windows.==>Automatic follows the Windows display language.
Disponible al terminar==>Available when it finishes
'@
foreach ($afLine in ($script:AfStringsEnText -split "`r?`n")) {
    if (-not $afLine -or $afLine.StartsWith('#')) { continue }
    $afAt = $afLine.IndexOf('==>')
    if ($afAt -gt 0) { $script:AfStringsEn[$afLine.Substring(0, $afAt)] = $afLine.Substring($afAt + 3) }
}

# Idioma de lo que se ve. El español es la base: T devuelve el mismo texto o, en inglés, su traducción.
# El registro de actividad (Write-AfLog) queda en español: no pasa por aquí.
$script:AfLanguage = 'es'

function Set-AfLanguage {
    param([Parameter(Mandatory)][ValidateSet('es', 'en')][string]$Language)
    $script:AfLanguage = $Language.ToLowerInvariant()
}

function Get-AfLanguage { $script:AfLanguage }

function Get-AfText {
    param([string]$Text)
    if ($script:AfLanguage -eq 'en' -and $Text -and $script:AfStringsEn.ContainsKey($Text)) { return $script:AfStringsEn[$Text] }
    $Text
}
Set-Alias -Name T -Value Get-AfText

# Automático (o un valor desconocido): el idioma de pantalla de Windows, español o, si es otro, inglés.
function Resolve-AfLanguage {
    param([string]$Setting)
    if ($Setting -in 'es', 'en') { return $Setting.ToLowerInvariant() }
    if ((Get-UICulture).TwoLetterISOLanguageName -eq 'es') { 'es' } else { 'en' }
}

# Al abrir: el idioma guardado en la configuración (Automático si no hay o no se conoce).
function Set-AfStartLanguage {
    param([hashtable]$Config)
    Set-AfLanguage -Language (Resolve-AfLanguage -Setting $(if ($Config) { $Config.Language } else { $null }))
}

# La hora como se escribe en el idioma: 16:42 o 4:42 PM.
function Format-AfTime {
    param([Parameter(Mandatory)][datetime]$Date)
    if ($script:AfLanguage -eq 'en') { $Date.ToString('h:mm tt', (Get-AfCulture)) } else { $Date.ToString('HH:mm') }
}

# Formato de fechas y números del idioma actual.
function Get-AfCulture {
    [System.Globalization.CultureInfo]::GetCultureInfo($(if ($script:AfLanguage -eq 'en') { 'en-US' } else { 'es-ES' }))
}

$script:AfLogLines = New-Object System.Collections.Generic.List[string]
$script:AfLogPath = $null

function Start-AfLog {
    param([Parameter(Mandatory)][string]$Directory)
    try {
        New-Item -ItemType Directory -Force -Path $Directory | Out-Null
        $path = Join-Path $Directory ((Get-Date -Format 'yyyy-MM-dd_HHmmss') + '.log')
        [System.IO.File]::WriteAllText($path, '', (New-Object System.Text.UTF8Encoding($true)))
        $script:AfLogPath = $path
    } catch {
        $script:AfLogPath = $null
    }
    $script:AfLogPath
}

function Write-AfLog {
    param(
        [ValidateSet('Info', 'Warn', 'Error')][string]$Level = 'Info',
        [Parameter(Mandatory)][string]$Message
    )
    $line = '{0} {1,-5} {2}' -f (Get-Date -Format 'HH:mm:ss.fff'), $Level.ToUpperInvariant(), $Message
    $script:AfLogLines.Add($line)
    if ($script:AfLogPath) {
        try { [System.IO.File]::AppendAllText($script:AfLogPath, $line + "`r`n", [System.Text.Encoding]::UTF8) } catch { }
    }
}

function Get-AfLogLines { , $script:AfLogLines.ToArray() }

function Get-AfLogPath { $script:AfLogPath }

# Para que el runspace de aplicar escriba en el mismo archivo que la ventana.
function Set-AfLogPath {
    param([string]$Path)
    $script:AfLogPath = $Path
}

function Get-AfConfigPath {
    param([string]$ScriptRoot)
    if ($ScriptRoot -and (Test-Path -LiteralPath $ScriptRoot)) {
        $probe = Join-Path $ScriptRoot ('.afina-' + [guid]::NewGuid().ToString('N'))
        try {
            [System.IO.File]::WriteAllText($probe, '')
            Remove-Item -LiteralPath $probe -Force
            return (Join-Path $ScriptRoot 'afina.config.json')
        } catch { }
    }
    Join-Path $env:LOCALAPPDATA 'Afina\afina.config.json'
}

function Get-AfConfigDefaults {
    @{ Theme = 'System'; Motion = 'Auto'; Language = 'Auto'; VirusTotalKey = $null }
}

function Get-AfConfig {
    param([string]$Path)
    $config = Get-AfConfigDefaults
    if ($Path -and (Test-Path -LiteralPath $Path)) {
        try {
            $data = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            foreach ($property in $data.PSObject.Properties) {
                if ($config.ContainsKey($property.Name)) { $config[$property.Name] = $property.Value }
            }
        } catch {
            Write-AfLog -Level Warn -Message "Configuración inválida en $Path; se usan los valores por defecto."
        }
    }
    $config
}

function Set-AfConfig {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][hashtable]$Config)
    $dir = Split-Path -Path $Path -Parent
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [System.IO.File]::WriteAllText($Path, ($Config | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-AfProcess {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string]$Arguments = '',
        [int]$TimeoutMs = 15000,
        [System.Text.Encoding]$Encoding
    )
    if (-not $Encoding) {
        # Las herramientas de consola de Windows escriben en la página OEM (850 en español).
        $Encoding = [System.Text.Encoding]::GetEncoding([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $Encoding
    $psi.StandardErrorEncoding = $Encoding

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutMs)) {
        try { $process.Kill() } catch { }
        Write-AfLog -Level Warn -Message "Tiempo agotado ($TimeoutMs ms): $FilePath $Arguments"
        return [pscustomobject]@{ ExitCode = $null; Output = ''; Error = ''; TimedOut = $true }
    }
    $process.WaitForExit()
    [pscustomobject]@{ ExitCode = $process.ExitCode; Output = $stdout.Result; Error = $stderr.Result; TimedOut = $false }
}

# Corre código que se puede colgar (Windows Update) en un runspace aparte y deja de esperarlo si no avanza.
# El script recibe -Sync (Stage y Beat en UTC) y los -Parameters por nombre; lo último que devuelve es Result.
# Lo que anota en Sync se puede leer aunque se corte (para no perder lo que ya hizo).
function Invoke-AfIsolatedJob {
    param(
        [Parameter(Mandatory)][string]$Script,
        [hashtable]$Parameters = @{},
        # Datos iniciales que el trabajo encuentra en $Sync (por ejemplo, los textos ya traducidos).
        [hashtable]$State = @{},
        [Parameter(Mandatory)][int]$StallSeconds,
        [scriptblock]$OnStage,
        [int]$PollMs = 250
    )
    $sync = [hashtable]::Synchronized(@{ Stage = $null; Beat = [datetime]::UtcNow })
    foreach ($key in $State.Keys) { $sync[$key] = $State[$key] }
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript($Script).AddParameter('Sync', $sync)
    foreach ($key in $Parameters.Keys) { [void]$ps.AddParameter($key, $Parameters[$key]) }
    $handle = $ps.BeginInvoke()

    $stage = $null
    $notify = {
        if ($sync.Stage -and $sync.Stage -ne $stage) {
            $stage = $sync.Stage
            if ($OnStage) { try { & $OnStage $stage } catch { Write-AfLog -Level Warn -Message "Aviso de etapa: $($_.Exception.Message)" } }
        }
    }
    while (-not $handle.IsCompleted) {
        . $notify
        if (([datetime]::UtcNow - [datetime]$sync.Beat).TotalSeconds -gt $StallSeconds) {
            # No se puede cortar una llamada COM trabada: el runspace queda abandonado y muere con el proceso.
            Write-AfLog -Level Warn -Message ('Trabajo aislado sin avance por más de {0} s; se deja de esperar (etapa: {1}).' -f $StallSeconds, $stage)
            try { [void]$ps.BeginStop($null, $null) } catch { }
            return [pscustomobject]@{ Done = $false; TimedOut = $true; Result = $null; Error = $null; HResult = $null; Sync = $sync }
        }
        Start-Sleep -Milliseconds $PollMs
    }
    . $notify

    $result = $null; $message = $null; $hresult = $null
    $failure = $null
    try {
        $output = $ps.EndInvoke($handle)
        if ($output.Count) { $result = $output[$output.Count - 1] }
        # La falla de un método (por ejemplo COM) solo corta esa línea: el script sigue, pero el error cuenta.
        if ($ps.Streams.Error.Count) { $failure = $ps.Streams.Error[0].Exception }
    } catch {
        $failure = $_.Exception
    } finally {
        if ($failure) {
            while ($failure.InnerException) { $failure = $failure.InnerException }
            $message = $failure.Message
            $hresult = $failure.HResult
            Write-AfLog -Level Warn -Message "Trabajo aislado: $message"
        }
        $ps.Dispose()
        $runspace.Dispose()
    }
    [pscustomobject]@{ Done = $true; TimedOut = $false; Result = $result; Error = $message; HResult = $hresult; Sync = $sync }
}

function Test-AfAdmin {
    $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    [bool]$principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Solo desde un archivo (USB): con "irm … | iex" no se relanza (ver Main.ps1).
function Get-AfRelaunchArguments {
    param([Parameter(Mandatory)][string]$ScriptPath, [string[]]$Extra = @())
    @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $ScriptPath)) + $Extra
}

function Restart-AfElevated {
    param([Parameter(Mandatory)][string[]]$Arguments)
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $Arguments
}

function Get-AfInteractiveUser {
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $sid = $current.User.Value
    $name = $current.Name
    try {
        $sessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        $explorer = Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'" -OperationTimeoutSec 15 |
            Where-Object { $_.SessionId -eq $sessionId } | Select-Object -First 1
        if ($explorer) {
            $ownerSid = Invoke-CimMethod -InputObject $explorer -MethodName GetOwnerSid -OperationTimeoutSec 15
            if ($ownerSid.Sid) {
                $sid = $ownerSid.Sid
                $owner = Invoke-CimMethod -InputObject $explorer -MethodName GetOwner -OperationTimeoutSec 15
                if ($owner.User) { $name = if ($owner.Domain) { '{0}\{1}' -f $owner.Domain, $owner.User } else { $owner.User } }
            }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo leer el usuario de la sesión: $($_.Exception.Message)"
    }

    $isSame = $sid -eq $current.User.Value
    $profilePath = $null
    try {
        $profilePath = (Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" -ErrorAction Stop).ProfileImagePath
    } catch { }

    [pscustomobject]@{
        Name = $name
        Sid = $sid
        ProfilePath = $profilePath
        IsSameAsProcess = $isSame
        HkcuRoot = if ($isSame) { 'HKCU:' } else { "Registry::HKEY_USERS\$sid" }
    }
}

function Resolve-AfRegistryPath {
    param([Parameter(Mandatory)][string]$Path, $User)
    if ($User -and -not $User.IsSameAsProcess -and $Path -match '^HKCU:\\?(.*)$') {
        return ($User.HkcuRoot + '\' + $Matches[1]).TrimEnd('\')
    }
    $Path
}

function Get-AfRegistryValue {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name, $User)
    $resolved = Resolve-AfRegistryPath -Path $Path -User $User
    try {
        (Get-ItemProperty -LiteralPath $resolved -Name $Name -ErrorAction Stop).$Name
    } catch {
        $null
    }
}

# Lee una lista de 'Ruta|Nombre' y devuelve un hashtable con la misma clave (ruta sin resolver).
function Get-AfRegistrySnapshot {
    param([string[]]$Reads = @(), $User)
    $snapshot = @{}
    foreach ($read in ($Reads | Select-Object -Unique)) {
        $parts = $read -split '\|', 2
        $snapshot[$read] = Get-AfRegistryValue -Path $parts[0] -Name $parts[1] -User $User
    }
    $snapshot
}

$script:AfNativeReady = $null

function Initialize-AfNative {
    if ($null -ne $script:AfNativeReady) { return $script:AfNativeReady }
    if ('Afina.Native' -as [type]) { $script:AfNativeReady = $true; return $true }
    $source = @'
using System;
using System.Runtime.InteropServices;

namespace Afina {
    public static class Native {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DISPLAY_DEVICE {
            public int cb;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
            public int StateFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DEVMODE {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
            public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra;
            public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput;
            public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
            public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight;
            public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent;
            public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2;
            public int dmPanningWidth; public int dmPanningHeight;
        }

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE lpDisplayDevice, uint dwFlags);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern int ChangeDisplaySettingsEx(string deviceName, ref DEVMODE devMode, IntPtr hwnd, uint flags, IntPtr param);

        [DllImport("powrprof.dll")]
        public static extern uint PowerGetEffectiveOverlayScheme(out Guid overlaySchemeGuid);

        [DllImport("powrprof.dll")]
        static extern uint PowerSetActiveOverlayScheme(Guid overlaySchemeGuid);

        // Windows 11: modo de energía "con cargador", aunque la PC esté en batería.
        [DllImport("powrprof.dll")]
        static extern uint PowerSetUserConfiguredACPowerMode(ref Guid powerModeGuid);

        [StructLayout(LayoutKind.Sequential)]
        public struct SYSTEM_POWER_STATUS {
            public byte ACLineStatus; public byte BatteryFlag; public byte BatteryLifePercent; public byte SystemStatusFlag;
            public int BatteryLifeTime; public int BatteryFullLifeTime;
        }

        [DllImport("kernel32.dll")]
        static extern bool GetSystemPowerStatus(out SYSTEM_POWER_STATUS status);

        // 1 = enchufado, 255 = desconocido (escritorios): los dos cuentan como con cargador.
        public static bool IsOnAcPower() {
            SYSTEM_POWER_STATUS status;
            if (!GetSystemPowerStatus(out status)) return true;
            return status.ACLineStatus != 0;
        }

        // 0 = hecho; 0xFFFFFFFF = en batería y sin la función de Windows 11; 0xFFFFFFFE = Windows no tiene modos de energía.
        public static uint SetAcOverlay(string guid) {
            Guid mode = new Guid(guid);
            bool onAc = IsOnAcPower();
            uint result = onAc ? 0xFFFFFFFE : 0xFFFFFFFF;
            if (onAc) {
                try { result = PowerSetActiveOverlayScheme(mode); } catch (EntryPointNotFoundException) { }
            }
            try {
                uint user = PowerSetUserConfiguredACPowerMode(ref mode);
                if (!onAc || result != 0) result = user;
            } catch (EntryPointNotFoundException) { }
            return result;
        }

        public class DisplayMode { public int Width; public int Height; public int Hz; }

        public class DisplayInfo {
            public string DeviceName; public string MonitorCode; public bool IsPrimary; public int Width; public int Height; public int Hz;
            public DisplayMode[] Modes;
        }

        static DEVMODE NewDevMode() {
            DEVMODE mode = new DEVMODE();
            mode.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
            return mode;
        }

        // Los recorridos van en C#: PowerShell no pasa bien estructuras por referencia a P/Invoke.
        public static DisplayInfo[] GetDisplays() {
            var result = new System.Collections.Generic.List<DisplayInfo>();
            for (uint i = 0; ; i++) {
                DISPLAY_DEVICE device = new DISPLAY_DEVICE();
                device.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
                if (!EnumDisplayDevices(null, i, ref device, 0)) break;
                if ((device.StateFlags & 0x1) == 0) continue;

                DEVMODE current = NewDevMode();
                if (!EnumDisplaySettings(device.DeviceName, -1, ref current)) continue;

                var modes = new System.Collections.Generic.List<DisplayMode>();
                DEVMODE mode = NewDevMode();
                for (int m = 0; EnumDisplaySettings(device.DeviceName, m, ref mode); m++) {
                    if (mode.dmBitsPerPel == 32) {
                        modes.Add(new DisplayMode { Width = mode.dmPelsWidth, Height = mode.dmPelsHeight, Hz = mode.dmDisplayFrequency });
                    }
                    mode = NewDevMode();
                }

                // Código del monitor (p. ej. BOE0A1B en MONITOR\BOE0A1B\{...}\0001), para cruzarlo con el EDID de WMI.
                string monitorCode = null;
                DISPLAY_DEVICE monitor = new DISPLAY_DEVICE();
                monitor.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
                if (EnumDisplayDevices(device.DeviceName, 0, ref monitor, 0) && monitor.DeviceID != null) {
                    string[] parts = monitor.DeviceID.Split('\\');
                    if (parts.Length > 1) monitorCode = parts[1];
                }

                result.Add(new DisplayInfo {
                    DeviceName = device.DeviceName, MonitorCode = monitorCode, IsPrimary = (device.StateFlags & 0x4) != 0,
                    Width = current.dmPelsWidth, Height = current.dmPelsHeight, Hz = current.dmDisplayFrequency,
                    Modes = modes.ToArray()
                });
            }
            return result.ToArray();
        }

        public static DisplayMode GetCurrentMode(string device) {
            DEVMODE mode = NewDevMode();
            if (!EnumDisplaySettings(device, -1, ref mode)) return null;
            return new DisplayMode { Width = mode.dmPelsWidth, Height = mode.dmPelsHeight, Hz = mode.dmDisplayFrequency };
        }

        // Primero prueba el modo (CDS_TEST) y después lo guarda (CDS_UPDATEREGISTRY). 0 = hecho.
        public static int ChangeMode(string device, int width, int height, int hz) {
            DEVMODE mode = NewDevMode();
            if (!EnumDisplaySettings(device, -1, ref mode)) return -1;
            mode.dmPelsWidth = width;
            mode.dmPelsHeight = height;
            mode.dmDisplayFrequency = hz;
            mode.dmFields = 0x80000 | 0x100000 | 0x400000;
            int test = ChangeDisplaySettingsEx(device, ref mode, IntPtr.Zero, 0x02, IntPtr.Zero);
            if (test != 0) return test;
            return ChangeDisplaySettingsEx(device, ref mode, IntPtr.Zero, 0x01, IntPtr.Zero);
        }

        public static string GetEffectiveOverlay() {
            try {
                Guid guid;
                return PowerGetEffectiveOverlayScheme(out guid) == 0 ? guid.ToString() : null;
            } catch (EntryPointNotFoundException) {
                return null;
            }
        }
    }
}
'@
    try {
        Add-Type -TypeDefinition $source -ErrorAction Stop
        $script:AfNativeReady = $true
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo compilar el código nativo: $($_.Exception.Message)"
        $script:AfNativeReady = $false
    }
    $script:AfNativeReady
}

function Get-AfDisplayModes {
    if (-not (Initialize-AfNative)) { return @() }
    foreach ($display in [Afina.Native]::GetDisplays()) {
        [pscustomobject]@{
            DeviceName = $display.DeviceName
            MonitorCode = $display.MonitorCode
            IsPrimary = $display.IsPrimary
            Width = $display.Width
            Height = $display.Height
            Hz = $display.Hz
            Modes = @($display.Modes | ForEach-Object { [pscustomobject]@{ Width = $_.Width; Height = $_.Height; Hz = $_.Hz } })
        }
    }
}

function Get-AfCurrentDisplayMode {
    param([Parameter(Mandatory)][string]$DeviceName)
    if (-not (Initialize-AfNative)) { return $null }
    $mode = [Afina.Native]::GetCurrentMode($DeviceName)
    if ($mode) { [pscustomobject]@{ Width = $mode.Width; Height = $mode.Height; Hz = $mode.Hz } }
}

function Invoke-AfDisplayModeChange {
    param([Parameter(Mandatory)][string]$DeviceName, [int]$Width, [int]$Height, [int]$Hz)
    if (-not (Initialize-AfNative)) { return -1 }
    [Afina.Native]::ChangeMode($DeviceName, $Width, $Height, $Hz)
}

function Test-AfOnAcPower {
    if (-not (Initialize-AfNative)) { return $true }
    [Afina.Native]::IsOnAcPower()
}

function Invoke-AfSetAcOverlay {
    param([Parameter(Mandatory)][string]$Guid)
    if (-not (Initialize-AfNative)) { return [uint32]4294967294 }
    [Afina.Native]::SetAcOverlay($Guid)
}

# Modo de energía con cargador. El registro da el de CA en concreto; la API, el de la fuente actual.
function Get-AfPowerOverlay {
    $value = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActiveOverlayAcPowerScheme'
    if ($value) { return ([string]$value).ToLowerInvariant() }
    if (-not (Initialize-AfNative)) { return $null }
    [Afina.Native]::GetEffectiveOverlay()
}

# Restaurar sistema: si está activo en el disco y si una política lo bloquea.
function Get-AfRestoreStatus {
    param([string]$Drive = $env:SystemDrive)
    $letter = $Drive.TrimEnd(':', '\').ToUpperInvariant()
    # Volúmenes protegidos: "\\?\Volume{…}\:(C%3A)".
    $clients = Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients' -Name '{09F7EDC5-294E-4180-AF6A-FB0E6A0E9513}'
    $enabled = @($clients | Where-Object { ([string]$_).ToUpperInvariant().Contains("($letter%3A)") }).Count -gt 0
    $policy = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'
    $disabled = (Get-AfRegistryValue -Path $policy -Name 'DisableSR') -eq 1
    $locked = (Get-AfRegistryValue -Path $policy -Name 'DisableConfig') -eq 1
    [pscustomobject]@{ Enabled = $enabled -and -not $disabled; Blocked = $disabled -or (-not $enabled -and $locked) }
}

function Enable-AfSystemRestore {
    param([string]$Drive = $env:SystemDrive)
    try {
        Enable-ComputerRestore -Drive ($Drive.TrimEnd('\') + '\') -ErrorAction Stop
        Write-AfLog -Level Info -Message "Restaurar sistema activado en $Drive."
        $true
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo activar Restaurar sistema: $($_.Exception.Message)"
        $false
    }
}

function New-AfRestorePoint {
    param([string]$Description = 'Afina', [string]$Drive = $env:SystemDrive)
    $letter = $Drive.TrimEnd(':', '\').ToUpperInvariant()
    if (-not (Get-AfRestoreStatus -Drive $Drive).Enabled) { return [pscustomobject]@{ Ok = $false; At = $null; Message = ((T 'Restaurar sistema está apagado en {0}:') -f $letter) } }
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
    $name = 'SystemRestorePointCreationFrequency'
    $previous = Get-AfRegistryValue -Path $key -Name $name
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        # Windows crea uno cada 24 h como máximo; con 0 se salta ese límite solo mientras se crea este.
        Set-ItemProperty -LiteralPath $key -Name $name -Value 0 -Type DWord -ErrorAction Stop
        $arguments = @{ Description = $Description; RestorePointType = [uint32]12; EventType = [uint32]100 }
        $result = Invoke-CimMethod -Namespace 'root/default' -ClassName 'SystemRestore' -MethodName 'CreateRestorePoint' -Arguments $arguments -OperationTimeoutSec 600 -ErrorAction Stop
        if ([int]$result.ReturnValue -ne 0) {
            Write-AfLog -Level Warn -Message "CreateRestorePoint: código $($result.ReturnValue)"
            return [pscustomobject]@{ Ok = $false; At = $null; Message = (T 'Windows no permitió crearlo') }
        }
        Write-AfLog -Level Info -Message ('Punto de restauración creado en {0:N1} s.' -f $watch.Elapsed.TotalSeconds)
        [pscustomobject]@{ Ok = $true; At = (Get-Date).ToString('o'); Message = $null }
    } catch {
        Write-AfLog -Level Warn -Message "Punto de restauración: $($_.Exception.Message)"
        $message = if ($watch.Elapsed.TotalSeconds -ge 590) { (T 'Windows no respondió a tiempo') } else { (T 'Windows no permitió crearlo') }
        [pscustomobject]@{ Ok = $false; At = $null; Message = $message }
    } finally {
        try {
            if ($null -eq $previous) { Remove-ItemProperty -LiteralPath $key -Name $name -ErrorAction Stop }
            else { Set-ItemProperty -LiteralPath $key -Name $name -Value $previous -Type DWord -ErrorAction Stop }
        } catch {
            Write-AfLog -Level Warn -Message "No se pudo dejar $name como estaba: $($_.Exception.Message)"
        }
    }
}

# Transacción de un cambio: cada pieza guarda el valor original antes de escribir (diseño, sección 11).
function New-AfTransaction {
    param($User, [scriptblock]$ConfirmDisplay, [scriptblock]$Progress)
    [pscustomobject]@{
        User = $User
        Records = New-Object System.Collections.ArrayList
        RestartAdapters = New-Object System.Collections.ArrayList
        Notes = New-Object System.Collections.ArrayList
        ConfirmDisplay = $ConfirmDisplay
        Progress = $Progress
        # $null: vale el NeedsReboot de la revisión; una pieza lo fija si depende de lo que pasó.
        NeedsReboot = $null
    }
}

# Texto de avance de un cambio largo (la fila lo muestra mientras aplica). Nunca corta el cambio.
function Set-AfTxProgress {
    param([Parameter(Mandatory)]$Tx, [string]$Text)
    if (-not $Tx.Progress) { return }
    try { & $Tx.Progress $Text } catch { Write-AfLog -Level Warn -Message "No se pudo mostrar el avance: $($_.Exception.Message)" }
}

function Add-AfTxRecord {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][hashtable]$Record)
    if (-not $Record.Kind) { throw (T 'El registro del cambio necesita Kind.') }
    [void]$Tx.Records.Add([pscustomobject]$Record)
}

# Error con un motivo que se puede mostrar en la fila. Uso: throw (New-AfApplyError -Reason '…').
function New-AfApplyError {
    param([Parameter(Mandatory)][string]$Reason, [switch]$Reverted)
    $exception = New-Object System.Exception($Reason)
    $exception.Data['AfReason'] = $Reason
    $exception.Data['AfReverted'] = [bool]$Reverted
    $exception
}

function Get-AfErrorData {
    param($ErrorRecord, [string]$Key)
    $exception = $ErrorRecord.Exception
    while ($exception) {
        if ($exception.Data -and $exception.Data.Contains($Key)) { return $exception.Data[$Key] }
        $exception = $exception.InnerException
    }
    $null
}

function Get-AfApplyReason {
    param([Parameter(Mandatory)]$ErrorRecord)
    $reason = Get-AfErrorData -ErrorRecord $ErrorRecord -Key 'AfReason'
    if ($reason) { [string]$reason } else { (T 'Windows no aceptó el cambio') }
}

function Test-AfRevertError {
    param([Parameter(Mandatory)]$ErrorRecord)
    [bool](Get-AfErrorData -ErrorRecord $ErrorRecord -Key 'AfReverted')
}

# Usuario de una sesión guardada: si no es el del proceso, su HKCU es HKEY_USERS\<SID>.
function Get-AfUserForSid {
    param([string]$Sid)
    $current = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    if (-not $Sid) { $Sid = $current }
    $same = $Sid -eq $current
    [pscustomobject]@{ Sid = $Sid; IsSameAsProcess = $same; HkcuRoot = if ($same) { 'HKCU:' } else { "Registry::HKEY_USERS\$Sid" } }
}

# Texto estable para comparar valores que vienen del sistema o de un JSON (claves ordenadas, números normalizados).
function ConvertTo-AfComparable {
    param($Value)
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return 's:' + $Value }
    if ($Value -is [bool]) { return 'b:' + $Value }
    if ($Value -is [System.Collections.IDictionary]) {
        $keys = @($Value.Keys | ForEach-Object { [string]$_ } | Sort-Object)
        return '{' + (($keys | ForEach-Object { $_ + '=' + (ConvertTo-AfComparable $Value[$_]) }) -join ',') + '}'
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $names = @($Value.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
        return '{' + (($names | ForEach-Object { $_ + '=' + (ConvertTo-AfComparable $Value.$_) }) -join ',') + '}'
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return '[' + ((@($Value) | ForEach-Object { ConvertTo-AfComparable $_ }) -join ',') + ']'
    }
    if ($Value -is [ValueType] -and $Value -isnot [char] -and $Value -isnot [datetime] -and $Value -isnot [guid]) {
        try { return 'n:' + ([decimal]$Value).ToString([System.Globalization.CultureInfo]::InvariantCulture) } catch { }
    }
    'o:' + [string]$Value
}

function Undo-AfRecord {
    param([Parameter(Mandatory)]$Record, $User)
    $command = 'Restore-Af{0}' -f $Record.Kind
    if (-not (Get-Command -Name $command -CommandType Function -ErrorAction SilentlyContinue)) { throw (New-AfApplyError -Reason (T 'Afina no sabe deshacer este cambio')) }
    & $command -Record $Record -User $User
}

# Deshace al revés. Sigue si uno falla y devuelve los que quedaron sin deshacer.
function Undo-AfRecords {
    param([object[]]$Records = @(), $User)
    $failed = New-Object System.Collections.ArrayList
    $adapters = New-Object System.Collections.ArrayList
    $reason = $null
    for ($i = $Records.Count - 1; $i -ge 0; $i--) {
        $record = $Records[$i]
        if ($record.Kind -eq 'Action') { continue }
        try {
            Undo-AfRecord -Record $record -User $User
            if ($record.Kind -eq 'NetAdapterProperty' -and $record.InterfaceGuid -and -not $adapters.Contains([string]$record.InterfaceGuid)) { [void]$adapters.Add([string]$record.InterfaceGuid) }
        } catch {
            Write-AfLog -Level Warn -Message ('No se pudo deshacer {0} {1}: {2}' -f $record.Kind, $record.Name, $_.Exception.Message)
            if (-not $reason) { $reason = Get-AfApplyReason -ErrorRecord $_ }
            [void]$failed.Insert(0, $record)
        }
    }
    if ($adapters.Count) { Restart-AfAdapters -InterfaceGuid @($adapters) }
    [pscustomobject]@{ Failed = @($failed); Reason = $reason }
}

function Get-AfRecordState {
    param([Parameter(Mandatory)]$Record, $User)
    & ('Get-Af{0}State' -f $Record.Kind) -Record $Record -User $User
}

function Test-AfRecordRestored {
    param([Parameter(Mandatory)]$Record, $User)
    if ($Record.Kind -eq 'Action') { return $true }
    (ConvertTo-AfComparable (Get-AfRecordState -Record $Record -User $User)) -eq (ConvertTo-AfComparable $Record.Previous)
}

function Complete-AfTransaction {
    param([Parameter(Mandatory)]$Tx)
    if ($Tx.RestartAdapters.Count) { Restart-AfAdapters -InterfaceGuid @($Tx.RestartAdapters) }
}

function Get-AfRegistryState {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Name, $User)
    $resolved = Resolve-AfRegistryPath -Path $Path -User $User
    $key = $null
    try { $key = Get-Item -LiteralPath $resolved -ErrorAction Stop } catch { }
    if (-not $key) { return [pscustomobject]@{ KeyExists = $false; Exists = $false; Type = $null; Value = $null } }
    try {
        if (@($key.GetValueNames()) -notcontains $Name) { return [pscustomobject]@{ KeyExists = $true; Exists = $false; Type = $null; Value = $null } }
        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        [pscustomobject]@{ KeyExists = $true; Exists = $true; Type = [string]$key.GetValueKind($Name); Value = $value }
    } finally {
        $key.Close()
    }
}

# Convierte un valor (también uno leído de JSON) al tipo .NET que espera el registro.
function ConvertTo-AfRegistryData {
    param([string]$Type, $Value)
    switch ($Type) {
        'DWord' { [int]$Value }
        'QWord' { [long]$Value }
        'Binary' { , [byte[]]@($Value) }
        'MultiString' { , [string[]]@($Value) }
        default { [string]$Value }
    }
}

function Set-AfRegistryValue {
    param(
        [Parameter(Mandatory)]$Tx,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DWord', 'QWord', 'String', 'ExpandString', 'MultiString', 'Binary')][string]$Type,
        [Parameter(Mandatory)][AllowEmptyString()][AllowEmptyCollection()]$Value
    )
    $before = Get-AfRegistryState -Path $Path -Name $Name -User $Tx.User
    $target = ConvertTo-AfRegistryData -Type $Type -Value $Value
    if ($before.Exists -and $before.Type -eq $Type -and (ConvertTo-AfComparable $before.Value) -eq (ConvertTo-AfComparable $target)) { return $false }
    $resolved = Resolve-AfRegistryPath -Path $Path -User $Tx.User
    try {
        if (-not $before.KeyExists) { New-Item -Path $resolved -Force -ErrorAction Stop | Out-Null }
        New-ItemProperty -LiteralPath $resolved -Name $Name -PropertyType $Type -Value $target -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-AfLog -Level Warn -Message "Registro $resolved\$Name`: $($_.Exception.Message)"
        if (-not $before.KeyExists) { Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue }
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'RegistryValue'; Path = $Path; Name = $Name; KeyExisted = $before.KeyExists
        Previous = [pscustomobject]@{ Exists = $before.Exists; Type = $before.Type; Value = $before.Value }
        New = [pscustomobject]@{ Exists = $true; Type = $Type; Value = $target }
    }
    $true
}

function Restore-AfRegistryValue {
    param([Parameter(Mandatory)]$Record, $User)
    $resolved = Resolve-AfRegistryPath -Path $Record.Path -User $User
    $previous = $Record.Previous
    try {
        if ($previous.Exists) {
            if (-not (Test-Path -LiteralPath $resolved)) { New-Item -Path $resolved -Force -ErrorAction Stop | Out-Null }
            New-ItemProperty -LiteralPath $resolved -Name $Record.Name -PropertyType $previous.Type -Value (ConvertTo-AfRegistryData -Type $previous.Type -Value $previous.Value) -Force -ErrorAction Stop | Out-Null
            return
        }
        $state = Get-AfRegistryState -Path $Record.Path -Name $Record.Name -User $User
        if ($state.Exists) { Remove-ItemProperty -LiteralPath $resolved -Name $Record.Name -Force -ErrorAction Stop }
        if (-not $Record.KeyExisted -and $state.KeyExists) {
            $key = Get-Item -LiteralPath $resolved -ErrorAction Stop
            $empty = $key.SubKeyCount -eq 0 -and $key.ValueCount -eq 0
            $key.Close()
            if ($empty) { Remove-Item -LiteralPath $resolved -Force -ErrorAction Stop }
        }
    } catch {
        Write-AfLog -Level Warn -Message "Deshacer registro $resolved\$($Record.Name): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Windows no dejó escribir en el registro'))
    }
}

function Get-AfRegistryValueState {
    param([Parameter(Mandatory)]$Record, $User)
    $state = Get-AfRegistryState -Path $Record.Path -Name $Record.Name -User $User
    [pscustomobject]@{ Exists = $state.Exists; Type = $state.Type; Value = $state.Value }
}

function Get-AfActivePowerScheme {
    $value = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme'
    if ($value) { ([string]$value).ToLowerInvariant() } else { $null }
}

function Invoke-AfPowercfg {
    param([Parameter(Mandatory)][string]$Arguments)
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\powercfg.exe') -Arguments $Arguments -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) {
        Write-AfLog -Level Warn -Message ('powercfg {0}: código {1}. {2} {3}' -f $Arguments, $result.ExitCode, $result.Output, $result.Error)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el ajuste de energía'))
    }
    $result
}

function Set-AfActivePowerScheme {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Guid)
    $target = $Guid.ToLowerInvariant()
    $previous = Get-AfActivePowerScheme
    if ($previous -eq $target) { return $false }
    Invoke-AfPowercfg -Arguments "/setactive $target" | Out-Null
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerScheme'; Previous = $previous; New = $target }
    $true
}

function Restore-AfPowerScheme {
    param([Parameter(Mandatory)]$Record, $User)
    if ($Record.Previous) { Invoke-AfPowercfg -Arguments "/setactive $($Record.Previous)" | Out-Null }
}

function Get-AfPowerSchemeState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfActivePowerScheme
}

function Get-AfPowerSettingAc {
    param([string]$Scheme, [string]$Subgroup, [string]$Setting)
    $result = Invoke-AfPowercfg -Arguments "/q $Scheme $Subgroup $Setting"
    $values = ConvertFrom-AfPowercfgQuery -Text $result.Output
    if (-not $values) { throw (New-AfApplyError -Reason (T 'Windows no mostró ese ajuste de energía')) }
    [int]$values.Ac
}

# Ajuste del plan activo con cargador (CA). La batería queda como estaba.
function Set-AfPowerSetting {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Subgroup, [Parameter(Mandatory)][string]$Setting, [Parameter(Mandatory)][int]$Ac)
    $scheme = Get-AfActivePowerScheme
    if (-not $scheme) { throw (New-AfApplyError -Reason (T 'no se encontró el plan de energía activo')) }
    $previous = Get-AfPowerSettingAc -Scheme $scheme -Subgroup $Subgroup -Setting $Setting
    if ($previous -eq $Ac) { return $false }
    Invoke-AfPowercfg -Arguments "/setacvalueindex $scheme $Subgroup $Setting $Ac" | Out-Null
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerSetting'; Scheme = $scheme; Subgroup = $Subgroup; Setting = $Setting; Previous = $previous; New = $Ac }
    Invoke-AfPowercfg -Arguments "/setactive $scheme" | Out-Null
    $true
}

function Restore-AfPowerSetting {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfPowercfg -Arguments ('/setacvalueindex {0} {1} {2} {3}' -f $Record.Scheme, $Record.Subgroup, $Record.Setting, $Record.Previous) | Out-Null
    if ((Get-AfActivePowerScheme) -eq $Record.Scheme) { Invoke-AfPowercfg -Arguments "/setactive $($Record.Scheme)" | Out-Null }
}

function Get-AfPowerSettingState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfPowerSettingAc -Scheme $Record.Scheme -Subgroup $Record.Subgroup -Setting $Record.Setting
}

function Get-AfCurrentOverlay {
    $value = Get-AfPowerOverlay
    if ($value) { ([string]$value).ToLowerInvariant() } else { '00000000-0000-0000-0000-000000000000' }
}

function Invoke-AfOverlayChange {
    param([Parameter(Mandatory)][string]$Guid)
    $code = [uint32](Invoke-AfSetAcOverlay -Guid $Guid)
    if ($code -eq 4294967295) { throw (New-AfApplyError -Reason (T 'conecta el cargador y vuelve a aplicar')) }
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Modo de energía {0}: código {1}' -f $Guid, $code)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo de energía'))
    }
}

# Modo de energía con cargador (superposición de CA del plan Equilibrado).
function Set-AfPowerOverlay {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Guid)
    $target = $Guid.ToLowerInvariant()
    $previous = Get-AfCurrentOverlay
    if ($previous -eq $target) { return $false }
    Invoke-AfOverlayChange -Guid $target
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'PowerOverlay'; Previous = $previous; New = $target }
    # Se verifica con la misma lectura que usa el análisis; si no cambió, el motor lo revierte.
    if ((Get-AfCurrentOverlay) -ne $target) { throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo de energía')) }
    $true
}

function Restore-AfPowerOverlay {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfOverlayChange -Guid $Record.Previous
}

function Get-AfPowerOverlayState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfCurrentOverlay
}

function Set-AfDisplayMode {
    param(
        [Parameter(Mandatory)]$Tx,
        [Parameter(Mandatory)][string]$DeviceName,
        [string]$Label = 'Pantalla',
        [Parameter(Mandatory)][int]$Width,
        [Parameter(Mandatory)][int]$Height,
        [Parameter(Mandatory)][int]$Hz
    )
    $current = Get-AfCurrentDisplayMode -DeviceName $DeviceName
    if (-not $current) { throw (New-AfApplyError -Reason (T 'no se encontró esa pantalla')) }
    if ($current.Width -eq $Width -and $current.Height -eq $Height -and $current.Hz -eq $Hz) { return $false }
    $code = Invoke-AfDisplayModeChange -DeviceName $DeviceName -Width $Width -Height $Height -Hz $Hz
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Pantalla {0} a {1}x{2}@{3}: código {4}' -f $DeviceName, $Width, $Height, $Hz, $code)
        throw (New-AfApplyError -Reason ((T 'Windows no aceptó {0} Hz en esa pantalla') -f $Hz))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'DisplayMode'; DeviceName = $DeviceName; Label = $Label
        Previous = [pscustomobject]@{ Width = $current.Width; Height = $current.Height; Hz = $current.Hz }
        New = [pscustomobject]@{ Width = $Width; Height = $Height; Hz = $Hz }
    }
    $true
}

# Como Windows: pregunta si se ve bien. Sin un "keep" lanza y el motor vuelve al modo anterior.
function Confirm-AfDisplayChange {
    param([Parameter(Mandatory)]$Tx)
    $records = @($Tx.Records | Where-Object { $_.Kind -eq 'DisplayMode' })
    if (-not $records.Count -or -not $Tx.ConfirmDisplay) { return }
    $answer = & $Tx.ConfirmDisplay $records
    if ($answer -eq 'keep') { return }
    $hz = $records[0].Previous.Hz
    $reason = if ($answer -eq 'revert') { (T 'Se volvió a {0} Hz') -f $hz } else { (T 'Se volvió a {0} Hz porque nadie confirmó la pantalla') -f $hz }
    throw (New-AfApplyError -Reason $reason -Reverted)
}

function Restore-AfDisplayMode {
    param([Parameter(Mandatory)]$Record, $User)
    $previous = $Record.Previous
    $code = Invoke-AfDisplayModeChange -DeviceName $Record.DeviceName -Width $previous.Width -Height $previous.Height -Hz $previous.Hz
    if ($code -ne 0) {
        Write-AfLog -Level Warn -Message ('Deshacer pantalla {0}: código {1}' -f $Record.DeviceName, $code)
        throw (New-AfApplyError -Reason (T 'Windows no aceptó el modo anterior de la pantalla'))
    }
}

function Get-AfDisplayModeState {
    param([Parameter(Mandatory)]$Record, $User)
    $mode = Get-AfCurrentDisplayMode -DeviceName $Record.DeviceName
    if ($mode) { [pscustomobject]@{ Width = $mode.Width; Height = $mode.Height; Hz = $mode.Hz } }
}

function Get-AfAdapterByGuid {
    param([string]$InterfaceGuid)
    @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { [string]$_.InterfaceGuid -eq $InterfaceGuid })[0]
}

# Cambia una propiedad avanzada sin reiniciar el adaptador; Complete-AfTransaction lo reinicia una sola vez al final.
function Set-AfNetAdapterProperty {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Adapter, [Parameter(Mandatory)][string]$Keyword, [Parameter(Mandatory)][string]$Value)
    $reason = (T 'el adaptador {0} no respondió') -f $Adapter
    try {
        $nic = Get-NetAdapter -Name $Adapter -ErrorAction Stop
        $property = Get-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Adaptador $Adapter ($Keyword): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason $reason)
    }
    $previous = [string](@($property.RegistryValue)[0])
    if ($previous -eq $Value) { return $false }
    try {
        Set-NetAdapterAdvancedProperty -Name $Adapter -RegistryKeyword $Keyword -RegistryValue $Value -NoRestart -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Adaptador $Adapter ($Keyword = $Value): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason $reason)
    }
    $guid = [string]$nic.InterfaceGuid
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'NetAdapterProperty'; InterfaceGuid = $guid; Adapter = $Adapter; Keyword = $Keyword; Previous = $previous; New = $Value }
    if (-not $Tx.RestartAdapters.Contains($guid)) { [void]$Tx.RestartAdapters.Add($guid) }
    $true
}

# Un reinicio por adaptador (la conexión se corta unos segundos). Si falla, se anota y el cambio queda para el próximo reinicio.
function Restart-AfAdapters {
    param([string[]]$InterfaceGuid = @())
    foreach ($guid in @($InterfaceGuid | Select-Object -Unique)) {
        $nic = Get-AfAdapterByGuid -InterfaceGuid $guid
        if (-not $nic) { Write-AfLog -Level Warn -Message "No se encontró el adaptador $guid para reiniciarlo."; continue }
        try { Restart-NetAdapter -Name $nic.Name -Confirm:$false -ErrorAction Stop } catch { Write-AfLog -Level Warn -Message "No se pudo reiniciar $($nic.Name): $($_.Exception.Message)" }
    }
}

function Restore-AfNetAdapterProperty {
    param([Parameter(Mandatory)]$Record, $User)
    # Por InterfaceGuid: el adaptador pudo cambiar de nombre desde que se aplicó.
    $nic = Get-AfAdapterByGuid -InterfaceGuid $Record.InterfaceGuid
    if (-not $nic) { throw (New-AfApplyError -Reason ((T 'no se encontró el adaptador {0}') -f $Record.Adapter)) }
    try {
        Set-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword $Record.Keyword -RegistryValue ([string]$Record.Previous) -NoRestart -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message "Deshacer $($nic.Name) ($($Record.Keyword)): $($_.Exception.Message)"
        throw (New-AfApplyError -Reason ((T 'el adaptador {0} no respondió') -f $nic.Name))
    }
}

function Get-AfNetAdapterPropertyState {
    param([Parameter(Mandatory)]$Record, $User)
    $nic = Get-AfAdapterByGuid -InterfaceGuid $Record.InterfaceGuid
    if (-not $nic) { return $null }
    [string](@((Get-NetAdapterAdvancedProperty -Name $nic.Name -RegistryKeyword $Record.Keyword -ErrorAction SilentlyContinue).RegistryValue)[0])
}

function Get-AfMpPreferenceValue {
    param([Parameter(Mandatory)][string]$Name)
    try { (Get-MpPreference -ErrorAction Stop).$Name } catch {
        Write-AfLog -Level Warn -Message "Get-MpPreference: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Microsoft Defender no respondió'))
    }
}

function Invoke-AfMpPreference {
    param([Parameter(Mandatory)][string]$Name, $Value)
    $arguments = @{ $Name = $Value; ErrorAction = 'Stop' }
    try { Set-MpPreference @arguments } catch {
        Write-AfLog -Level Warn -Message "Set-MpPreference ${Name}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'Microsoft Defender no aceptó el cambio'))
    }
}

function Set-AfMpPreference {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Value)
    $previous = Get-AfMpPreferenceValue -Name $Name
    if ((ConvertTo-AfComparable $previous) -eq (ConvertTo-AfComparable $Value)) { return $false }
    Invoke-AfMpPreference -Name $Name -Value $Value
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'MpPreference'; Name = $Name; Previous = $previous; New = $Value }
    $true
}

function Restore-AfMpPreference {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfMpPreference -Name $Record.Name -Value $Record.Previous
}

function Get-AfMpPreferenceState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfMpPreferenceValue -Name $Record.Name
}

# Con la protección contra alteraciones, Set-MpPreference no falla pero tampoco cambia nada: se comprueba.
function Enable-AfDefenderRealtime {
    param([Parameter(Mandatory)]$Tx, [int]$WaitSeconds = 5)
    Set-AfMpPreference -Tx $Tx -Name 'DisableRealtimeMonitoring' -Value $false | Out-Null
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    do {
        try { if ((Get-MpComputerStatus -ErrorAction Stop).RealTimeProtectionEnabled) { return } } catch { }
        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $deadline)
    throw (New-AfApplyError -Reason (T 'la protección contra alteraciones no dejó encenderla; actívala en Seguridad de Windows, Protección contra virus y amenazas'))
}

function Update-AfDefenderSignatures {
    param([Parameter(Mandatory)]$Tx)
    $tool = Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe'
    $ok = $true
    if (Test-Path -LiteralPath $tool) {
        $result = Invoke-AfProcess -FilePath $tool -Arguments '-SignatureUpdate' -TimeoutMs 300000
        $ok = -not $result.TimedOut -and $result.ExitCode -eq 0
        if (-not $ok) { Write-AfLog -Level Warn -Message ('MpCmdRun -SignatureUpdate: código {0}. {1}' -f $result.ExitCode, $result.Output) }
    } else {
        try { Update-MpSignature -ErrorAction Stop } catch { $ok = $false; Write-AfLog -Level Warn -Message "Update-MpSignature: $($_.Exception.Message)" }
    }
    if (-not $ok) { throw (New-AfApplyError -Reason (T 'no se pudieron descargar las firmas; revisa la conexión a internet')) }
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Firmas'; Detail = (T 'Firmas al día') }
    [void]$Tx.Notes.Add((T 'Firmas al día.'))
}

function Get-AfFirewallProfileEnabled {
    param([Parameter(Mandatory)][string]$Profile)
    try { [string](Get-NetFirewallProfile -Name $Profile -ErrorAction Stop).Enabled } catch {
        Write-AfLog -Level Warn -Message "Get-NetFirewallProfile ${Profile}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'el Firewall de Windows no respondió'))
    }
}

function Invoke-AfFirewallProfile {
    param([Parameter(Mandatory)][string]$Profile, [Parameter(Mandatory)][string]$Enabled)
    try { Set-NetFirewallProfile -Name $Profile -Enabled $Enabled -ErrorAction Stop } catch {
        Write-AfLog -Level Warn -Message "Set-NetFirewallProfile $Profile ${Enabled}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'el Firewall de Windows no aceptó el cambio'))
    }
}

function Set-AfFirewallProfile {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Profile, [Parameter(Mandatory)][bool]$Enabled)
    $previous = Get-AfFirewallProfileEnabled -Profile $Profile
    $target = if ($Enabled) { 'True' } else { 'False' }
    if ($previous -eq $target) { return $false }
    Invoke-AfFirewallProfile -Profile $Profile -Enabled $target
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'FirewallProfile'; Profile = $Profile; Previous = $previous; New = $target }
    $true
}

function Restore-AfFirewallProfile {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfFirewallProfile -Profile $Record.Profile -Enabled ([string]$Record.Previous)
}

function Get-AfFirewallProfileState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfFirewallProfileEnabled -Profile $Record.Profile
}

function Get-AfTrimEnabled {
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\fsutil.exe') -Arguments 'behavior query DisableDeleteNotify' -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) { throw (New-AfApplyError -Reason (T 'fsutil no respondió')) }
    -not (ConvertFrom-AfFsutilTrim -Text $result.Output).NtfsDisabled
}

function Invoke-AfTrimChange {
    param([bool]$Enabled)
    $flag = if ($Enabled) { 0 } else { 1 }
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\fsutil.exe') -Arguments "behavior set DisableDeleteNotify NTFS $flag" -TimeoutMs 15000
    if ($result.TimedOut -or $result.ExitCode -ne 0) {
        Write-AfLog -Level Warn -Message ('fsutil DisableDeleteNotify {0}: código {1}. {2}' -f $flag, $result.ExitCode, $result.Output)
        throw (New-AfApplyError -Reason (T 'fsutil no aceptó el cambio'))
    }
}

function Set-AfTrim {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][bool]$Enabled)
    $previous = Get-AfTrimEnabled
    if ($previous -eq $Enabled) { return $false }
    Invoke-AfTrimChange -Enabled $Enabled
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Trim'; Previous = $previous; New = $Enabled }
    $true
}

function Restore-AfTrim {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfTrimChange -Enabled ([bool]$Record.Previous)
}

function Get-AfTrimState {
    param([Parameter(Mandatory)]$Record, $User)
    Get-AfTrimEnabled
}

# Carpetas de temporales (las mismas que mide el inventario). En Temp solo se borra lo que tiene más de 24 h.
function Get-AfTempFolders {
    param($Inventory)
    $profilePath = if ($Inventory -and $Inventory.User -and $Inventory.User.ProfilePath) { $Inventory.User.ProfilePath } else { $env:USERPROFILE }
    $wer = Join-Path $env:ProgramData 'Microsoft\Windows\WER'
    @(
        [pscustomobject]@{ Path = Join-Path $profilePath 'AppData\Local\Temp'; MinAgeHours = 24 }
        [pscustomobject]@{ Path = Join-Path $env:windir 'Temp'; MinAgeHours = 24 }
        [pscustomobject]@{ Path = Join-Path $env:windir 'SoftwareDistribution\Download'; MinAgeHours = 0 }
        [pscustomobject]@{ Path = Join-Path $wer 'ReportArchive'; MinAgeHours = 0 }
        [pscustomobject]@{ Path = Join-Path $wer 'ReportQueue'; MinAgeHours = 0 }
    )
}

# Borra el contenido de una carpeta sin seguir uniones ni enlaces y salta lo que esté en uso. Devuelve los bytes liberados.
function Remove-AfFolderContent {
    param([Parameter(Mandatory)][string]$Path, [int]$MinAgeHours = 0)
    if (-not [System.IO.Directory]::Exists($Path)) { return [long]0 }
    $limit = (Get-Date).AddHours(-$MinAgeHours)
    $freed = [long]0
    $folders = New-Object System.Collections.Generic.List[string]
    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push($Path)
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        $files = @()
        try { $files = [System.IO.Directory]::GetFiles($dir) } catch { }
        foreach ($file in $files) {
            try {
                $info = New-Object System.IO.FileInfo($file)
                if (($info.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
                if ($MinAgeHours -gt 0 -and $info.LastWriteTime -gt $limit) { continue }
                $length = $info.Length
                if ($info.IsReadOnly) { $info.IsReadOnly = $false }
                $info.Delete()
                $freed += $length
            } catch { }
        }
        $subs = @()
        try { $subs = [System.IO.Directory]::GetDirectories($dir) } catch { }
        foreach ($sub in $subs) {
            try { if (([System.IO.File]::GetAttributes($sub) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue } } catch { continue }
            $folders.Add($sub)
            $pending.Push($sub)
        }
    }
    # Las carpetas que quedaron vacías, de la más profunda a la menos (Delete sin recursión falla si no está vacía).
    foreach ($dir in @($folders | Sort-Object -Property Length -Descending)) {
        try { [System.IO.Directory]::Delete($dir) } catch { }
    }
    $freed
}

function Clear-AfDeliveryOptimizationCache {
    $path = Join-Path $env:windir 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'
    if (-not (Get-Command -Name 'Delete-DeliveryOptimizationCache' -ErrorAction SilentlyContinue)) { return [long]0 }
    $before = Get-AfFolderBytes -Path $path
    try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop } catch { Write-AfLog -Level Warn -Message "Optimización de distribución: $($_.Exception.Message)" }
    [math]::Max([long]0, $before - (Get-AfFolderBytes -Path $path))
}

# Sin deshacer: queda un registro Action con lo liberado.
function Clear-AfTempFiles {
    param([Parameter(Mandatory)]$Tx, $Inventory)
    $freed = [long]0
    foreach ($folder in Get-AfTempFolders -Inventory $Inventory) { $freed += Remove-AfFolderContent -Path $folder.Path -MinAgeHours $folder.MinAgeHours }
    $freed += Clear-AfDeliveryOptimizationCache
    $detail = (T 'Se liberaron {0}') -f (Format-AfSize -Bytes $freed)
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Temporales'; Detail = $detail; FreedBytes = $freed }
    [void]$Tx.Notes.Add($detail + '.')
}

# Igual que el Administrador de tareas: StartupApproved = 03 00 00 00 + FILETIME UTC de cuándo se desactivó.
function Get-AfStartupDisabledBytes {
    param([datetime]$Time = (Get-Date))
    $bytes = New-Object byte[] 12
    $bytes[0] = 3
    [System.BitConverter]::GetBytes($Time.ToFileTimeUtc()).CopyTo($bytes, 4)
    , $bytes
}

function Disable-AfStartupEntry {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)]$Entry)
    if (-not $Entry.ApprovedKey -or -not $Entry.ApprovedName) { throw (New-AfApplyError -Reason ((T 'no se encontró dónde desactivar {0}') -f $Entry.Name)) }
    $state = Get-AfRegistryState -Path $Entry.ApprovedKey -Name $Entry.ApprovedName -User $Tx.User
    # Primer byte impar = ya desactivado: no se reescribe la fecha.
    if ($state.Exists -and $state.Type -eq 'Binary' -and @($state.Value).Count -gt 0 -and ([int]@($state.Value)[0] -band 1) -eq 1) { return $false }
    Set-AfRegistryValue -Tx $Tx -Path $Entry.ApprovedKey -Name $Entry.ApprovedName -Type Binary -Value (Get-AfStartupDisabledBytes)
}

# Windows Update por su API COM, en un trabajo aislado: si un paso se traba, Afina deja de esperarlo (Core\Jobs.ps1).
# BrowseOnly=0: solo las que Windows no considera opcionales, o sea las que instalaría solo.
$script:AfUpdateCriteria = "IsInstalled=0 and IsHidden=0 and Type='Software' and BrowseOnly=0"

# Corre en otro runspace: no usa funciones de Afina. Anota en $Sync lo que va haciendo (Found, Results, Stage, Beat).
$script:AfWindowsUpdateJob = @'
param($Sync, [string]$Mode, [string]$Criteria)
# Cualquier falla corta el trabajo (sin esto, una llamada COM que falla solo corta su línea y la búsqueda diría "Al día").
$ErrorActionPreference = 'Stop'
# Clasificación Upgrades (versiones nuevas de Windows): no se instalan desde Afina.
$upgrades = '3689bdc8-b205-4af4-8d4a-a63924c5e9d5'
$Sync.Results = @()
# Textos del avance: llegan traducidos desde afuera (aquí no hay funciones de Afina).
$texts = if ($Sync.Texts) { $Sync.Texts } else { @{ Search = 'Buscando actualizaciones'; Download = 'Descargando {0} de {1}'; Install = 'Instalando {0} de {1}' } }
$Sync.Stage = $texts.Search
$Sync.Beat = [datetime]::UtcNow
$session = New-Object -ComObject Microsoft.Update.Session
$session.ClientApplicationID = 'Afina'
$found = $session.CreateUpdateSearcher().Search($Criteria).Updates
$updates = @()
for ($i = 0; $i -lt $found.Count; $i++) {
    $update = $found.Item($i)
    $isUpgrade = $false
    foreach ($category in $update.Categories) { if ([string]$category.CategoryID -eq $upgrades) { $isUpgrade = $true } }
    if (-not $isUpgrade -and -not $update.InstallationBehavior.CanRequestUserInput) { $updates += $update }
}
$Sync.Found = $updates.Count
if ($Mode -eq 'Search') { return @{ Titles = @($updates | ForEach-Object { [string]$_.Title }) } }
for ($i = 0; $i -lt $updates.Count; $i++) {
    $update = $updates[$i]
    $one = New-Object -ComObject Microsoft.Update.UpdateColl
    if (-not $update.EulaAccepted) { $update.AcceptEula() }
    [void]$one.Add($update)
    $entry = @{ Title = [string]$update.Title; Ok = $false; HResult = 0; RebootRequired = $false }
    if (-not $update.IsDownloaded) {
        $Sync.Stage = $texts.Download -f ($i + 1), $updates.Count
        $Sync.Beat = [datetime]::UtcNow
        $downloader = $session.CreateUpdateDownloader()
        $downloader.Updates = $one
        $download = $downloader.Download()
        # ResultCode 2 = bien, 3 = bien con errores.
        if ($download.ResultCode -notin 2, 3) {
            $entry.HResult = [int]$download.HResult
            $Sync.Results = @($Sync.Results) + @($entry)
            continue
        }
    }
    $Sync.Stage = $texts.Install -f ($i + 1), $updates.Count
    $Sync.Beat = [datetime]::UtcNow
    $installer = $session.CreateUpdateInstaller()
    $installer.AllowSourcePrompts = $false
    $installer.Updates = $one
    $install = $installer.Install()
    $entry.Ok = $install.ResultCode -in 2, 3
    $entry.HResult = [int]$install.HResult
    $entry.RebootRequired = [bool]$install.RebootRequired
    $Sync.Results = @($Sync.Results) + @($entry)
}
'@

function ConvertTo-AfUpdateReason {
    param($HResult)
    if (-not $HResult) { return (T 'Windows Update no respondió como se esperaba') }
    $code = [int64]$HResult -band 0xFFFFFFFFL
    switch ($code) {
        0x80070422L { return (T 'el servicio de Windows Update está desactivado') }
        { $_ -in 0x8024402CL, 0x80072EE2L, 0x80072EE7L, 0x80072EFDL } { return (T 'no hay conexión con Windows Update') }
        0x80072F8FL { return (T 'no se pudo abrir una conexión segura con Windows Update') }
        0x80240016L { return (T 'Windows Update está instalando otra cosa o espera un reinicio') }
        0x8024001EL { return (T 'Windows Update se detuvo') }
    }
    (T 'Windows Update devolvió el código 0x{0:X8}') -f $code
}

# Lento (de segundos a minutos): lo usa la búsqueda en segundo plano del análisis.
function Find-AfWindowsUpdates {
    param([string]$Script = $script:AfWindowsUpdateJob, [int]$StallSeconds = 300)
    $job = Invoke-AfIsolatedJob -Script $Script -Parameters @{ Mode = 'Search'; Criteria = $script:AfUpdateCriteria } -StallSeconds $StallSeconds
    $none = [pscustomobject]@{ Count = 0; Titles = @(); TimedOut = [bool]$job.TimedOut; Reason = $null }
    if ($job.TimedOut) { $none.Reason = (T 'Windows Update no respondió a tiempo'); return $none }
    if ($job.Error) { $none.Reason = ConvertTo-AfUpdateReason -HResult $job.HResult; return $none }
    $titles = @($job.Result.Titles | Where-Object { $_ })
    [pscustomobject]@{ Count = $titles.Count; Titles = $titles; TimedOut = $false; Reason = $null }
}

# Sin deshacer: queda un registro Action con lo instalado. Si un paso se traba, lo ya instalado queda anotado.
function Install-AfWindowsUpdates {
    param([Parameter(Mandatory)]$Tx, [string]$Script = $script:AfWindowsUpdateJob, [int]$StallSeconds = 3600)
    # El avance va directo: un closure (GetNewClosure) no encuentra las funciones de Afina fuera del ámbito global.
    $texts = @{ Search = (T 'Buscando actualizaciones'); Download = (T 'Descargando {0} de {1}'); Install = (T 'Instalando {0} de {1}') }
    $job = Invoke-AfIsolatedJob -Script $Script -Parameters @{ Mode = 'Install'; Criteria = $script:AfUpdateCriteria } -State @{ Texts = $texts } -StallSeconds $StallSeconds -OnStage $Tx.Progress
    $results = @($job.Sync.Results | Where-Object { $_ })
    $found = $job.Sync.Found
    if ($job.Done -and -not $job.Error -and $found -eq 0) {
        $Tx.NeedsReboot = $false
        [void]$Tx.Notes.Add((T 'Ya estaba al día.'))
        return $false
    }
    $ok = @($results | Where-Object { $_.Ok })
    $failed = @($results | Where-Object { -not $_.Ok })
    if (-not $ok.Count) {
        $reason = if ($failed.Count) { ConvertTo-AfUpdateReason -HResult $failed[0].HResult } elseif ($job.TimedOut) { (T 'Windows Update dejó de responder') } else { ConvertTo-AfUpdateReason -HResult $job.HResult }
        throw (New-AfApplyError -Reason $reason)
    }
    $total = if ($found) { [int]$found } else { $results.Count }
    $detail = (T 'Se instalaron {0} de {1}') -f $ok.Count, $total
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'Action'; Name = (T 'Actualizaciones de Windows'); Detail = $detail
        Installed = @($ok | ForEach-Object { $_.Title }); Failed = @($failed | ForEach-Object { $_.Title })
    }
    [void]$Tx.Notes.Add($detail + '.')
    if ($failed.Count) { [void]$Tx.Notes.Add((T 'No se pudieron: {0}.') -f (@($failed | ForEach-Object { $_.Title }) -join ', ')) }
    if ($job.TimedOut) { [void]$Tx.Notes.Add((T 'Windows Update dejó de responder; lo que falta sigue en Configuración.')) }
    elseif ($job.Error) { [void]$Tx.Notes.Add((T 'Windows Update se detuvo ({0}); lo que falta sigue en Configuración.') -f (ConvertTo-AfUpdateReason -HResult $job.HResult)) }
    $Tx.NeedsReboot = [bool]@($ok | Where-Object { $_.RebootRequired }).Count
    $true
}

# Códigos de salida de winget (tabla oficial: winget-cli, doc\windows\package-manager\winget\returnCodes.md).
function Get-AfWingetOutcome {
    param([int]$ExitCode)
    $outcome = { param($Ok, $Reboot, $Reason) [pscustomobject]@{ Ok = $Ok; Reboot = $Reboot; Reason = $Reason } }
    switch ($ExitCode) {
        0 { return & $outcome $true $false $null }
        -1978335189 { return & $outcome $true $false (T 'ya estaba al día') }               # 0x8A15002B UPDATE_NOT_APPLICABLE
        { $_ -in -1978334967, -1978334965 } { return & $outcome $true $true $null }    # 0x8A150109 y 0x8A15010B: reinicio
        -1978334966 { return & $outcome $false $false (T 'hay que reiniciar la PC antes') } # 0x8A15010A
        { $_ -in -1978334975, -1978334973 } { return & $outcome $false $false (T 'la app está abierta') }  # 0x8A150101, 0x8A150103
        -1978334974 { return & $outcome $false $false (T 'hay otra instalación en curso') } # 0x8A150102
        -1978334971 { return & $outcome $false $false (T 'no queda espacio en el disco') }  # 0x8A150105
        -1978334969 { return & $outcome $false $false (T 'no hay conexión a internet') }    # 0x8A150107
        -1978334961 { return & $outcome $false $false (T 'una directiva de la organización lo impide') }  # 0x8A15010F
        -1978335128 { return & $outcome $false $false (T 'la app está fijada en su versión') }  # 0x8A150068
        { $_ -in -1978335216, -1978335212 } { return & $outcome $false $false (T 'winget no tiene un instalador para esta PC') }  # 0x8A150010, 0x8A150014
        # 0x8A150056 (el instalador no acepta administrador) y 0x8A15007D (instalada solo para el usuario).
        { $_ -in -1978335146, -1978335107 } { return & $outcome $false $false (T 'no se puede actualizar como administrador; se actualiza desde la propia app') }
    }
    & $outcome $false $false ((T 'winget devolvió el código 0x{0:X8}') -f $ExitCode)
}

# Sin deshacer: queda un registro Action. Si una app falla, sigue con las demás.
function Update-AfWingetApps {
    param([Parameter(Mandatory)]$Tx, [object[]]$Apps = @(), [int]$TimeoutMinutes = 15)
    if (-not $Apps.Count) { return $false }
    # App Installer es el propio winget: si se actualiza antes, las siguientes llamadas pueden fallar.
    $self = 'Microsoft.AppInstaller', '9NBLGGH4NNS1'
    $Apps = @($Apps | Where-Object { $_.Id -notin $self }) + @($Apps | Where-Object { $_.Id -in $self })
    $winget = Get-AfWingetPath
    if (-not $winget) { throw (New-AfApplyError -Reason (T 'winget no está instalado')) }
    $updated = @(); $failed = @(); $reboot = $false
    for ($i = 0; $i -lt $Apps.Count; $i++) {
        $app = $Apps[$i]
        Set-AfTxProgress -Tx $Tx -Text ((T 'Actualizando {0} de {1}: {2}') -f ($i + 1), $Apps.Count, $app.Name)
        $source = if ($app.Source) { ' --source {0}' -f $app.Source } else { '' }
        $arguments = 'upgrade --id "{0}" --exact{1} --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -f $app.Id, $source
        $result = Invoke-AfProcess -FilePath $winget -Arguments $arguments -TimeoutMs ($TimeoutMinutes * 60000) -Encoding ([System.Text.Encoding]::UTF8)
        $outcome = if ($result.TimedOut) { [pscustomobject]@{ Ok = $false; Reboot = $false; Reason = ((T 'winget no terminó en {0} min') -f $TimeoutMinutes) } } else { Get-AfWingetOutcome -ExitCode $result.ExitCode }
        if ($outcome.Ok) {
            $updated += $app.Name
            if ($outcome.Reboot) { $reboot = $true }
        } else {
            Write-AfLog -Level Warn -Message ('winget {0}: {1} (código {2})' -f $app.Id, $outcome.Reason, $result.ExitCode)
            $failed += [pscustomobject]@{ Name = $app.Name; Reason = $outcome.Reason }
        }
    }
    if (-not $updated.Count) {
        $reasons = @($failed | ForEach-Object { $_.Reason } | Select-Object -Unique)
        $reason = if ($reasons.Count -eq 1) { $reasons[0] } else { (T 'ninguna app se pudo actualizar') }
        throw (New-AfApplyError -Reason $reason)
    }
    $detail = (T 'Se actualizaron {0} de {1}') -f $updated.Count, $Apps.Count
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'Action'; Name = 'Apps'; Detail = $detail; Updated = $updated; Failed = @($failed | ForEach-Object { $_.Name }) }
    [void]$Tx.Notes.Add($detail + '.')
    foreach ($f in $failed) { [void]$Tx.Notes.Add(((T 'No se pudo con {0}: {1}.') -f $f.Name, $f.Reason)) }
    $Tx.NeedsReboot = $reboot
    $true
}
# Características opcionales de Windows con dism.exe: /English deja la salida igual en cualquier idioma.
# Por su ruta completa: por nombre, Windows lo buscaría antes en la carpeta actual (por ejemplo, la USB).
function Get-AfDismPath { Join-Path $env:SystemRoot 'System32\dism.exe' }

function Get-AfFeatureInfo {
    param([Parameter(Mandatory)][string]$Name)
    $result = Invoke-AfProcess -FilePath (Get-AfDismPath) -Arguments ('/Online /English /Get-FeatureInfo /FeatureName:{0}' -f $Name) -TimeoutMs 120000
    if ($result.TimedOut) { throw (New-AfApplyError -Reason (T 'DISM no respondió')) }
    $info = ConvertFrom-AfDismFeatureInfo -Text $result.Output
    if ($result.ExitCode -ne 0 -or -not $info.State) { throw (New-AfApplyError -Reason ((T 'DISM no pudo leer {0} (código {1})') -f $Name, $result.ExitCode)) }
    $info
}

function Invoke-AfFeatureChange {
    param([Parameter(Mandatory)][string]$Name, [bool]$Enabled)
    $verb = if ($Enabled) { 'Enable' } else { 'Disable' }
    $result = Invoke-AfProcess -FilePath (Get-AfDismPath) -Arguments ('/Online /English /{0}-Feature /FeatureName:{1} /NoRestart /Quiet' -f $verb, $Name) -TimeoutMs 600000
    if ($result.TimedOut) { throw (New-AfApplyError -Reason (T 'DISM no terminó a tiempo')) }
    # 3010: hecho, falta reiniciar.
    if ($result.ExitCode -notin 0, 3010) {
        Write-AfLog -Level Warn -Message ('dism {0}-Feature {1}: código {2}. {3}' -f $verb, $Name, $result.ExitCode, $result.Output)
        throw (New-AfApplyError -Reason ((T 'DISM no aceptó el cambio (código {0})') -f $result.ExitCode))
    }
}

function Set-AfWindowsFeature {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][bool]$Enabled)
    $target = if ($Enabled) { 'Enabled' } else { 'Disabled' }
    $previous = (Get-AfFeatureInfo -Name $Name).State
    if ($previous -eq $target) { return $false }
    Invoke-AfFeatureChange -Name $Name -Enabled $Enabled
    Add-AfTxRecord -Tx $Tx -Record @{ Kind = 'WindowsFeature'; Name = $Name; Previous = $previous; New = $target }
    $Tx.NeedsReboot = $true
    $true
}

function Restore-AfWindowsFeature {
    param([Parameter(Mandatory)]$Record, $User)
    Invoke-AfFeatureChange -Name $Record.Name -Enabled ($Record.Previous -eq 'Enabled')
}

function Get-AfWindowsFeatureState {
    param([Parameter(Mandatory)]$Record, $User)
    (Get-AfFeatureInfo -Name $Record.Name).State
}

# Apps de la Store para el usuario del proceso. Deshacer las registra de nuevo si siguen en la PC
# (aprovisionadas o de otra cuenta) o las reinstala desde la Microsoft Store con winget.
function Test-AfAppxStaged {
    param([Parameter(Mandatory)][string]$PackageName)
    try { if (@(Get-AppxPackage -AllUsers -Name $PackageName -ErrorAction Stop).Count) { return $true } } catch { }
    try { return [bool]@(Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $_.DisplayName -eq $PackageName }).Count } catch { }
    $false
}

function Remove-AfAppxPackage {
    param([Parameter(Mandatory)]$Tx, [Parameter(Mandatory)]$App)
    $installed = @(Get-AppxPackage -Name $App.PackageName -ErrorAction SilentlyContinue)
    if (-not $installed.Count) { return $false }
    try {
        Remove-AppxPackage -Package $installed[0].PackageFullName -ErrorAction Stop
    } catch {
        Write-AfLog -Level Warn -Message ('Remove-AppxPackage {0}: {1}' -f $installed[0].PackageFullName, $_.Exception.Message)
        throw (New-AfApplyError -Reason ((T 'Windows no dejó quitar {0}') -f $App.Name))
    }
    Add-AfTxRecord -Tx $Tx -Record @{
        Kind = 'AppxPackage'; Name = $App.Name; PackageName = $App.PackageName; PackageFamilyName = $installed[0].PackageFamilyName
        StoreId = $App.StoreId; Previous = 'Installed'; New = 'Removed'
    }
    $true
}

function Restore-AfAppxPackage {
    param([Parameter(Mandatory)]$Record, $User)
    if (@(Get-AppxPackage -Name $Record.PackageName -ErrorAction SilentlyContinue).Count) { return }
    if (Test-AfAppxStaged -PackageName $Record.PackageName) {
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage $Record.PackageFamilyName -ErrorAction Stop
            return
        } catch {
            Write-AfLog -Level Warn -Message ('No se pudo registrar {0}: {1}' -f $Record.PackageFamilyName, $_.Exception.Message)
        }
    }
    $winget = if ($Record.StoreId) { Get-AfWingetPath }
    if (-not $winget) { throw (New-AfApplyError -Reason (T 'ya no está en la PC; se reinstala desde la Microsoft Store')) }
    $arguments = 'install --id {0} --source msstore --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity' -f $Record.StoreId
    $result = Invoke-AfProcess -FilePath $winget -Arguments $arguments -TimeoutMs 900000 -Encoding ([System.Text.Encoding]::UTF8)
    $outcome = if ($result.TimedOut) { [pscustomobject]@{ Ok = $false; Reason = (T 'winget no terminó en 15 min') } } else { Get-AfWingetOutcome -ExitCode $result.ExitCode }
    if (-not $outcome.Ok) { throw (New-AfApplyError -Reason ((T 'no se pudo reinstalar {0} desde la Microsoft Store: {1}') -f $Record.Name, $outcome.Reason)) }
}

function Get-AfAppxPackageState {
    param([Parameter(Mandatory)]$Record, $User)
    if (@(Get-AppxPackage -Name $Record.PackageName -ErrorAction SilentlyContinue).Count) { 'Installed' } else { 'Removed' }
}

# Lectores de salidas de comandos. Solo usan posiciones, números y palabras que no cambian con el idioma.

# powercfg /q <plan> <subgrupo> <ajuste>: los dos últimos 0x... son CA y CC, en ese orden.
function ConvertFrom-AfPowercfgQuery {
    param([string]$Text)
    $hex = [regex]::Matches([string]$Text, '0x([0-9a-fA-F]+)')
    if ($hex.Count -lt 2) { return $null }
    [pscustomobject]@{
        Ac = [Convert]::ToInt32($hex[$hex.Count - 2].Groups[1].Value, 16)
        Dc = [Convert]::ToInt32($hex[$hex.Count - 1].Groups[1].Value, 16)
    }
}

# netsh wlan show interfaces: conectado si hay línea SSID; banda por "GHz" o, si falta, por el canal.
function ConvertFrom-AfNetshWlan {
    param([string]$Text)
    $text = [string]$Text
    $ssid = [regex]::Match($text, '(?m)^\s*SSID\s*:\s*(.+?)\s*$')
    $band = $null
    $channel = $null
    if ($ssid.Success) {
        $bandMatch = [regex]::Match($text, '(?m):\s*(\d+(?:[.,]\d+)?)\s*GHz\s*$')
        if ($bandMatch.Success) {
            $band = [double]::Parse($bandMatch.Groups[1].Value.Replace(',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
        }
        # Etiqueta del canal en los idiomas más comunes; solo se usa si falta la banda.
        $channelMatch = [regex]::Match($text, '(?mi)^\s*(?:Channel|Canal|Kanal|Canale)\s*:\s*(\d+)\s*$')
        if ($channelMatch.Success) { $channel = [int]$channelMatch.Groups[1].Value }
        if (-not $band -and $channel) { $band = if ($channel -le 14) { 2.4 } else { 5.0 } }
    }
    [pscustomobject]@{
        Connected = $ssid.Success
        BandGHz = $band
        Channel = $channel
        Ssid = if ($ssid.Success) { $ssid.Groups[1].Value } else { $null }
    }
}

function ConvertFrom-AfFsutilTrim {
    param([string]$Text)
    $m = [regex]::Match([string]$Text, 'NTFS\s+DisableDeleteNotify\s*=\s*(\d)')
    [pscustomobject]@{ NtfsDisabled = $m.Success -and $m.Groups[1].Value -eq '1' }
}

# productState de root\SecurityCenter2: bits 12-15 = activado (1); bits 4-7 = firmas (0 = al día).
function ConvertFrom-AfProductState {
    param([int]$State)
    [pscustomobject]@{
        Enabled = (($State -shr 12) -band 0xF) -eq 1
        UpToDate = (($State -shr 4) -band 0xF) -eq 0
    }
}

# winget upgrade: las columnas se cortan por donde empieza cada palabra del encabezado sobre la línea de guiones.
function ConvertFrom-AfWingetUpgrade {
    param([string]$Text)
    $lines = @(([string]$Text) -split "`r?`n" | ForEach-Object { ($_ -split "`r")[-1] })
    $dash = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^-{10,}\s*$') { $dash = $i; break }
    }
    if ($dash -lt 1) { return @() }

    $starts = @([regex]::Matches($lines[$dash - 1], '(?<=^|\s)\S') | ForEach-Object { $_.Index })
    if ($starts.Count -lt 4) { return @() }

    $apps = @()
    for ($i = $dash + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { break }
        if ($line.Length -le $starts[3]) { continue }
        $availableEnd = if ($starts.Count -ge 5 -and $line.Length -gt $starts[4]) { $starts[4] } else { $line.Length }
        $id = $line.Substring($starts[1], $starts[2] - $starts[1]).Trim()
        if (-not $id -or $id -match '\s') { continue }
        $apps += [pscustomobject]@{
            Name = $line.Substring(0, $starts[1]).Trim()
            Id = $id
            Version = $line.Substring($starts[2], $starts[3] - $starts[2]).Trim()
            Available = $line.Substring($starts[3], $availableEnd - $starts[3]).Trim()
            Source = if ($starts.Count -ge 5 -and $line.Length -gt $starts[4]) { $line.Substring($starts[4]).Trim() } else { '' }
        }
    }
    $apps
}

# Salida de "dism /English /Get-FeatureInfo": el estado se normaliza a Enabled o Disabled, con su reinicio pendiente.
function ConvertFrom-AfDismFeatureInfo {
    param([string]$Text)
    $raw = $null
    $match = [regex]::Match([string]$Text, '(?m)^\s*State\s*:\s*(.+?)\s*$')
    if ($match.Success) { $raw = $match.Groups[1].Value }
    $state = $null; $pending = $false
    switch ($raw) {
        'Enabled' { $state = 'Enabled' }
        'Enable Pending' { $state = 'Enabled'; $pending = $true }
        'Disabled' { $state = 'Disabled' }
        'Disable Pending' { $state = 'Disabled'; $pending = $true }
        'Disabled with Payload Removed' { $state = 'Disabled' }
    }
    [pscustomobject]@{ State = $state; Pending = $pending; Raw = $raw }
}

# La primera cifra de la versión del driver indica el WDDM: 27 = 2.7, 32 = 3.2.
function Get-AfWddmVersion {
    param([string]$DriverVersion)
    $first = ([string]$DriverVersion -split '\.')[0]
    $number = 0
    if (-not [int]::TryParse($first, [ref]$number)) { return 0 }
    [math]::Round($number / 10, 1)
}

function Get-AfSystemInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -OperationTimeoutSec 15
    $build = [int]$os.BuildNumber
    [pscustomobject]@{
        Caption = ([string]$os.Caption).Trim()
        Build = $build
        Edition = Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID'
        IsWin11 = $build -ge 22000
        IsInsider = [bool](Get-AfRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability' -Name 'BranchName')
    }
}

function Get-AfDeviceInfo {
    $laptopChassis = @(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32)
    $system = Get-CimInstance -ClassName Win32_ComputerSystem -OperationTimeoutSec 15
    $product = Get-CimInstance -ClassName Win32_ComputerSystemProduct -OperationTimeoutSec 15
    $enclosure = Get-CimInstance -ClassName Win32_SystemEnclosure -OperationTimeoutSec 15 | Select-Object -First 1
    $battery = @(Get-CimInstance -ClassName Win32_Battery -OperationTimeoutSec 15)

    $manufacturer = ([string]$system.Manufacturer).Trim()
    # Lenovo pone el tipo de máquina (83DV) en Model y el nombre comercial en Version.
    $model = if ($manufacturer -match 'LENOVO' -and $product.Version) { ([string]$product.Version).Trim() } else { ([string]$system.Model).Trim() }
    $hasLaptopChassis = @($enclosure.ChassisTypes | Where-Object { $laptopChassis -contains [int]$_ }).Count -gt 0

    [pscustomobject]@{
        Manufacturer = $manufacturer
        Model = $model
        IsLaptop = $hasLaptopChassis -or $battery.Count -gt 0
        OnBattery = $battery.Count -gt 0 -and [int]$battery[0].BatteryStatus -eq 1
    }
}

function Get-AfCpuInfo {
    $cpu = Get-CimInstance -ClassName Win32_Processor -OperationTimeoutSec 15 | Select-Object -First 1
    [pscustomobject]@{ Name = ([string]$cpu.Name).Trim(); Cores = [int]$cpu.NumberOfCores; Threads = [int]$cpu.NumberOfLogicalProcessors }
}

# Fabricante por el identificador PCI (no cambia con el idioma ni con el driver); si no está, por el nombre.
function Get-AfGpuVendor {
    param([string]$PnpId, [string]$Text)
    if ($PnpId -match 'VEN_10DE') { return 'NVIDIA' }
    if ($PnpId -match 'VEN_(1002|1022)') { return 'AMD' }
    if ($PnpId -match 'VEN_8086') { return 'Intel' }
    switch -Regex ($Text) {
        'NVIDIA' { 'NVIDIA'; break }
        'Advanced Micro Devices|AMD|ATI ' { 'AMD'; break }
        'Intel' { 'Intel'; break }
        default { 'Other' }
    }
}

# Solo gráficas físicas (PCI). Se saltan las virtuales, remotas o por USB: Hyper-V, VMware, VirtualBox, QEMU,
# Escritorio remoto, Parsec, DisplayLink. Una gráfica física con display.inf ("Adaptador de pantalla básico") no tiene su driver.
function Get-AfGpuInfo {
    $virtualName = 'Remote Display|Virtual|Hyper-V|VMware|VirtualBox|Parsec|Citrix|Mirage|DisplayLink'
    $virtualVendor = 'VEN_(15AD|80EE|1414|1234|1AF4|1B36|5333)'
    foreach ($gpu in @(Get-CimInstance -ClassName Win32_VideoController -OperationTimeoutSec 15)) {
        $name = ([string]$gpu.Name).Trim()
        $pnp = [string]$gpu.PNPDeviceID
        if ($pnp -notlike 'PCI\*' -or $pnp -match $virtualVendor -or $name -match $virtualName) { continue }
        $vendor = Get-AfGpuVendor -PnpId $pnp -Text (([string]$gpu.AdapterCompatibility) + ' ' + $name)
        [pscustomobject]@{
            Name = $name
            Vendor = $vendor
            IsDiscrete = $vendor -eq 'NVIDIA' -or $name -match 'Radeon RX|Radeon Pro|Arc A\d|Arc B\d'
            HasDriver = ([string]$gpu.InfFilename) -ne 'display.inf'
            DriverVersion = [string]$gpu.DriverVersion
            DriverDate = $gpu.DriverDate
            WddmVersion = Get-AfWddmVersion -DriverVersion $gpu.DriverVersion
        }
    }
}

function Get-AfMemoryInfo {
    $modules = @(Get-CimInstance -ClassName Win32_PhysicalMemory -OperationTimeoutSec 15 | ForEach-Object {
            [pscustomobject]@{
                CapacityGB = [math]::Round([double]$_.Capacity / 1GB, 1)
                Speed = [int]$_.Speed
                ConfiguredSpeed = [int]$_.ConfiguredClockSpeed
                FormFactor = [int]$_.FormFactor
                PartNumber = ([string]$_.PartNumber).Trim()
                Locator = ([string]$_.DeviceLocator).Trim()
            }
        })
    $total = ($modules | Measure-Object -Property CapacityGB -Sum).Sum
    [pscustomobject]@{
        TotalGB = [math]::Round([double]$total)
        # 8 = DIMM, 12 = SODIMM; lo demás es RAM soldada.
        Socketed = $modules.Count -gt 0 -and @($modules | Where-Object { $_.FormFactor -notin 8, 12 }).Count -eq 0
        Modules = $modules
    }
}

function Get-AfDisplayInfo {
    # Hz máximos que anuncia cada monitor (EDID), por código de monitor.
    $edid = @{}
    try {
        foreach ($monitor in @(Get-CimInstance -Namespace 'root\wmi' -ClassName WmiMonitorListedSupportedSourceModes -OperationTimeoutSec 15 -ErrorAction Stop)) {
            $code = ([string]$monitor.InstanceName -split '\\')[1]
            $rates = @($monitor.MonitorSourceModes | Where-Object { $_.VerticalRefreshRateDenominator } |
                    ForEach-Object { [math]::Round($_.VerticalRefreshRateNumerator / $_.VerticalRefreshRateDenominator) })
            if ($code -and $rates.Count) { $edid[$code] = [int]($rates | Measure-Object -Maximum).Maximum }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudieron leer los modos EDID: $($_.Exception.Message)"
    }

    foreach ($display in @(Get-AfDisplayModes)) {
        $sameRes = @($display.Modes | Where-Object { $_.Width -eq $display.Width -and $_.Height -eq $display.Height } | ForEach-Object { $_.Hz })
        $maxHz = (@($sameRes) + $display.Hz | Measure-Object -Maximum).Maximum
        [pscustomobject]@{
            DeviceName = $display.DeviceName
            MonitorCode = $display.MonitorCode
            IsPrimary = $display.IsPrimary
            Width = $display.Width
            Height = $display.Height
            Hz = $display.Hz
            MaxHzAtCurrentRes = [int]$maxHz
            EdidMaxHz = if ($display.MonitorCode -and $edid.ContainsKey($display.MonitorCode)) { $edid[$display.MonitorCode] } else { $null }
            Modes = $display.Modes
        }
    }
}

function Get-AfPowerInfo {
    $active = Get-AfRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name 'ActivePowerScheme'
    $wifiAc = $null
    # Adaptador inalámbrico > Modo de ahorro de energía (0 = rendimiento máximo).
    $query = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\powercfg.exe') -Arguments '/q SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a' -TimeoutMs 15000
    if (-not $query.TimedOut -and $query.ExitCode -eq 0) {
        $values = ConvertFrom-AfPowercfgQuery -Text $query.Output
        if ($values) { $wifiAc = $values.Ac }
    }
    [pscustomobject]@{
        ActiveScheme = if ($active) { ([string]$active).ToLowerInvariant() } else { $null }
        OverlayAc = Get-AfPowerOverlay
        WifiPowerAc = $wifiAc
    }
}

# Herramientas de fabricante que manejan límites de potencia y ventiladores.
# Nombres de servicio y proceso por conocimiento común: verificarlos en equipos reales de cada marca.
$script:AfVendorToolList = @(
    @{ Name = 'Armoury Crate'; Services = @('ArmouryCrateService', 'ArmouryCrateControlInterface'); Processes = @('ArmouryCrate') }
    @{ Name = 'G-Helper'; Services = @(); Processes = @('GHelper') }
    @{ Name = 'Lenovo Vantage'; Services = @('ImControllerService', 'LenovoVantageService'); Processes = @('LenovoVantage') }
    @{ Name = 'Legion Toolkit'; Services = @(); Processes = @('Lenovo Legion Toolkit', 'LenovoLegionToolkit') }
    @{ Name = 'MSI Center'; Services = @('MSI Central Service'); Processes = @('MSI Center', 'MSI.CentralServer') }
    @{ Name = 'NitroSense'; Services = @('NitroSenseService'); Processes = @('NitroSense') }
    @{ Name = 'OMEN Gaming Hub'; Services = @('HPOmenCap', 'HP Omen HSA Service'); Processes = @('OmenCommandCenterBackground') }
    @{ Name = 'Alienware Command Center'; Services = @('AWCCService'); Processes = @() }
)

function Get-AfVendorTools {
    $services = @(Get-Service -ErrorAction SilentlyContinue | ForEach-Object { $_.Name; $_.DisplayName })
    $processes = @(Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.ProcessName })
    foreach ($tool in $script:AfVendorToolList) {
        $found = @($tool.Services | Where-Object { $services -contains $_ }).Count -gt 0 -or
            @($tool.Processes | Where-Object { $processes -contains $_ }).Count -gt 0
        if ($found) { $tool.Name }
    }
}

function Get-AfNetworkInfo {
    foreach ($adapter in @(Get-NetAdapter -Physical -ErrorAction Stop)) {
        $kind = switch -Regex ([string]$adapter.PhysicalMediaType) {
            '^802\.3$' { 'Ethernet'; break }
            '802\.11|Wireless' { 'WiFi'; break }
            default { $null }
        }
        if (-not $kind) { continue }

        $properties = @{}
        $speedDuplexValues = @()
        foreach ($p in @(Get-NetAdapterAdvancedProperty -Name $adapter.Name -ErrorAction SilentlyContinue)) {
            if ($p.RegistryKeyword) { $properties[$p.RegistryKeyword] = [string](@($p.RegistryValue)[0]) }
            if ($p.RegistryKeyword -eq '*SpeedDuplex') { $speedDuplexValues = @($p.ValidRegistryValues) }
        }

        $linkMbps = [int]([double]$adapter.ReceiveLinkSpeed / 1e6)
        $description = [string]$adapter.InterfaceDescription
        $maxMbps = $linkMbps
        if ($description -match '2\.5\s*G') { $maxMbps = 2500 }
        elseif ($description -match '\b10\s*G') { $maxMbps = 10000 }
        elseif ($description -match 'GbE|Gigabit|1000') { $maxMbps = [math]::Max($maxMbps, 1000) }
        # *SpeedDuplex = 6 es 1 Gbps dúplex completo.
        if ($speedDuplexValues -contains '6') { $maxMbps = [math]::Max($maxMbps, 1000) }

        [pscustomobject]@{
            Name = $adapter.Name
            Kind = $kind
            Description = $description
            Status = [string]$adapter.Status
            LinkSpeedMbps = $linkMbps
            MaxSpeedMbps = $maxMbps
            Properties = $properties
        }
    }
}

function Get-AfWlanInfo {
    $result = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\netsh.exe') -Arguments 'wlan show interfaces' -TimeoutMs 15000 -Encoding ([System.Text.Encoding]::UTF8)
    if ($result.TimedOut) { return [pscustomobject]@{ Connected = $false; BandGHz = $null; Channel = $null; Ssid = $null } }
    ConvertFrom-AfNetshWlan -Text $result.Output
}

function ConvertFrom-AfThreatResource {
    param([string]$Resource)
    # Defender anota los recursos como "file:_C:\ruta" o "regkey:_HKLM\...".
    ([string]$Resource) -replace '^[a-zA-Z]+:_', ''
}

function Test-AfUsesVirtualization {
    param($User)
    $lxss = Resolve-AfRegistryPath -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -User $User
    $wslDistros = @(Get-ChildItem -LiteralPath $lxss -ErrorAction SilentlyContinue).Count -gt 0
    $docker = Test-Path -LiteralPath (Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe')
    $bluestacks = Test-Path -LiteralPath 'HKLM:\SOFTWARE\BlueStacks_nxt'
    $wslDistros -or $docker -or $bluestacks
}

function Get-AfSecurityInfo {
    param($User)
    $antivirus = @()
    try {
        foreach ($av in @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName AntiVirusProduct -OperationTimeoutSec 15 -ErrorAction Stop)) {
            $state = ConvertFrom-AfProductState -State ([int]$av.productState)
            $antivirus += [pscustomobject]@{
                Name = [string]$av.displayName
                Enabled = $state.Enabled
                UpToDate = $state.UpToDate
                IsDefender = [string]$av.displayName -match 'Defender'
            }
        }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudo leer el Centro de seguridad: $($_.Exception.Message)"
    }

    $defender = [pscustomobject]@{ Available = $false; RealTime = $null; SignatureAgeDays = $null; TamperProtected = $null; PuaProtection = $null; Threats = @() }
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        $preference = Get-MpPreference -ErrorAction Stop
        $threats = @()
        try {
            $threats = @(Get-MpThreat -ErrorAction Stop | ForEach-Object {
                    [pscustomobject]@{ Name = [string]$_.ThreatName; Active = [bool]$_.IsActive; Path = ConvertFrom-AfThreatResource -Resource (@($_.Resources)[0]) }
                })
        } catch { }
        $defender = [pscustomobject]@{
            Available = [bool]$status.AMServiceEnabled
            RealTime = [bool]$status.RealTimeProtectionEnabled
            SignatureAgeDays = [int]$status.AntivirusSignatureAge
            TamperProtected = [bool]$status.IsTamperProtected
            PuaProtection = [int]$preference.PUAProtection
            Threats = $threats
        }
    } catch {
        Write-AfLog -Level Info -Message 'Defender no está disponible (otro antivirus o modo pasivo).'
    }

    $firewall = @()
    try {
        $firewall = @(Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object {
                [pscustomobject]@{ Profile = [string]$_.Name; Enabled = [string]$_.Enabled -eq 'True' }
            })
    } catch { }

    $thirdPartyFirewall = $false
    try {
        $products = @(Get-CimInstance -Namespace 'root\SecurityCenter2' -ClassName FirewallProduct -OperationTimeoutSec 15 -ErrorAction Stop)
        $thirdPartyFirewall = @($products | Where-Object { [string]$_.displayName -notmatch 'Windows|Microsoft' }).Count -gt 0
    } catch { }

    $hvci = $false
    try {
        $guard = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -OperationTimeoutSec 15 -ErrorAction Stop
        $hvci = @($guard.SecurityServicesRunning) -contains 2
    } catch { }

    # InstallState 1 = activada. Con Hyper-V o la Plataforma del hipervisor activadas, apagar VMP no cambia nada.
    $features = @{}
    try {
        $filter = "Name='VirtualMachinePlatform' OR Name='Microsoft-Hyper-V-All' OR Name='HypervisorPlatform'"
        foreach ($feature in @(Get-CimInstance -ClassName Win32_OptionalFeature -Filter $filter -OperationTimeoutSec 15 -ErrorAction Stop)) { $features[[string]$feature.Name] = [int]$feature.InstallState }
    } catch { }
    $hypervisor = $features['Microsoft-Hyper-V-All'] -eq 1 -or $features['HypervisorPlatform'] -eq 1
    $vmPlatform = [pscustomobject]@{ State = $(if ($features['VirtualMachinePlatform'] -eq 1) { 'Enabled' } else { 'Disabled' }); Pending = $false }
    # DISM tarda unos segundos: solo se le pregunta si CIM la ve activada, para saber si ya se apaga al reiniciar.
    if ($vmPlatform.State -eq 'Enabled') {
        try {
            $info = Get-AfFeatureInfo -Name 'VirtualMachinePlatform'
            $vmPlatform = [pscustomobject]@{ State = $info.State; Pending = $info.Pending }
        } catch { }
    }

    [pscustomobject]@{
        Antivirus = $antivirus
        Defender = $defender
        Firewall = $firewall
        ThirdPartyFirewall = $thirdPartyFirewall
        HvciRunning = $hvci
        VmPlatform = $vmPlatform
        VmPlatformEnabled = $vmPlatform.State -eq 'Enabled'
        UsesVirtualization = $hypervisor -or (Test-AfUsesVirtualization -User $User)
    }
}

$script:AfSignatureCache = @{}

function Get-AfCommandPath {
    param([string]$Command)
    $text = [Environment]::ExpandEnvironmentVariables(([string]$Command).Trim())
    if (-not $text) { return $null }
    if ($text.StartsWith('"')) {
        $end = $text.IndexOf('"', 1)
        if ($end -gt 1) { return $text.Substring(1, $end - 1) }
    }
    $m = [regex]::Match($text, '^(.+?\.(exe|com|bat|cmd|ps1|vbs|lnk))(\s|$)', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    ($text -split '\s+')[0]
}

function Test-AfUserWritablePath {
    param([string]$Path)
    if (-not $Path) { return $false }
    $Path -match '^[A-Za-z]:\\(Users|ProgramData)\\' -or $Path -match '\\(AppData|Temp)\\'
}

function Get-AfFileSignature {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [pscustomobject]@{ IsSigned = $false; Signer = $null } }
    if ($script:AfSignatureCache.ContainsKey($Path)) { return $script:AfSignatureCache[$Path] }
    $result = [pscustomobject]@{ IsSigned = $false; Signer = $null }
    try {
        $signature = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        $signer = $null
        if ($signature.SignerCertificate -and $signature.SignerCertificate.Subject -match 'CN="?([^",]+)') { $signer = $Matches[1] }
        $result = [pscustomobject]@{ IsSigned = [string]$signature.Status -eq 'Valid'; Signer = $signer }
    } catch { }
    $script:AfSignatureCache[$Path] = $result
    $result
}

function Get-AfRunValues {
    param($User)
    $skip = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
    $sources = @(
        @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' }
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Scope = 'User'; Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
    )
    foreach ($source in $sources) {
        try { $item = Get-ItemProperty -LiteralPath (Resolve-AfRegistryPath -Path $source.Path -User $User) -ErrorAction Stop } catch { continue }
        foreach ($p in $item.PSObject.Properties) {
            if ($skip -contains $p.Name) { continue }
            [pscustomobject]@{ Name = $p.Name; Command = [string]$p.Value; Scope = $source.Scope; ApprovedPath = $source.Approved; ApprovedName = $p.Name; Source = 'Run' }
        }
    }
}

function Get-AfStartupFolderItems {
    param($User)
    $profilePath = if ($User -and $User.ProfilePath) { $User.ProfilePath } else { $env:USERPROFILE }
    $folders = @(
        @{ Path = Join-Path $profilePath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'; Scope = 'User'; Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
        @{ Path = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\StartUp'; Scope = 'Machine'; Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
    )
    $shell = $null
    foreach ($folder in $folders) {
        foreach ($file in @(Get-ChildItem -LiteralPath $folder.Path -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'desktop.ini' })) {
            $command = $file.FullName
            if ($file.Extension -eq '.lnk') {
                try {
                    if (-not $shell) { $shell = New-Object -ComObject WScript.Shell }
                    $target = $shell.CreateShortcut($file.FullName).TargetPath
                    if ($target) { $command = '"{0}"' -f $target }
                } catch { }
            }
            [pscustomobject]@{ Name = $file.BaseName; Command = $command; Scope = $folder.Scope; ApprovedPath = $folder.Approved; ApprovedName = $file.Name; Source = 'Folder' }
        }
    }
}

function Get-AfStartupEntries {
    param($User)
    foreach ($item in @(@(Get-AfRunValues -User $User) + @(Get-AfStartupFolderItems -User $User))) {
        $approvedName = if ($item.PSObject.Properties['ApprovedName'] -and $item.ApprovedName) { $item.ApprovedName } else { $item.Name }
        # StartupApproved: primer byte impar = desactivado (como lo deja el Administrador de tareas).
        $approved = @(Get-AfRegistryValue -Path $item.ApprovedPath -Name $approvedName -User $User)
        $disabled = $approved.Count -gt 0 -and $null -ne $approved[0] -and ([int]$approved[0] -band 1) -eq 1
        $path = Get-AfCommandPath -Command $item.Command
        $signature = Get-AfFileSignature -Path $path
        [pscustomobject]@{
            Name = $item.Name
            Command = $item.Command
            Path = $path
            Source = if ($item.PSObject.Properties['Source'] -and $item.Source) { $item.Source } else { 'Run' }
            Scope = $item.Scope
            Enabled = -not $disabled
            ApprovedKey = $item.ApprovedPath
            ApprovedName = $approvedName
            IsSigned = $signature.IsSigned
            Signer = $signature.Signer
            InUserWritablePath = Test-AfUserWritablePath -Path $path
        }
    }
}

# Todo lo que arranca solo: inicio, servicios automáticos y tareas programadas que no son de Microsoft.
function Get-AfAutostartBinaries {
    param($User)
    $windows = $env:windir.TrimEnd('\') + '\'
    $result = @(Get-AfStartupEntries -User $User | Where-Object Enabled)

    foreach ($service in @(Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" -OperationTimeoutSec 15 -ErrorAction SilentlyContinue)) {
        $path = Get-AfCommandPath -Command $service.PathName
        if (-not $path -or $path.StartsWith($windows, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $signature = Get-AfFileSignature -Path $path
        if ($signature.Signer -match 'Microsoft') { continue }
        $result += [pscustomobject]@{ Name = [string]$service.DisplayName; Command = [string]$service.PathName; Path = $path; Source = 'Service'; Scope = 'Machine'; Enabled = $true; IsSigned = $signature.IsSigned; Signer = $signature.Signer; InUserWritablePath = Test-AfUserWritablePath -Path $path }
    }

    foreach ($task in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' })) {
        foreach ($action in @($task.Actions | Where-Object { $_.Execute })) {
            $path = Get-AfCommandPath -Command $action.Execute
            if (-not $path -or $path.StartsWith($windows, [StringComparison]::OrdinalIgnoreCase)) { continue }
            $signature = Get-AfFileSignature -Path $path
            if ($signature.Signer -match 'Microsoft') { continue }
            $result += [pscustomobject]@{ Name = [string]$task.TaskName; Command = [string]$action.Execute; Path = $path; Source = 'Task'; Scope = 'Machine'; Enabled = $true; IsSigned = $signature.IsSigned; Signer = $signature.Signer; InUserWritablePath = Test-AfUserWritablePath -Path $path }
        }
    }
    $result
}

function Get-AfFolderBytes {
    param([string]$Path)
    # Directory.Exists y no Test-Path: Test-Path lanza "Acceso denegado" en carpetas de servicio como la de NetworkService.
    if (-not $Path -or -not [System.IO.Directory]::Exists($Path)) { return [long]0 }
    $total = [long]0
    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push($Path)
    while ($pending.Count -gt 0) {
        $dir = $pending.Pop()
        try { foreach ($file in [System.IO.Directory]::EnumerateFiles($dir)) { try { $total += (New-Object System.IO.FileInfo($file)).Length } catch { } } } catch { }
        try {
            foreach ($sub in [System.IO.Directory]::EnumerateDirectories($dir)) {
                # Las uniones y enlaces simbólicos no se siguen, para no contar dos veces ni entrar en bucles.
                if (([System.IO.File]::GetAttributes($sub) -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) { $pending.Push($sub) }
            }
        } catch { }
    }
    $total
}

function Get-AfSystemDiskType {
    try {
        $partition = Get-Partition -DriveLetter ($env:SystemDrive.TrimEnd(':')) -ErrorAction Stop
        $disk = Get-PhysicalDisk -ErrorAction Stop | Where-Object { $_.DeviceId -eq [string]$partition.DiskNumber } | Select-Object -First 1
        [pscustomobject]@{ MediaType = [string]$disk.MediaType; BusType = [string]$disk.BusType }
    } catch {
        [pscustomobject]@{ MediaType = $null; BusType = $null }
    }
}

function Get-AfStorageInfo {
    param($User)
    $drive = $env:SystemDrive
    $logical = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'" -OperationTimeoutSec 15
    $type = Get-AfSystemDiskType
    $profilePath = if ($User -and $User.ProfilePath) { $User.ProfilePath } else { $env:USERPROFILE }
    $windows = $env:windir
    $wer = Join-Path $env:ProgramData 'Microsoft\Windows\WER'
    $temp = [pscustomobject]@{
        User = Get-AfFolderBytes -Path (Join-Path $profilePath 'AppData\Local\Temp')
        Windows = Get-AfFolderBytes -Path (Join-Path $windows 'Temp')
        UpdateCache = Get-AfFolderBytes -Path (Join-Path $windows 'SoftwareDistribution\Download')
        DeliveryOptimization = Get-AfFolderBytes -Path (Join-Path $windows 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache')
        ErrorReports = (Get-AfFolderBytes -Path (Join-Path $wer 'ReportArchive')) + (Get-AfFolderBytes -Path (Join-Path $wer 'ReportQueue'))
    }
    $trim = Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\fsutil.exe') -Arguments 'behavior query DisableDeleteNotify' -TimeoutMs 15000
    [pscustomobject]@{
        SystemDrive = $drive
        FreeGB = [math]::Round([double]$logical.FreeSpace / 1GB)
        SizeGB = [math]::Round([double]$logical.Size / 1GB)
        MediaType = $type.MediaType
        BusType = $type.BusType
        TempBytes = $temp
        TrimEnabled = if ($trim.TimedOut -or $trim.ExitCode -ne 0) { $null } else { -not (ConvertFrom-AfFsutilTrim -Text $trim.Output).NtfsDisabled }
    }
}

function Get-AfWingetPath {
    $winget = Get-Command -Name 'winget' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($winget) { $winget.Source } else { $null }
}

function Get-AfWingetUpgrades {
    $winget = Get-AfWingetPath
    if (-not $winget) { return [pscustomobject]@{ Available = $false; TimedOut = $false; Apps = @() } }
    $result = Invoke-AfProcess -FilePath $winget -Arguments 'upgrade --accept-source-agreements --disable-interactivity' -TimeoutMs 60000 -Encoding ([System.Text.Encoding]::UTF8)
    if ($result.TimedOut) { return [pscustomobject]@{ Available = $true; TimedOut = $true; Apps = @() } }
    [pscustomobject]@{ Available = $true; TimedOut = $false; Apps = @(ConvertFrom-AfWingetUpgrade -Text $result.Output) }
}

# Apps promocionales preinstaladas (lista cerrada y conservadora; ver sección 10 del diseño).
# StoreId y FamilyName verificados en el catálogo de la Microsoft Store (displaycatalog, 2026-11-21):
# el ID solo se usa si el paquete instalado es exactamente ese, para reinstalarlo al deshacer.
# Es una función, no datos sueltos: los nombres se traducen al usarla, con el idioma ya fijado.
function Get-AfPromoAppPatterns {
    @(
    @{ Pattern = 'king.com.CandyCrush*'; Name = 'Candy Crush'; StoreId = '9NBLGGH18846'; FamilyName = 'king.com.CandyCrushSaga_kgqvnymyfvs32' }
    @{ Pattern = 'BytedancePte.Ltd.TikTok'; Name = 'TikTok'; StoreId = '9NH2GPH4JZS4'; FamilyName = 'BytedancePte.Ltd.TikTok_6yccndn6064se' }
    @{ Pattern = 'Disney.37853FC22B2CE'; Name = 'Disney+'; StoreId = '9NXQXXLFST89'; FamilyName = 'Disney.37853FC22B2CE_6rarf9sa4v8jt' }
    @{ Pattern = 'Facebook.Facebook'; Name = 'Facebook'; StoreId = '9WZDNCRFJ2WL'; FamilyName = 'Facebook.Facebook_8xx8rvfyw5nnt' }
    @{ Pattern = 'Facebook.InstagramBeta'; Name = 'Instagram'; StoreId = '9NBLGGH5L9XT'; FamilyName = 'Facebook.InstagramBeta_8xx8rvfyw5nnt' }
    @{ Pattern = '7EE7776C.LinkedInforWindows'; Name = 'LinkedIn'; StoreId = '9WZDNCRFJ4Q7'; FamilyName = '7EE7776C.LinkedInforWindows_w1wdnht996qgy' }
    @{ Pattern = 'Microsoft.MicrosoftSolitaireCollection'; Name = (T 'Solitario'); StoreId = '9WZDNCRFHWD2'; FamilyName = 'Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.BingNews'; Name = (T 'Noticias'); StoreId = '9WZDNCRFHVFW'; FamilyName = 'Microsoft.BingNews_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.Getstarted'; Name = (T 'Sugerencias'); StoreId = '9WZDNCRDTBJJ'; FamilyName = 'Microsoft.Getstarted_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.GetHelp'; Name = (T 'Obtener ayuda'); StoreId = '9PKDZBMV1H3T'; FamilyName = 'Microsoft.GetHelp_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.WindowsFeedbackHub'; Name = (T 'Centro de opiniones'); StoreId = '9NBLGGH4R32N'; FamilyName = 'Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe' }
    @{ Pattern = 'Microsoft.MixedReality.Portal'; Name = (T 'Portal de realidad mixta'); StoreId = '9NG1H8B3ZC7M'; FamilyName = 'Microsoft.MixedReality.Portal_8wekyb3d8bbwe' }
    )
}

function Get-AfPromoApps {
    param($User)
    $packages = @()
    try {
        $packages = if ($User -and -not $User.IsSameAsProcess) { @(Get-AppxPackage -User $User.Sid -ErrorAction Stop) } else { @(Get-AppxPackage -ErrorAction Stop) }
    } catch {
        Write-AfLog -Level Warn -Message "No se pudieron listar las apps: $($_.Exception.Message)"
    }
    $promo = @(foreach ($entry in Get-AfPromoAppPatterns) {
            $match = $packages | Where-Object { $_.Name -like $entry.Pattern } | Select-Object -First 1
            if ($match) {
                [pscustomobject]@{
                    Name = $entry.Name; PackageName = $match.Name; PackageFullName = $match.PackageFullName; PackageFamilyName = $match.PackageFamilyName
                    StoreId = if ($match.PackageFamilyName -eq $entry.FamilyName) { $entry.StoreId } else { $null }
                    Provisioned = $false
                }
            }
        })
    # Aprovisionada = sigue en la PC después de quitarla, y se puede registrar de nuevo sin internet.
    # La consulta tarda unos segundos: solo hace falta para las que no se pueden reinstalar desde la Store.
    if (@($promo | Where-Object { -not $_.StoreId }).Count) {
        try {
            $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction Stop | ForEach-Object { [string]$_.DisplayName })
            foreach ($app in $promo) { $app.Provisioned = $provisioned -contains $app.PackageName }
        } catch {
            Write-AfLog -Level Warn -Message "No se pudieron listar las apps aprovisionadas: $($_.Exception.Message)"
        }
    }
    [pscustomobject]@{ Promo = $promo }
}

function Get-AfInventoryPartNames {
    'User', 'Os', 'Device', 'Cpu', 'Gpus', 'Memory', 'Displays', 'Power', 'VendorTools', 'Network', 'Wlan',
    'Security', 'Apps', 'Startup', 'Autostart', 'Storage', 'Registry'
}

# Lee la PC una sola vez. Si una parte falla, queda en $null, se anota en Errors y el resto sigue.
function Get-AfInventory {
    param([string[]]$Reads = @(), [scriptblock]$OnProgress)
    $user = $null
    $parts = [ordered]@{
        User = { Get-AfInteractiveUser }
        Os = { Get-AfSystemInfo }
        Device = { Get-AfDeviceInfo }
        Cpu = { Get-AfCpuInfo }
        Gpus = { , @(Get-AfGpuInfo) }
        Memory = { Get-AfMemoryInfo }
        Displays = { , @(Get-AfDisplayInfo) }
        Power = { Get-AfPowerInfo }
        VendorTools = { , @(Get-AfVendorTools) }
        Network = { , @(Get-AfNetworkInfo) }
        Wlan = { Get-AfWlanInfo }
        Security = { Get-AfSecurityInfo -User $user }
        Apps = { Get-AfPromoApps -User $user }
        Startup = { , @(Get-AfStartupEntries -User $user) }
        Autostart = { , @(Get-AfAutostartBinaries -User $user) }
        Storage = { Get-AfStorageInfo -User $user }
        Registry = { Get-AfRegistrySnapshot -Reads $Reads -User $user }
    }

    $inventory = [ordered]@{}
    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($name in $parts.Keys) {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $inventory[$name] = & $parts[$name]
        } catch {
            $inventory[$name] = $null
            $errors.Add($name)
            Write-AfLog -Level Warn -Message "Inventario: falló $name. $($_.Exception.Message)"
        }
        if ($name -eq 'User') { $user = $inventory.User }
        Write-AfLog -Level Info -Message ('Inventario: {0} en {1} ms' -f $name, $watch.ElapsedMilliseconds)
        if ($OnProgress) { & $OnProgress $name }
    }
    $inventory.Errors = $errors.ToArray()
    [pscustomobject]$inventory
}

function Get-AfCategories {
    @(
        [pscustomobject]@{ Id = 'energy'; Name = (T 'Energía'); Icon = 'lightning' }
        [pscustomobject]@{ Id = 'gaming'; Name = (T 'Juegos y gráficos'); Icon = 'game-controller' }
        [pscustomobject]@{ Id = 'network'; Name = (T 'Red'); Icon = 'wifi-high' }
        [pscustomobject]@{ Id = 'startup'; Name = (T 'Inicio'); Icon = 'rocket-launch' }
        [pscustomobject]@{ Id = 'storage'; Name = (T 'Almacenamiento'); Icon = 'hard-drives' }
        [pscustomobject]@{ Id = 'security'; Name = (T 'Seguridad'); Icon = 'shield-check' }
        [pscustomobject]@{ Id = 'hardware'; Name = (T 'Hardware'); Icon = 'wrench' }
        [pscustomobject]@{ Id = 'optional'; Name = (T 'Opcional'); Icon = 'sliders-horizontal' }
    )
}

function New-AfDetection {
    param(
        [Parameter(Mandatory)][ValidateSet('Ok', 'Improvable', 'Manual', 'Info', 'NotApplicable', 'Error')][string]$State,
        [string]$Title,
        [string]$Current,
        [string]$Target,
        [string]$Note,
        [string]$What,
        [string[]]$Steps = @(),
        [hashtable]$Data = @{},
        $Preselect = $null
    )
    [pscustomobject]@{ State = $State; Title = $Title; Current = $Current; Target = $Target; Note = $Note; What = $What; Steps = $Steps; Data = $Data; Preselect = $Preselect }
}

$script:AfRequiredCheckKeys = 'Id', 'Category', 'Title', 'Why', 'Impact', 'Risk', 'Kind', 'Preselect', 'NeedsReboot', 'Source', 'Undo', 'Detect'

function Test-AfCheckDefinition {
    param([Parameter(Mandatory)][hashtable]$Check)
    $errors = @()
    foreach ($key in $script:AfRequiredCheckKeys) {
        $value = $Check[$key]
        if (-not $Check.ContainsKey($key) -or $null -eq $value -or ($value -is [string] -and -not $value)) { $errors += "Falta $key" }
    }
    if ($Check.Impact -and $Check.Impact -notin 'High', 'Medium', 'Low') { $errors += "Impact inválido: $($Check.Impact)" }
    if ($Check.Risk -and $Check.Risk -notin 'Safe', 'Advanced') { $errors += "Risk inválido: $($Check.Risk)" }
    if ($Check.Kind -and $Check.Kind -notin 'Auto', 'Manual', 'Info') { $errors += "Kind inválido: $($Check.Kind)" }
    if ($Check.Category -and $Check.Category -notin (Get-AfCategories).Id) { $errors += "Category inválida: $($Check.Category)" }
    if ($Check.Detect -and $Check.Detect -isnot [scriptblock]) { $errors += 'Detect debe ser un scriptblock' }
    if ($Check.ContainsKey('AppliesTo') -and $Check.AppliesTo -isnot [scriptblock]) { $errors += 'AppliesTo debe ser un scriptblock' }
    if ($Check.ContainsKey('Apply') -and $Check.Apply -isnot [scriptblock]) { $errors += 'Apply debe ser un scriptblock' }
    foreach ($read in @($Check.Reads)) { if ($read -and $read -notmatch '^HK(LM|CU):\\.+\|.+$') { $errors += "Lectura inválida: $read" } }
    $errors
}

# Una entrada por categoría; cada tarea de revisiones agrega la suya.
function Get-AfCatalogProviders {
    @(
        { Get-AfEnergyChecks }
        { Get-AfGamingChecks }
        { Get-AfNetworkChecks }
        { Get-AfStartupChecks }
        { Get-AfStorageChecks }
        { Get-AfHardwareChecks }
        { Get-AfSecurityChecks }
        { Get-AfOptionalChecks }
    )
}

function Get-AfCatalog {
    param([scriptblock[]]$Providers)
    if (-not $PSBoundParameters.ContainsKey('Providers')) { $Providers = @(Get-AfCatalogProviders) }
    $catalog = @()
    $ids = @{}
    foreach ($provider in $Providers) {
        foreach ($check in @(& $provider)) {
            if ($ids.ContainsKey($check.Id)) { throw "Id repetido en el catálogo: $($check.Id)" }
            $ids[$check.Id] = $true
            $catalog += $check
        }
    }
    $catalog
}

function Get-AfCatalogReads {
    param([object[]]$Catalog = @())
    @($Catalog | ForEach-Object { if ($_.Reads) { $_.Reads } }) | Select-Object -Unique
}

function Get-AfWeight {
    param([string]$Impact)
    switch ($Impact) { 'High' { 3 } 'Medium' { 2 } default { 1 } }
}

function Invoke-AfCheck {
    param([Parameter(Mandatory)][hashtable]$Check, [Parameter(Mandatory)]$Inventory)
    try {
        if ($Check.AppliesTo -and -not (& $Check.AppliesTo $Inventory)) {
            $detection = New-AfDetection -State NotApplicable
        } else {
            $detection = & $Check.Detect $Inventory
            if (-not $detection) { throw (T 'La revisión no devolvió resultado.') }
        }
    } catch {
        $detection = New-AfDetection -State Error -Note $_.Exception.Message
        Write-AfLog -Level Warn -Message "Revisión $($Check.Id): $($_.Exception.Message)"
    }
    $preselect = if ($null -ne $detection.Preselect) { [bool]$detection.Preselect } else { [bool]$Check.Preselect }
    [pscustomobject]@{
        Check = $Check
        Detection = $detection
        Weight = Get-AfWeight -Impact $Check.Impact
        Preselected = $preselect -and $detection.State -eq 'Improvable' -and (Test-AfCanApply -Check $Check)
    }
}

function Test-AfCountsForScore {
    param($Result)
    $Result.Check.Kind -eq 'Auto' -and $Result.Check.Category -ne 'optional' -and $Result.Detection.State -in 'Ok', 'Improvable'
}

# Posición de la aguja: peso en orden / peso de las revisiones automáticas que cuentan (sección 9 del diseño).
function Get-AfScore {
    param([object[]]$Results = @())
    $counted = @($Results | Where-Object { Test-AfCountsForScore $_ })
    $total = ($counted | Measure-Object -Property Weight -Sum).Sum
    if (-not $total) { return 1.0 }
    $ok = (@($counted | Where-Object { $_.Detection.State -eq 'Ok' }) | Measure-Object -Property Weight -Sum).Sum
    [double]$ok / $total
}

function Get-AfSummary {
    param([object[]]$Results = @())
    [pscustomobject]@{
        Ready = @($Results | Where-Object { $_.Check.Kind -eq 'Auto' -and $_.Check.Category -ne 'optional' -and $_.Detection.State -eq 'Improvable' }).Count
        Manual = @($Results | Where-Object { $_.Detection.State -eq 'Manual' }).Count
        Ok = @($Results | Where-Object { $_.Detection.State -eq 'Ok' }).Count
        Optional = @($Results | Where-Object { $_.Check.Category -eq 'optional' -and $_.Detection.State -eq 'Improvable' }).Count
    }
}

# Respaldos: una sesión por cada vez que se aplica, en %ProgramData%\Afina\respaldos\<fecha>.json (diseño, sección 11).
function Get-AfBackupDirectory {
    Join-Path $env:ProgramData 'Afina\respaldos'
}

function Save-AfSession {
    param([Parameter(Mandatory)]$Session)
    $data = $Session | Select-Object -Property * -ExcludeProperty Path
    $json = ConvertTo-Json -InputObject $data -Depth 10
    # Se escribe aparte y se reemplaza: un corte a mitad de escritura no deja el respaldo dañado.
    $temporary = $Session.Path + '.tmp'
    [System.IO.File]::WriteAllText($temporary, $json, (New-Object System.Text.UTF8Encoding($false)))
    # [NullString]::Value: un $null de PowerShell llegaría a .NET como "" y Replace lo rechaza como ruta.
    if ([System.IO.File]::Exists($Session.Path)) { [System.IO.File]::Replace($temporary, $Session.Path, [NullString]::Value) } else { [System.IO.File]::Move($temporary, $Session.Path) }
}

# Se escribe enseguida: si no se puede guardar el respaldo, no se aplica nada.
function New-AfSession {
    param([Parameter(Mandatory)][string]$Directory, $User, [string]$Version = (Get-AfVersion), [datetime]$Now = (Get-Date))
    $id = $Now.ToString('yyyy-MM-dd_HHmmss')
    $sid = if ($User -and $User.Sid) { $User.Sid } else { (Get-AfUserForSid).Sid }
    $session = [pscustomobject]@{
        Format = 1
        Id = $id
        Version = $Version
        Language = Get-AfLanguage
        Machine = $env:COMPUTERNAME
        User = [pscustomobject]@{ Name = if ($User) { $User.Name } else { $null }; Sid = $sid }
        StartedAt = $Now.ToString('o')
        RestorePoint = $null
        Changes = New-Object System.Collections.ArrayList
        Path = $null
    }
    try {
        New-Item -ItemType Directory -Force -Path $Directory -ErrorAction Stop | Out-Null
        $path = Join-Path $Directory "$id.json"
        $n = 2
        while ([System.IO.File]::Exists($path)) {
            $session.Id = '{0}-{1}' -f $id, $n
            $path = Join-Path $Directory ($session.Id + '.json')
            $n++
        }
        $session.Path = $path
        Save-AfSession -Session $session
    } catch {
        Write-AfLog -Level Error -Message "No se pudo crear el respaldo en ${Directory}: $($_.Exception.Message)"
        throw (New-AfApplyError -Reason (T 'no se pudo guardar el respaldo en ProgramData\Afina\respaldos'))
    }
    $session
}

function Import-AfSession {
    param([Parameter(Mandatory)][string]$Path)
    $data = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Path))
    if (-not $data.Id -or $null -eq $data.PSObject.Properties['Changes']) { throw ((T 'No es un respaldo de Afina: {0}') -f $Path) }
    $changes = New-Object System.Collections.ArrayList
    foreach ($change in @($data.Changes)) { if ($null -ne $change) { [void]$changes.Add($change) } }
    $data.Changes = $changes
    $data | Add-Member -NotePropertyName Path -NotePropertyValue $Path -Force
    $data
}

function Get-AfSessions {
    param([string]$Directory = (Get-AfBackupDirectory), [int]$Max = 30)
    if (-not [System.IO.Directory]::Exists($Directory)) { return @() }
    $sessions = foreach ($file in @(Get-ChildItem -LiteralPath $Directory -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
        try { Import-AfSession -Path $file.FullName } catch { Write-AfLog -Level Warn -Message "Respaldo dañado o ajeno: $($file.Name)" }
    }
    $order = { try { [datetimeoffset]::Parse([string]$_.StartedAt, [System.Globalization.CultureInfo]::InvariantCulture) } catch { [datetimeoffset]::MinValue } }
    @($sessions | Sort-Object -Property $order -Descending | Select-Object -First $Max)
}

function Get-AfSessionSummary {
    param([Parameter(Mandatory)]$Session)
    $changes = @($Session.Changes)
    [pscustomobject]@{
        Applied = @($changes | Where-Object { $_.Status -in 'Applied', 'UndoFailed' }).Count
        Undone = @($changes | Where-Object { $_.Status -eq 'Undone' }).Count
        Failed = @($changes | Where-Object { $_.Status -eq 'Failed' }).Count
        Undoable = @($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count
    }
}

function Test-AfCanApply {
    param([Parameter(Mandatory)][hashtable]$Check)
    $Check.Kind -eq 'Auto' -and $Check.Apply -is [scriptblock]
}

# La pantalla primero (pide confirmar), la red al final (corta la conexión unos segundos) y el resto en su orden.
function Get-AfApplyOrder {
    param([object[]]$Items = @())
    $index = 0
    $ranked = foreach ($item in $Items) {
        # Las actualizaciones necesitan internet: van antes de que se reinicie el adaptador.
        $group = if ($item.Check.Id -eq 'display.refresh') { 0 } elseif ($item.Check.Category -eq 'network') { 3 } elseif ($item.Check.Id -like 'updates.*') { 2 } else { 1 }
        [pscustomobject]@{ Item = $item; Group = $group; Index = $index }
        $index++
    }
    @($ranked | Sort-Object -Property Group, Index | ForEach-Object { $_.Item })
}

function Test-AfChangeUndoable {
    param([Parameter(Mandatory)]$Change)
    $Change.Status -notin 'Undone', 'Reverted' -and @($Change.Records | Where-Object { $_ -and $_.Kind -ne 'Action' }).Count -gt 0
}

# Aplica una revisión como un todo: si algo falla a mitad, se revierte lo de esa revisión.
function Invoke-AfChange {
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)][hashtable]$Check, $Detection, $Inventory, [scriptblock]$ConfirmDisplay, [scriptblock]$Progress)
    $user = if ($Inventory -and $Inventory.User) { $Inventory.User } else { Get-AfUserForSid -Sid $Session.User.Sid }
    $tx = New-AfTransaction -User $user -ConfirmDisplay $ConfirmDisplay -Progress $Progress
    $title = if ($Detection -and $Detection.Title) { $Detection.Title } else { $Check.Title }
    $change = [pscustomobject]@{
        CheckId = $Check.Id; Title = $title; NeedsReboot = [bool]$Check.NeedsReboot
        Status = 'Applied'; Message = $null; Note = $null; AppliedAt = $null; UndoneAt = $null; Records = @()
    }
    try {
        if (-not (Test-AfCanApply -Check $Check)) { throw (New-AfApplyError -Reason (T 'este cambio todavía no se aplica desde Afina')) }
        & $Check.Apply $Inventory $Detection $tx | Out-Null
        Complete-AfTransaction -Tx $tx
        $change.Records = @($tx.Records)
        if ($null -ne $tx.NeedsReboot) { $change.NeedsReboot = [bool]$tx.NeedsReboot }
        $change.AppliedAt = (Get-Date).ToString('o')
        if ($tx.Notes.Count) { $change.Note = @($tx.Notes) -join ' ' }
        Write-AfLog -Level Info -Message ('Aplicado {0} ({1} registros).' -f $Check.Id, $tx.Records.Count)
    } catch {
        $failure = $_
        $reason = Get-AfApplyReason -ErrorRecord $failure
        Write-AfLog -Level Warn -Message ('No se aplicó {0}: {1}' -f $Check.Id, $failure.Exception.Message)
        $left = @((Undo-AfRecords -Records @($tx.Records) -User $user).Failed)
        $change.Records = $left
        if ($left.Count) {
            $change.Status = 'Failed'
            $change.Message = (T 'No se pudo aplicar: {0}. Una parte quedó aplicada y se puede deshacer desde Historial.') -f $reason
        } elseif (Test-AfRevertError -ErrorRecord $failure) {
            $change.Status = 'Reverted'
            $change.Message = $reason + '.'
        } else {
            $change.Status = 'Failed'
            $change.Message = (T 'No se pudo aplicar: {0}. No se cambió nada.') -f $reason
        }
    }
    [void]$Session.Changes.Add($change)
    try {
        Save-AfSession -Session $Session
    } catch {
        # Sin respaldo no queda nada aplicado.
        Write-AfLog -Level Error -Message ('No se pudo guardar el respaldo tras {0}: {1}' -f $Check.Id, $_.Exception.Message)
        if ($change.Status -eq 'Applied') {
            $left = @((Undo-AfRecords -Records @($change.Records) -User $user).Failed)
            $change.Records = $left
            $change.Status = 'Failed'
            $change.Message = if ($left.Count) { (T 'No se pudo guardar el respaldo y una parte quedó aplicada.') } else { (T 'No se pudo aplicar: no se pudo guardar el respaldo. No se cambió nada.') }
        }
        try { Save-AfSession -Session $Session } catch { }
    }
    $change
}

# Lo que corre en el trabajo de aplicar. Habla con la ventana solo por la cola (eventos) y por $Shared (respuestas).
function Invoke-AfApplyPlan {
    param([Parameter(Mandatory)]$Plan, [Parameter(Mandatory)]$Queue, [Parameter(Mandatory)]$Shared, [object[]]$Catalog)
    # Los motivos y las notas salen en el idioma de la ventana (antes de armar el catálogo).
    if ($Plan.Language) { Set-AfLanguage -Language $Plan.Language }
    if (-not $PSBoundParameters.ContainsKey('Catalog')) { $Catalog = @(Get-AfCatalog) }
    $inventory = $Plan.Inventory
    $restore = $null
    if ($Plan.RestoreAction -in 'create', 'enable') {
        if ($Plan.RestoreAction -eq 'enable') {
            $Queue.Enqueue([pscustomobject]@{ Type = 'Stage'; Text = 'Activando Restaurar sistema…' })
            Enable-AfSystemRestore | Out-Null
        }
        $Queue.Enqueue([pscustomobject]@{ Type = 'Stage'; Text = (T 'Creando punto de restauración…') })
        $restore = New-AfRestorePoint
        $Queue.Enqueue([pscustomobject]@{ Type = 'RestorePoint'; Ok = $restore.Ok; At = $restore.At; Message = $restore.Message })
        if (-not $restore.Ok) {
            while ($null -eq $Shared.ContinueWithoutRestore) { Start-Sleep -Milliseconds 100 }
            if (-not $Shared.ContinueWithoutRestore) {
                Write-AfLog -Level Info -Message 'Se canceló: no hubo punto de restauración.'
                $Queue.Enqueue([pscustomobject]@{ Type = 'Cancelled' })
                return
            }
        }
    }
    $session = New-AfSession -Directory $Plan.BackupDirectory -User $inventory.User -Version $Plan.Version
    $session.RestorePoint = [pscustomobject]@{
        Created = [bool]($restore -and $restore.Ok)
        At = if ($restore) { $restore.At } else { $null }
        Message = if ($restore) { $restore.Message } else { $null }
        EnabledSystemRestore = $Plan.RestoreAction -eq 'enable'
    }
    Save-AfSession -Session $session
    $items = Get-AfApplyOrder -Items @(foreach ($planned in @($Plan.Items)) {
            $check = @($Catalog | Where-Object { $_.Id -eq $planned.Id })[0]
            if ($check) { [pscustomobject]@{ Id = $planned.Id; Check = $check; Detection = $planned.Detection } }
        })
    # La pantalla se confirma desde la ventana; sin respuesta en 15 s vuelve sola.
    $confirm = {
        param($records)
        $Shared.DisplayAnswer = $null
        $Queue.Enqueue([pscustomobject]@{ Type = 'ConfirmDisplay'; Id = $Shared.Current; Records = @($records) })
        $deadline = (Get-Date).AddSeconds(15)
        while ((Get-Date) -lt $deadline -and -not $Shared.DisplayAnswer) { Start-Sleep -Milliseconds 100 }
        if ($Shared.DisplayAnswer) { $Shared.DisplayAnswer } else { 'timeout' }
    }.GetNewClosure()
    $progress = {
        param($text)
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeProgress'; Id = $Shared.Current; Text = [string]$text })
    }.GetNewClosure()
    foreach ($item in $items) {
        $Shared.Current = $item.Id
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeStart'; Id = $item.Id })
        $change = Invoke-AfChange -Session $session -Check $item.Check -Detection $item.Detection -Inventory $inventory -ConfirmDisplay $confirm -Progress $progress
        $Queue.Enqueue([pscustomobject]@{ Type = 'ChangeDone'; Id = $item.Id; Change = $change })
    }
    $Queue.Enqueue([pscustomobject]@{ Type = 'ApplyDone'; SessionPath = $session.Path })
}

# Deshace en el orden inverso al aplicado; sin ChangeIds, todo lo que se pueda de la sesión.
function Invoke-AfUndoPlan {
    param([Parameter(Mandatory)]$Plan, [Parameter(Mandatory)]$Queue)
    if ($Plan.Language) { Set-AfLanguage -Language $Plan.Language }
    $session = Import-AfSession -Path $Plan.SessionPath
    $ids = @($Plan.ChangeIds | Where-Object { $_ })
    $changes = @($session.Changes | Where-Object { ($ids.Count -eq 0 -or $ids -contains $_.CheckId) -and (Test-AfChangeUndoable -Change $_) })
    [array]::Reverse($changes)
    foreach ($change in $changes) {
        $Queue.Enqueue([pscustomobject]@{ Type = 'UndoStart'; Id = $change.CheckId })
        Undo-AfChange -Session $session -Change $change | Out-Null
        $Queue.Enqueue([pscustomobject]@{ Type = 'UndoDone'; Id = $change.CheckId; Change = $change })
    }
    $Queue.Enqueue([pscustomobject]@{ Type = 'UndoFinished'; SessionPath = $session.Path })
}

function Undo-AfChange {
    param([Parameter(Mandatory)]$Session, [Parameter(Mandatory)]$Change)
    if (-not (Test-AfChangeUndoable -Change $Change)) { return $Change }
    $user = Get-AfUserForSid -Sid $Session.User.Sid
    $result = Undo-AfRecords -Records @($Change.Records) -User $user
    $left = @($result.Failed)
    if ($left.Count) {
        $Change.Status = 'UndoFailed'
        $Change.Records = @($left)
        $Change.Message = (T 'No se pudo deshacer: {0}.') -f $result.Reason
    } else {
        $Change.Status = 'Undone'
        $Change.UndoneAt = (Get-Date).ToString('o')
        $Change.Message = $null
    }
    Write-AfLog -Level Info -Message ('Deshacer {0}: {1}' -f $Change.CheckId, $Change.Status)
    Save-AfSession -Session $Session
    $Change
}

function Get-AfOverlayName {
    param([string]$Guid)
    switch ($Guid) {
        '00000000-0000-0000-0000-000000000000' { (T 'Equilibrado') }
        '961cc777-2547-4f9d-8174-7d86181b8a7a' { (T 'Mejor eficiencia energética') }
        'ded574b5-45a0-4f42-8737-46345c09c238' { (T 'Mejor rendimiento') }
        default { (T 'Otro modo') }
    }
}

function Get-AfVendorModeName {
    param([string]$Tool)
    switch ($Tool) {
        'Armoury Crate' { 'Turbo' }
        'G-Helper' { 'Turbo' }
        'MSI Center' { 'Extreme Performance' }
        'NitroSense' { 'Turbo' }
        default { (T 'Rendimiento') }
    }
}

function Get-AfEnergyChecks {
    @{
        Id = 'energy.power-mode'; Category = 'energy'
        Title = (T 'Modo de energía en Mejor rendimiento')
        Why = (T 'Con el cargador puesto, Windows deja trabajar al procesador y a la gráfica sin recortes.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: modos de energía de Windows'); SourceUrl = 'https://support.microsoft.com/en-us/windows/change-the-power-mode-for-your-windows-pc-c2aff038-22c9-f46d-5ca0-78696fdf2de8'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Power -and $inv.Power.ActiveScheme }
        Detect = {
            param($inv)
            $balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
            $saver = 'a1841308-3541-4fab-bc81-f71556f20b4a'
            $best = 'ded574b5-45a0-4f42-8737-46345c09c238'
            $scheme = $inv.Power.ActiveScheme
            if ($scheme -eq $saver) {
                return New-AfDetection -State Improvable -Current (T 'Ahorro de energía') -Target (T 'Mejor rendimiento') -Note (T 'Solo con el cargador puesto') `
                    -What (T 'El plan pasa de Ahorro de energía a Equilibrado, y el modo con cargador a Mejor rendimiento. Con batería no cambia nada.')
            }
            # Los modos solo existen sobre el plan Equilibrado; otro plan es uno propio de alto rendimiento.
            if ($scheme -ne $balanced) { return New-AfDetection -State Ok -Current (T 'Plan de alto rendimiento') }
            $overlay = if ($inv.Power.OverlayAc) { $inv.Power.OverlayAc } else { '00000000-0000-0000-0000-000000000000' }
            if ($overlay -eq $best) { return New-AfDetection -State Ok -Current (T 'Mejor rendimiento') }
            $name = Get-AfOverlayName -Guid $overlay
            New-AfDetection -State Improvable -Current $name -Target (T 'Mejor rendimiento') -Note (T 'Solo con el cargador puesto') `
                -What ((T 'Modo de energía con cargador, de {0} a Mejor rendimiento. Con batería no cambia nada.') -f $name)
        }
        Apply = {
            param($inv, $detected, $tx)
            if ($inv.Power.ActiveScheme -eq 'a1841308-3541-4fab-bc81-f71556f20b4a') { Set-AfActivePowerScheme -Tx $tx -Guid '381b4222-f694-41f0-9685-ff5bb260df2e' | Out-Null }
            Set-AfPowerOverlay -Tx $tx -Guid 'ded574b5-45a0-4f42-8737-46345c09c238' | Out-Null
        }
    }

    @{
        Id = 'energy.vendor-mode'; Category = 'energy'
        Title = (T 'Modo de rendimiento del fabricante')
        Why = (T 'En estas laptops, los límites de potencia y los ventiladores los maneja la herramienta del fabricante, no Windows.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Herramienta del fabricante del equipo'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.VendorTools).Count -gt 0 }
        Detect = {
            param($inv)
            $tool = @($inv.VendorTools)[0]
            $mode = Get-AfVendorModeName -Tool $tool
            New-AfDetection -State Manual -Title ((T 'Modo {0} en {1}') -f $mode, $tool) -Current $tool `
                -Note ((T 'Los límites de potencia y los ventiladores los maneja {0}') -f $tool) `
                -Steps @(((T 'Abre {0}.') -f $tool), ((T 'Busca el modo de rendimiento y elige {0}.') -f $mode), (T 'Déjalo así mientras juegas con el cargador puesto.'))
        }
    }
}

function Get-AfDisplayLabel {
    param($Display, [int]$Index)
    if ($Display.IsPrimary) { (T 'Pantalla principal') } else { (T 'Pantalla {0}') -f ($Index + 1) }
}

# Pone SwapEffectUpgradeEnable=1 en la cadena de DirectX y conserva el resto de las claves.
function Get-AfWindowedOptimizationsValue {
    param([string]$Current)
    if ($Current -match 'SwapEffectUpgradeEnable=\d;') { return $Current -replace 'SwapEffectUpgradeEnable=\d;', 'SwapEffectUpgradeEnable=1;' }
    $base = if ($Current -and -not $Current.EndsWith(';')) { $Current + ';' } else { [string]$Current }
    $base + 'SwapEffectUpgradeEnable=1;'
}

function Get-AfGamingChecks {
    @{
        Id = 'display.refresh'; Category = 'gaming'
        Title = (T 'Pantalla a su frecuencia máxima')
        Why = (T 'Muchas pantallas de 144 Hz o más vienen puestas a 60 Hz; con más Hz el juego se ve y se siente más fluido.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: frecuencia de actualización de la pantalla'); SourceUrl = 'https://support.microsoft.com/en-us/windows/hardware/display-graphics/change-the-refresh-rate-on-your-monitor-in-windows'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Displays).Count -gt 0 }
        Detect = {
            param($inv)
            $displays = @($inv.Displays)
            $slow = @()
            for ($i = 0; $i -lt $displays.Count; $i++) {
                $d = $displays[$i]
                if ($d.MaxHzAtCurrentRes -gt $d.Hz) {
                    $slow += [pscustomobject]@{ Label = Get-AfDisplayLabel -Display $d -Index $i; DeviceName = $d.DeviceName; Width = $d.Width; Height = $d.Height; Hz = $d.Hz; MaxHz = $d.MaxHzAtCurrentRes }
                }
            }
            if (-not $slow.Count) { return New-AfDetection -State Ok -Current ('{0} Hz' -f $displays[0].Hz) }
            $first = $slow[0]
            New-AfDetection -State Improvable -Current ('{0} Hz' -f $first.Hz) -Target ('{0} Hz' -f $first.MaxHz) -Data @{ Displays = $slow } `
                -What ((T '{0} a {1} × {2}, de {3} a {4} Hz. Pregunta si se ve bien y vuelve sola al modo anterior a los 15 s si nadie responde.') -f $first.Label, $first.Width, $first.Height, $first.Hz, $first.MaxHz)
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($d in @($detected.Data.Displays)) { Set-AfDisplayMode -Tx $tx -DeviceName $d.DeviceName -Label $d.Label -Width $d.Width -Height $d.Height -Hz $d.MaxHz | Out-Null }
            Confirm-AfDisplayChange -Tx $tx
        }
    }

    @{
        Id = 'display.cable-limit'; Category = 'gaming'
        Title = (T 'El cable o el puerto limita la pantalla')
        Why = (T 'El monitor anuncia más Hz de los que Windows puede usar con esta conexión.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Datos EDID del monitor'); Undo = (T 'No cambia nada')
        # Con una gráfica sin driver, el límite es el driver básico, no el cable (lo dice gpu.driver-missing).
        AppliesTo = { param($inv) @($inv.Displays | Where-Object { $_.EdidMaxHz }).Count -gt 0 -and @($inv.Gpus | Where-Object { $_.HasDriver -eq $false }).Count -eq 0 }
        Detect = {
            param($inv)
            $limited = @($inv.Displays | Where-Object { $_.EdidMaxHz -and $_.EdidMaxHz -gt ($_.MaxHzAtCurrentRes + 1) }) | Select-Object -First 1
            if (-not $limited) { return New-AfDetection -State Ok }
            New-AfDetection -State Manual -Current ('{0} Hz' -f $limited.MaxHzAtCurrentRes) -Target ('{0} Hz' -f $limited.EdidMaxHz) `
                -Steps @((T 'Usa un cable DisplayPort, o HDMI 2.0 o superior.'), (T 'En laptops, conecta el monitor al puerto que va a la gráfica dedicada (suele ser el HDMI o un USB-C con DisplayPort).'), (T 'Revisa en el menú del monitor que la entrada no esté en un modo de compatibilidad.'))
        }
    }

    @{
        Id = 'gpu.hags'; Category = 'gaming'
        Title = (T 'Programación de GPU por hardware')
        Why = (T 'La gráfica organiza su propio trabajo y baja la latencia; DLSS Frame Generation la necesita.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Microsoft DirectX: programación de GPU por hardware'); SourceUrl = 'https://devblogs.microsoft.com/directx/hardware-accelerated-gpu-scheduling/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode')
        AppliesTo = { param($inv) $inv.Os.Build -ge 19041 -and @($inv.Gpus | Where-Object { $_.IsDiscrete -and $_.WddmVersion -ge 2.7 }).Count -gt 0 }
        Detect = {
            param($inv)
            $value = $inv.Registry['HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers|HwSchMode']
            if ($value -eq 2) { return New-AfDetection -State Ok -Current (T 'Activada') }
            $from = if ($null -eq $value) { (T 'sin valor') } else { $value }
            New-AfDetection -State Improvable -Current (T 'Apagada') -Target (T 'Activada') -What ((T 'HwSchMode pasa de {0} a 2. Pide reiniciar.') -f $from)
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -Type DWord -Value 2 | Out-Null }
    }

    @{
        Id = 'gaming.game-mode'; Category = 'gaming'
        Title = (T 'Modo de juego activado')
        Why = (T 'Windows da prioridad al juego y frena tareas de fondo como las actualizaciones mientras juegas.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: modo de juego'); SourceUrl = 'https://support.microsoft.com/en-us/help/4028293/windows-using-game-mode-on-your-pc'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled')
        Detect = {
            param($inv)
            $value = $inv.Registry['HKCU:\Software\Microsoft\GameBar|AutoGameModeEnabled']
            if ($null -eq $value -or $value -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'AutoGameModeEnabled pasa de 0 a 1.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Type DWord -Value 1 | Out-Null }
    }

    @{
        Id = 'gaming.background-recording'; Category = 'gaming'
        Title = (T 'Grabación en segundo plano apagada')
        Why = (T 'Con la grabación de fondo, Xbox Game Bar graba todo el tiempo y le quita rendimiento a la gráfica.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft, blog de Xbox: grabación en segundo plano'); SourceUrl = 'https://news.xbox.com/en-us/2016/10/14/tips-on-windows-10-and-game-dvr-optimization/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled')
        Detect = {
            param($inv)
            $value = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR|HistoricalCaptureEnabled']
            if ($value -ne 1) { return New-AfDetection -State Ok -Current (T 'Apagada') }
            New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Xbox Game Bar graba todo el tiempo') `
                -What (T 'Se apaga "Grabar lo que pasó" de Xbox Game Bar. Las capturas manuales siguen funcionando.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'HistoricalCaptureEnabled' -Type DWord -Value 0 | Out-Null }
    }

    @{
        Id = 'gaming.windowed-optimizations'; Category = 'gaming'
        Title = (T 'Optimizaciones para juegos en ventana')
        Why = (T 'Los juegos DirectX 10 y 11 en ventana o sin bordes usan el mismo camino rápido que en pantalla completa: menos latencia.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: optimizaciones para juegos en ventana'); SourceUrl = 'https://support.microsoft.com/en-us/windows/hardware/display-graphics/optimizations-for-windowed-games-in-windows-11'; Undo = (T 'Se puede deshacer')
        Reads = @('HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings')
        AppliesTo = { param($inv) $inv.Os.IsWin11 }
        Detect = {
            param($inv)
            $value = [string]$inv.Registry['HKCU:\Software\Microsoft\DirectX\UserGpuPreferences|DirectXUserGlobalSettings']
            if ($value -match 'SwapEffectUpgradeEnable=1;') { return New-AfDetection -State Ok -Current (T 'Activadas') }
            New-AfDetection -State Improvable -Current (T 'Apagadas') -Target (T 'Activadas') -What (T 'Se agrega SwapEffectUpgradeEnable=1 a la configuración de DirectX, sin tocar lo demás.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $path = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
            $current = [string](Get-AfRegistryValue -Path $path -Name 'DirectXUserGlobalSettings' -User $tx.User)
            Set-AfRegistryValue -Tx $tx -Path $path -Name 'DirectXUserGlobalSettings' -Type String -Value (Get-AfWindowedOptimizationsValue -Current $current) | Out-Null
        }
    }

    @{
        Id = 'gpu.driver-missing'; Category = 'gaming'
        Title = (T 'La gráfica no tiene su driver')
        Why = (T 'Sin su driver, Windows usa uno básico: los juegos casi no funcionan y la pantalla no llega a sus Hz.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Fabricante de la gráfica'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.Gpus).Count -gt 0 }
        Detect = {
            param($inv)
            $gpu = @($inv.Gpus | Where-Object { $_.HasDriver -eq $false })[0]
            if (-not $gpu) { return New-AfDetection -State Ok -Current (T 'Instalado') }
            $steps = switch ($gpu.Vendor) {
                'NVIDIA' { @((T 'Descarga NVIDIA App desde nvidia.com.'), (T 'Instala el driver Game Ready que proponga.'), (T 'Reinicia la PC.')) }
                'AMD' { @((T 'Descarga AMD Software: Adrenalin Edition desde amd.com; detecta la gráfica sola.'), (T 'Instala el driver recomendado.'), (T 'Reinicia la PC.')) }
                'Intel' { @((T 'Descarga Intel Driver & Support Assistant desde intel.com.'), (T 'Instala el driver de gráficos que proponga.'), (T 'Reinicia la PC.')) }
                default { @((T 'Abre Configuración, Windows Update, Opciones avanzadas, Actualizaciones opcionales, e instala el driver de pantalla.'), (T 'Si no aparece, descárgalo del sitio del fabricante de la PC.')) }
            }
            $title = if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { (T 'La gráfica de {0} no tiene su driver') -f $gpu.Vendor } else { (T 'La gráfica no tiene su driver') }
            New-AfDetection -State Manual -Title $title -Current (T 'Driver básico de Windows') -Target (T 'Driver del fabricante') -Steps $steps
        }
    }

    @{
        Id = 'gpu.driver-age'; Category = 'gaming'
        Title = (T 'Driver de gráficos al día')
        Why = (T 'Los drivers nuevos traen mejoras de rendimiento y arreglos para los juegos recientes.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Fabricante de la gráfica'); Undo = (T 'No cambia nada')
        # Solo gráficas con su driver; las que no lo tienen las ve gpu.driver-missing.
        AppliesTo = { param($inv) @($inv.Gpus | Where-Object { $_.HasDriver -ne $false }).Count -gt 0 }
        Detect = {
            param($inv)
            $gpus = @($inv.Gpus | Where-Object { $_.HasDriver -ne $false })
            $gpu = @($gpus | Where-Object IsDiscrete)[0]
            if (-not $gpu) { $gpu = $gpus[0] }
            if (-not $gpu.DriverDate) { return New-AfDetection -State NotApplicable }
            $days = ((Get-Date) - [datetime]$gpu.DriverDate).TotalDays
            if ($days -le 180) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $months = [math]::Floor($days / 30)
            $steps = switch ($gpu.Vendor) {
                'NVIDIA' { @((T 'Abre NVIDIA App.'), (T 'Entra a Controladores.'), (T 'Instala el Game Ready más reciente sin instalación limpia.')) }
                'AMD' { @((T 'Abre AMD Software: Adrenalin Edition.'), (T 'Entra a Controladores y software.'), (T 'Instala la versión recomendada.')) }
                'Intel' { @((T 'Abre Intel Driver & Support Assistant, o descárgalo de intel.com.'), (T 'Instala el driver de gráficos que proponga.')) }
                default { @((T 'Descarga el driver más reciente desde el sitio del fabricante de la gráfica.')) }
            }
            $who = if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { $gpu.Vendor } else { (T 'la gráfica') }
            New-AfDetection -State Manual -Title ((T 'Driver de {0} de hace {1} meses') -f $who, $months) -Current ((T 'Hace {0} meses') -f $months) -Steps $steps
        }
    }

    @{
        Id = 'gpu.hybrid'; Category = 'gaming'
        Title = (T 'Esta laptop tiene dos gráficas')
        Why = (T 'Si un juego corre en la gráfica integrada, rinde mucho menos.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: preferencia de gráficos por app'); SourceUrl = 'https://devblogs.microsoft.com/directx/navigating-the-redesigned-graphics-settings-page/'; Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device.IsLaptop -and @($inv.Gpus | Where-Object IsDiscrete).Count -gt 0 -and @($inv.Gpus | Where-Object { -not $_.IsDiscrete }).Count -gt 0 }
        Detect = {
            param($inv)
            New-AfDetection -State Info -Steps @((T 'Abre Configuración, Sistema, Pantalla, Gráficos.'), (T 'Elige cada juego y márcalo en Alto rendimiento.'), (T 'En NVIDIA App o en el panel de la gráfica, revisa que la dedicada sea la preferida.'))
        }
    }
}

function Join-AfNames {
    param([string[]]$Names)
    $unique = @($Names | Where-Object { $_ } | Select-Object -Unique)
    switch ($unique.Count) {
        0 { '' }
        1 { $unique[0] }
        default { ($unique[0..($unique.Count - 2)] -join ', ') + ' ' + (T 'y') + ' ' + $unique[-1] }
    }
}

# Programas que no hace falta arrancar con Windows (lista cerrada; Steam, Discord y el resto se muestran sin marcar).
function Get-AfStartupBloatName {
    param($Entry)
    $text = '{0} {1}' -f $Entry.Name, [System.IO.Path]::GetFileNameWithoutExtension([string]$Entry.Path)
    switch -Regex ($text) {
        'EpicGamesLauncher' { 'Epic Games'; break }
        'EADesktop' { 'EA app'; break }
        '\bOrigin\b' { 'Origin'; break }
        'UbisoftConnect|\bupc\b' { 'Ubisoft Connect'; break }
        'AdobeGCInvoker|CCXProcess|AdobeARM|Adobe Creative Cloud' { (T 'el actualizador de Adobe'); break }
        'Spotify' { 'Spotify'; break }
        'Skype' { 'Skype'; break }
        default { $null }
    }
}

function Get-AfStartupChecks {
    @{
        Id = 'startup.apps'; Category = 'startup'
        Title = (T 'Programas que arrancan con Windows')
        Why = (T 'Cada programa que arranca solo alarga el encendido y ocupa memoria mientras juegas.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: apps de inicio'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/startup-boot/configure-startup-applications-in-windows'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Startup).Count -gt 0 }
        Detect = {
            param($inv)
            # Cada entrada es también una opción del detalle: Selected empieza igual que Preselected y la interfaz lo cambia.
            $entries = @($inv.Startup | Where-Object Enabled | ForEach-Object {
                    $bloat = Get-AfStartupBloatName -Entry $_
                    [pscustomobject]@{
                        Name = $_.Name; Label = $_.Name; Path = $_.Path; Friendly = $bloat; Preselected = [bool]$bloat; Selected = [bool]$bloat
                        ApprovedKey = $_.ApprovedKey; ApprovedName = $_.ApprovedName
                    }
                })
            $bloat = @($entries | Where-Object Preselected)
            if (-not $bloat.Count) {
                $note = if ($entries.Count) { (T '{0} programas arrancan con Windows; ninguno sobra') -f $entries.Count } else { $null }
                return New-AfDetection -State Ok -Note $note -Data @{ Entries = $entries }
            }
            $title = if ($bloat.Count -eq 1) { (T '1 programa menos al arrancar') } else { (T '{0} programas menos al arrancar') -f $bloat.Count }
            $names = Join-AfNames @($bloat.Friendly)
            New-AfDetection -State Improvable -Title $title -Current $names -Data @{ Entries = $entries; Choices = $entries } `
                -What (T 'Se desactivan igual que en el Administrador de tareas los programas marcados abajo. Los demás siguen arrancando.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($choice in @($detected.Data.Choices | Where-Object Selected)) { Disable-AfStartupEntry -Tx $tx -Entry $choice | Out-Null }
        }
    }
}

function Get-AfEthernetPowerKeywords {
    [ordered]@{
        '*EEE' = 'Energy-Efficient Ethernet'
        'AdvancedEEE' = 'Advanced EEE'
        'EnableGreenEthernet' = 'Green Ethernet'
        'GigaLite' = 'Gigabit Lite'
        'PowerSavingMode' = 'Power Saving Mode'
    }
}

function Get-AfNetworkChecks {
    @{
        Id = 'network.ethernet-power'; Category = 'network'
        Title = (T 'Ethernet sin ahorro de energía')
        Why = (T 'El ahorro de energía del adaptador renegocia el enlace y puede meter pausas en la conexión.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'djdallmann, investigación de red'); SourceUrl = 'https://djdallmann.github.io/GamingPCSetup/CONTENT/RESEARCH/NETWORK'
        Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Network | Where-Object Kind -eq 'Ethernet').Count -gt 0 }
        Detect = {
            param($inv)
            $keywords = Get-AfEthernetPowerKeywords
            $changes = @()
            foreach ($nic in @($inv.Network | Where-Object Kind -eq 'Ethernet')) {
                foreach ($keyword in $keywords.Keys) {
                    if ($nic.Properties.ContainsKey($keyword) -and [string]$nic.Properties[$keyword] -ne '0') {
                        $changes += [pscustomobject]@{ Adapter = $nic.Name; Description = $nic.Description; Keyword = $keyword; Name = $keywords[$keyword] }
                    }
                }
            }
            if (-not $changes.Count) { return New-AfDetection -State Ok -Current (T 'Sin ahorro de energía') }
            $current = if ($changes.Count -eq 1) { (T '1 opción activa') } else { (T '{0} opciones activas') -f $changes.Count }
            New-AfDetection -State Improvable -Current $current -Target (T 'Apagadas') -Note (T 'La conexión se corta unos segundos al aplicar') -Data @{ Changes = $changes } `
                -What ((T '{0} del adaptador {1} pasan a apagado.') -f (Join-AfNames @($changes.Name)), $changes[0].Description)
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($change in @($detected.Data.Changes)) { Set-AfNetAdapterProperty -Tx $tx -Adapter $change.Adapter -Keyword $change.Keyword -Value '0' | Out-Null }
        }
    }

    @{
        Id = 'network.wifi-power'; Category = 'network'
        Title = (T 'Wi-Fi sin ahorro de energía')
        Why = (T 'Con el ahorro de energía, el adaptador inalámbrico se duerme entre paquetes y sube la latencia.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: ahorro de energía del Wi-Fi'); SourceUrl = 'https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/wi-fi-power-management-for-modern-standby-platforms'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) @($inv.Network | Where-Object Kind -eq 'WiFi').Count -gt 0 -and $null -ne $inv.Power.WifiPowerAc }
        Detect = {
            param($inv)
            $value = [int]$inv.Power.WifiPowerAc
            if ($value -eq 0) { return New-AfDetection -State Ok -Current (T 'Rendimiento máximo') }
            $name = switch ($value) { 1 { (T 'Ahorro bajo') } 2 { (T 'Ahorro medio') } default { (T 'Ahorro máximo') } }
            New-AfDetection -State Improvable -Current $name -Target (T 'Rendimiento máximo') -Note (T 'Solo con el cargador puesto') `
                -What ((T 'Plan de energía, adaptador inalámbrico con cargador: de {0} a Rendimiento máximo.') -f $name)
        }
        Apply = { param($inv, $detected, $tx) Set-AfPowerSetting -Tx $tx -Subgroup '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1' -Setting '12bbebe6-58d6-4636-95bb-3217ef867c1a' -Ac 0 | Out-Null }
    }

    @{
        Id = 'network.link-100'; Category = 'network'
        Title = (T 'La conexión por cable va a 100 Mbps')
        Why = (T 'El adaptador puede ir a 1 Gbps o más, pero el cable o el puerto lo limitan.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Velocidad de enlace del adaptador'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) @($inv.Network | Where-Object { $_.Kind -eq 'Ethernet' -and $_.Status -eq 'Up' }).Count -gt 0 }
        Detect = {
            param($inv)
            $slow = @($inv.Network | Where-Object { $_.Kind -eq 'Ethernet' -and $_.Status -eq 'Up' -and $_.LinkSpeedMbps -le 100 -and $_.MaxSpeedMbps -ge 1000 }) | Select-Object -First 1
            if (-not $slow) { return New-AfDetection -State Ok }
            New-AfDetection -State Manual -Current ('{0} Mbps' -f $slow.LinkSpeedMbps) -Target (T '1 Gbps') `
                -Steps @((T 'Cambia el cable por uno Cat 5e o mejor: los de 100 Mbps solo tienen 4 hilos.'), (T 'Prueba otro puerto del router o del switch.'), (T 'Si el router solo tiene puertos de 100 Mbps, ese es el límite.'))
        }
    }

    @{
        Id = 'network.wifi-band'; Category = 'network'
        Title = (T 'Wi-Fi en la banda de 2,4 GHz')
        Why = (T 'La banda de 5 GHz es más rápida y tiene menos interferencia, aunque llega un poco menos lejos.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Banda de la conexión Wi-Fi actual'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Wlan -and $inv.Wlan.Connected -and $inv.Wlan.BandGHz }
        Detect = {
            param($inv)
            if ($inv.Wlan.BandGHz -ge 5) { return New-AfDetection -State Ok -Current ('{0} GHz' -f $inv.Wlan.BandGHz) }
            New-AfDetection -State Info -Current (T '2,4 GHz') -Steps @((T 'Si el router tiene una red de 5 GHz, conéctate a esa para jugar.'))
        }
    }
}

function Format-AfSize {
    param([double]$Bytes)
    $culture = Get-AfCulture
    if ($Bytes -ge 1GB) { return ($Bytes / 1GB).ToString('0.0', $culture) + ' GB' }
    ([math]::Round($Bytes / 1MB)).ToString($culture) + ' MB'
}

function Get-AfStorageChecks {
    @{
        Id = 'storage.free-space'; Category = 'storage'
        Title = (T 'Poco espacio libre en el disco')
        Why = (T 'Windows y los juegos necesitan espacio libre para actualizarse y para su memoria virtual.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Espacio libre del disco del sistema'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.SizeGB }
        Detect = {
            param($inv)
            $free = [double]$inv.Storage.FreeGB
            $current = (T '{0} GB libres') -f [math]::Round($free)
            if ($free -ge 20 -and ($free / $inv.Storage.SizeGB) -ge 0.15) { return New-AfDetection -State Ok -Current $current }
            New-AfDetection -State Info -Current $current -Steps @((T 'Borra los temporales (abajo) y desinstala los juegos que ya no usas.'))
        }
    }

    @{
        Id = 'storage.temp'; Category = 'storage'
        Title = (T 'Borrar archivos temporales')
        Why = (T 'Temporales y cachés viejas ocupan espacio que Windows y los juegos necesitan.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: liberar espacio en el disco'); SourceUrl = 'https://support.microsoft.com/en-us/windows/experience/storage-filemanagement/free-up-drive-space-in-windows'; Undo = (T 'No se puede deshacer: solo borra temporales'); NoUndo = $true
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.TempBytes }
        Detect = {
            param($inv)
            $t = $inv.Storage.TempBytes
            $total = [double]($t.User + $t.Windows + $t.UpdateCache + $t.DeliveryOptimization + $t.ErrorReports)
            if ($total -lt 100MB) { return New-AfDetection -State Ok -Current (T 'Menos de 100 MB') }
            New-AfDetection -State Improvable -Current (Format-AfSize -Bytes $total) -Target (T 'Liberados') -Preselect ($total -gt 1GB) `
                -What (T 'Temporales de Windows y del usuario, y cachés de Windows Update y de Optimización de distribución.')
        }
        Apply = { param($inv, $detected, $tx) Clear-AfTempFiles -Tx $tx -Inventory $inv }
    }

    @{
        Id = 'storage.trim'; Category = 'storage'
        Title = (T 'TRIM del SSD activado')
        Why = (T 'Con TRIM, el SSD sabe qué bloques puede limpiar y mantiene su velocidad con el tiempo.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft: fsutil behavior DisableDeleteNotify'); SourceUrl = 'https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Storage -and $inv.Storage.MediaType -eq 'SSD' -and $null -ne $inv.Storage.TrimEnabled }
        Detect = {
            param($inv)
            if ($inv.Storage.TrimEnabled) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'DisableDeleteNotify de NTFS pasa de 1 a 0.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfTrim -Tx $tx -Enabled $true | Out-Null }
    }
}

function Get-AfRatedMemorySpeed {
    param([string]$PartNumber)
    # Velocidad que suele ir en el número de parte (F4-3200C16, CMK16GX4M2B3200C16): de 2400 a 8999.
    $speeds = @([regex]::Matches([string]$PartNumber, '(?<!\d)(2[4-9]\d{2}|[3-8]\d{3})(?!\d)') | ForEach-Object { [int]$_.Value })
    if ($speeds.Count) { ($speeds | Measure-Object -Maximum).Maximum } else { $null }
}

function Get-AfHardwareChecks {
    @{
        Id = 'hardware.ram-single-channel'; Category = 'hardware'
        Title = (T 'RAM en un solo canal')
        Why = (T 'Con un solo módulo la RAM rinde la mitad: en juegos se nota, sobre todo con gráficos integrados.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Configuración de módulos de memoria'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Memory -and $inv.Memory.Socketed }
        Detect = {
            param($inv)
            $modules = @($inv.Memory.Modules)
            if ($modules.Count -ne 1) { return New-AfDetection -State Ok -Current ((T '{0} módulos') -f $modules.Count) }
            $m = $modules[0]
            New-AfDetection -State Manual -Current ((T '{0} GB en un módulo') -f $m.CapacityGB) -Target (T 'Dos módulos iguales') `
                -Steps @(((T 'Compra un módulo igual al actual: {0} GB a {1} MT/s.') -f $m.CapacityGB, $m.Speed), (T 'Instálalo en la ranura libre.'), (T 'Con dos módulos la RAM trabaja en doble canal.'))
        }
    }

    @{
        Id = 'hardware.ram-xmp'; Category = 'hardware'
        Title = (T 'XMP o EXPO apagado')
        Why = (T 'La RAM está trabajando más lento de lo que permite: el perfil de velocidad se activa en la BIOS.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Velocidad de la memoria contra su número de parte'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device -and -not $inv.Device.IsLaptop -and $inv.Memory -and $inv.Memory.Socketed }
        Detect = {
            param($inv)
            $m = @($inv.Memory.Modules)[0]
            $rated = Get-AfRatedMemorySpeed -PartNumber $m.PartNumber
            if (-not $rated -or $rated -le ($m.ConfiguredSpeed + 100)) { return New-AfDetection -State Ok -Current ('{0} MT/s' -f $m.ConfiguredSpeed) }
            New-AfDetection -State Manual -Current ('{0} MT/s' -f $m.ConfiguredSpeed) -Target ('{0} MT/s' -f $rated) `
                -Steps @((T 'Entra a la BIOS: suele ser con Supr o F2 al encender.'), (T 'Activa XMP (Intel) o EXPO (AMD) en las opciones de memoria.'), (T 'Guarda y reinicia.'))
        }
    }

    @{
        Id = 'hardware.ram-low'; Category = 'hardware'
        Title = (T 'Poca memoria RAM')
        Why = (T 'Con poca RAM, Windows usa el disco como memoria y los juegos se traban.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Memoria instalada'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Memory -and $inv.Memory.TotalGB }
        Detect = {
            param($inv)
            $current = '{0} GB' -f $inv.Memory.TotalGB
            if ($inv.Memory.TotalGB -gt 8) { return New-AfDetection -State Ok -Current $current }
            New-AfDetection -State Info -Current $current -Steps @((T 'Para jugar hoy se recomiendan 16 GB.'))
        }
    }

    @{
        Id = 'hardware.on-battery'; Category = 'hardware'
        Title = (T 'Laptop en batería')
        Why = (T 'En batería, Windows y el fabricante recortan la potencia para que dure más.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Estado de la batería'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Device -and $inv.Device.IsLaptop }
        Detect = {
            param($inv)
            if (-not $inv.Device.OnBattery) { return New-AfDetection -State Ok -Current (T 'Con cargador') }
            New-AfDetection -State Info -Current (T 'En batería') -Steps @((T 'Conecta el cargador para jugar y para que este análisis refleje el rendimiento real.'))
        }
    }
}

function Get-AfFirewallProfileName {
    param([string]$Profile)
    switch ($Profile) { 'Domain' { (T 'Dominio') } 'Private' { (T 'Privado') } 'Public' { (T 'Público') } default { $Profile } }
}

function Test-AfDefenderActive {
    param($Inventory)
    $s = $Inventory.Security
    $s -and $s.Defender.Available -and (@($s.Antivirus | Where-Object { $_.Enabled -and -not $_.IsDefender }).Count -eq 0)
}

function Get-AfSecurityChecks {
    @{
        Id = 'security.antivirus'; Category = 'security'
        Title = (T 'Antivirus activo')
        Why = (T 'Sin protección en tiempo real, cualquier descarga o mod puede infectar la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Centro de seguridad de Windows'); Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $null -ne $inv.Security }
        Detect = {
            param($inv)
            $active = @($inv.Security.Antivirus | Where-Object { $_.Enabled -and $_.UpToDate })
            if ($active.Count) { return New-AfDetection -State Ok -Current (Join-AfNames @($active.Name)) }
            $outdated = @($inv.Security.Antivirus | Where-Object { $_.Enabled -and -not $_.UpToDate -and -not $_.IsDefender }) | Select-Object -First 1
            if ($outdated) {
                return New-AfDetection -State Manual -Title ((T '{0} no está al día') -f $outdated.Name) -Current $outdated.Name -Steps @(((T 'Abre {0} y busca actualizaciones.') -f $outdated.Name))
            }
            if ($inv.Security.Defender.Available -and -not $inv.Security.Defender.RealTime) {
                return New-AfDetection -State Improvable -Current (T 'Sin protección activa') -Target (T 'Defender en tiempo real') -What (T 'Se enciende la protección en tiempo real de Microsoft Defender.')
            }
            if ($inv.Security.Defender.Available) { return New-AfDetection -State Ok -Current (T 'Microsoft Defender') }
            New-AfDetection -State Manual -Title (T 'No hay antivirus activo') -Steps @((T 'Abre Seguridad de Windows, Protección contra virus y amenazas, y actívala.'), (T 'Si usas otro antivirus, revisa que esté encendido y al día.'))
        }
        Apply = { param($inv, $detected, $tx) Enable-AfDefenderRealtime -Tx $tx }
    }

    @{
        Id = 'security.signatures'; Category = 'security'
        Title = (T 'Firmas de Microsoft Defender al día')
        Why = (T 'Con firmas viejas, Defender no reconoce las amenazas recientes.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft Defender: actualizaciones de firmas'); SourceUrl = 'https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-antivirus-updates'; Undo = (T 'No se deshace: solo descarga firmas nuevas')
        AppliesTo = { param($inv) Test-AfDefenderActive $inv }
        Detect = {
            param($inv)
            $age = [int]$inv.Security.Defender.SignatureAgeDays
            if ($age -le 3) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $current = if ($age -eq 1) { (T 'Hace 1 día') } else { (T 'Hace {0} días') -f $age }
            New-AfDetection -State Improvable -Current $current -Target (T 'Al día') -What (T 'Se descargan las firmas nuevas de Microsoft Defender.')
        }
        Apply = { param($inv, $detected, $tx) Update-AfDefenderSignatures -Tx $tx }
    }

    @{
        Id = 'security.threats'; Category = 'security'
        Title = (T 'Amenazas activas')
        Why = (T 'Defender encontró algo que sigue en la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Manual'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft Defender: amenazas detectadas'); SourceUrl = 'https://learn.microsoft.com/en-us/powershell/module/defender/get-mpthreat'; Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $inv.Security -and $inv.Security.Defender.Available }
        Detect = {
            param($inv)
            $active = @($inv.Security.Defender.Threats | Where-Object Active)
            if (-not $active.Count) { return New-AfDetection -State Ok -Current (T 'Sin amenazas activas') }
            $title = if ($active.Count -eq 1) { (T '1 amenaza activa') } else { (T '{0} amenazas activas') -f $active.Count }
            New-AfDetection -State Manual -Title $title -Current $active[0].Name -Note $active[0].Path -Data @{ Threats = $active } `
                -Steps @((T 'Abre Seguridad de Windows, Protección contra virus y amenazas.'), (T 'En Amenazas actuales, quita o pon en cuarentena cada una.'))
        }
    }

    @{
        Id = 'security.pua'; Category = 'security'
        Title = (T 'Bloqueo de aplicaciones no deseadas')
        Why = (T 'Defender frena los instaladores que meten adware o barras en el navegador.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Microsoft Defender: protección contra aplicaciones potencialmente no deseadas'); SourceUrl = 'https://learn.microsoft.com/en-us/defender-endpoint/detect-block-potentially-unwanted-apps-microsoft-defender-antivirus'; Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) Test-AfDefenderActive $inv }
        Detect = {
            param($inv)
            if ($inv.Security.Defender.PuaProtection -eq 1) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'PUAProtection pasa a 1: Defender bloquea instaladores con adware.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfMpPreference -Tx $tx -Name 'PUAProtection' -Value 1 | Out-Null }
    }

    @{
        Id = 'security.firewall'; Category = 'security'
        Title = (T 'Firewall de Windows activado')
        Why = (T 'Sin firewall, cualquier programa o equipo de la red puede intentar conectarse a la PC.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $false
        Source = (T 'Firewall de Windows'); Undo = (T 'Se puede deshacer')
        AppliesTo = { param($inv) $inv.Security -and @($inv.Security.Firewall).Count -gt 0 -and -not $inv.Security.ThirdPartyFirewall }
        Detect = {
            param($inv)
            $off = @($inv.Security.Firewall | Where-Object { -not $_.Enabled })
            if (-not $off.Count) { return New-AfDetection -State Ok -Current (T 'Activado') }
            $names = Join-AfNames @($off | ForEach-Object { Get-AfFirewallProfileName -Profile $_.Profile })
            New-AfDetection -State Improvable -Current ((T 'Apagado en {0}') -f $names) -Target (T 'Activado') -What ((T 'Se activa el Firewall de Windows en: {0}.') -f $names) -Data @{ Profiles = @($off.Profile) }
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($name in @($detected.Data.Profiles)) { Set-AfFirewallProfile -Tx $tx -Profile $name -Enabled $true | Out-Null }
        }
    }

    @{
        Id = 'security.uac'; Category = 'security'
        Title = (T 'Control de cuentas de usuario')
        Why = (T 'Sin él, cualquier programa puede hacer cambios de administrador sin pedir permiso.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $true; NeedsReboot = $true
        Source = (T 'Microsoft: Control de cuentas de usuario'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/security/application-security/application-control/user-account-control/'; Undo = (T 'Se puede deshacer')
        Reads = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA')
        Detect = {
            param($inv)
            if ($inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System|EnableLUA'] -ne 0) { return New-AfDetection -State Ok -Current (T 'Activado') }
            New-AfDetection -State Improvable -Current (T 'Apagado') -Target (T 'Activado') -What (T 'EnableLUA pasa de 0 a 1. Pide reiniciar.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'EnableLUA' -Type DWord -Value 1 | Out-Null }
    }

    @{
        Id = 'security.unsigned-autostart'; Category = 'security'
        Title = (T 'Programas sin firma que arrancan solos')
        Why = (T 'Casi todo el software legítimo está firmado; lo que arranca solo y sin firma merece una mirada.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Info'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Firmas Authenticode de los ejecutables'); Undo = (T 'No cambia nada')
        AppliesTo = { param($inv) $null -ne $inv.Autostart }
        Detect = {
            param($inv)
            $items = @($inv.Autostart | Where-Object { -not $_.IsSigned -and $_.Path })
            if (-not $items.Count) { return New-AfDetection -State Ok -Current (T 'Todos firmados') }
            $title = if ($items.Count -eq 1) { (T '1 programa sin firma arranca solo') } else { (T '{0} programas sin firma arrancan solos') -f $items.Count }
            New-AfDetection -State Info -Title $title -Current (Join-AfNames @($items.Name | Select-Object -First 3)) -Data @{ Items = $items } `
                -Steps @((T 'Revisa la lista: si no reconoces alguno, consúltalo en VirusTotal desde "Analizar seguridad".'))
        }
    }
}

function Get-AfAdsReads {
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    @(
        "$cdm|SilentInstalledAppsEnabled"
        "$cdm|SystemPaneSuggestionsEnabled"
        "$cdm|SubscribedContent-338388Enabled"
        "$cdm|SubscribedContent-338389Enabled"
        "$cdm|SubscribedContent-353694Enabled"
        "$cdm|SubscribedContent-353696Enabled"
        "$cdm|SoftLandingEnabled"
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo|Enabled'
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced|Start_IrisRecommendations'
    )
}

function Get-AfOptionalChecks {
    @{
        Id = 'updates.windows'; Category = 'optional'
        Title = (T 'Actualizaciones de Windows')
        Why = (T 'Traen arreglos de seguridad y a veces drivers nuevos.')
        Impact = 'High'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Windows Update'); Undo = (T 'No se puede deshacer desde Afina; se desinstalan en Configuración'); NoUndo = $true
        Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Buscando actualizaciones…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $updates = Find-AfWindowsUpdates
            if ($updates.Reason) { return New-AfDetection -State Error -Note $updates.Reason }
            if (-not $updates.Count) { return New-AfDetection -State Ok -Current (T 'Al día') }
            $current = if ($updates.Count -eq 1) { '1 disponible' } else { (T '{0} disponibles') -f $updates.Count }
            New-AfDetection -State Improvable -Current $current -Target (T 'Instaladas') -Note (T 'Puede tardar unos minutos') -Data @{ Titles = $updates.Titles } `
                -What (T 'Descarga e instala las actualizaciones que Windows instalaría solo, con su avance. No incluye versiones nuevas de Windows.')
        }
        Apply = { param($inv, $detected, $tx) Install-AfWindowsUpdates -Tx $tx | Out-Null }
    }

    @{
        Id = 'updates.apps'; Category = 'optional'
        Title = (T 'Apps con actualización')
        Why = (T 'Las apps al día corrigen fallos y huecos de seguridad.')
        Impact = 'Medium'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'winget'); Undo = (T 'No se puede deshacer desde Afina'); NoUndo = $true
        Async = $true
        Detect = { param($inv) New-AfDetection -State Info -Current (T 'Buscando actualizaciones de apps…') -Data @{ Async = $true } }
        AsyncDetect = {
            param($inv)
            $result = Get-AfWingetUpgrades
            if (-not $result.Available) { return New-AfDetection -State NotApplicable -Note (T 'winget no está instalado') }
            if ($result.TimedOut) { return New-AfDetection -State Error -Note (T 'winget no respondió a tiempo') }
            $apps = @($result.Apps)
            if (-not $apps.Count) { return New-AfDetection -State Ok -Current (T 'Al día') }
            # Cada app es una opción del detalle; al marcar la fila se eligen todas.
            $choices = @($apps | ForEach-Object {
                    [pscustomobject]@{ Name = $_.Name; Id = $_.Id; Source = $_.Source; Label = ('{0} ({1} → {2})' -f $_.Name, $_.Version, $_.Available); Preselected = $true; Selected = $false }
                })
            New-AfDetection -State Improvable -Current (Join-AfNames @($apps.Name | Select-Object -First 3)) -Target (T 'Actualizadas') -Note (T 'Cierra las apps antes de actualizarlas') `
                -Data @{ Apps = $apps; Choices = $choices; ChoicesLabel = (T 'Apps') } `
                -Title $(if ($apps.Count -eq 1) { (T '1 app con actualización') } else { (T '{0} apps con actualización') -f $apps.Count }) `
                -What (T 'Actualiza las apps elegidas con winget, sin ventanas.')
        }
        Apply = { param($inv, $detected, $tx) Update-AfWingetApps -Tx $tx -Apps @($detected.Data.Choices | Where-Object { $_.Selected }) | Out-Null }
    }

    @{
        Id = 'advanced.memory-integrity'; Category = 'optional'
        Title = (T 'Integridad de memoria apagada')
        Why = (T 'Microsoft reconoce que en algunos equipos baja el rendimiento en juegos.')
        Impact = 'Medium'; Risk = 'Advanced'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: virtualización y rendimiento en juegos'); SourceUrl = 'https://support.microsoft.com/en-us/topic/a255f612-2949-4373-a566-ff6f3f474613'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Enabled'
            'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity|Locked'
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard|HypervisorEnforcedCodeIntegrity'
        )
        AppliesTo = { param($inv) $null -ne $inv.Security }
        Detect = {
            param($inv)
            $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
            $enabled = $inv.Registry["$key|Enabled"]
            # Con bloqueo UEFI o activada por directiva, cambiar Enabled no hace nada.
            $locked = $inv.Registry["$key|Locked"] -eq 1
            $policy = $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard|HypervisorEnforcedCodeIntegrity'] -in 1, 2
            if ($inv.Security.HvciRunning) {
                if ($locked -or $policy) {
                    return New-AfDetection -State Manual -Current (T 'Activa') -Note (T 'Bloqueada por UEFI o por una directiva') -Steps @(
                        (T 'Abre Seguridad de Windows > Seguridad del dispositivo > Aislamiento del núcleo.')
                        (T 'Si el interruptor está gris, la activó una directiva de la organización: se quita desde ahí.')
                        (T 'Si tiene bloqueo UEFI, Microsoft indica que para apagarla hay que desactivar el arranque seguro desde la BIOS.')
                    )
                }
                if ($enabled -eq 0) { return New-AfDetection -State Info -Current (T 'Se apaga al reiniciar') }
                return New-AfDetection -State Improvable -Current (T 'Activa') -Target (T 'Apagada') -Note (T 'Puede dar más FPS, pero baja la seguridad') `
                    -What (T 'Apaga la protección de Windows contra drivers maliciosos. Pide reiniciar.')
            }
            if ($enabled -eq 1) { return New-AfDetection -State Info -Current (T 'Se activa al reiniciar') }
            New-AfDetection -State Ok -Current (T 'Apagada')
        }
        Apply = {
            param($inv, $detected, $tx)
            Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -Name 'Enabled' -Type DWord -Value 0 | Out-Null
        }
    }

    @{
        Id = 'advanced.vm-platform'; Category = 'optional'
        Title = (T 'Plataforma de máquina virtual apagada')
        Why = (T 'Microsoft reconoce que junto con la integridad de memoria puede bajar el rendimiento en juegos.')
        Impact = 'Medium'; Risk = 'Advanced'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $true
        Source = (T 'Microsoft: virtualización y rendimiento en juegos'); SourceUrl = 'https://support.microsoft.com/en-us/topic/a255f612-2949-4373-a566-ff6f3f474613'
        Undo = (T 'Se puede deshacer')
        AppliesTo = {
            param($inv)
            $vmp = if ($inv.Security) { $inv.Security.VmPlatform }
            [bool]($vmp -and ($vmp.State -eq 'Enabled' -or $vmp.Pending) -and -not $inv.Security.UsesVirtualization)
        }
        Detect = {
            param($inv)
            $vmp = $inv.Security.VmPlatform
            if ($vmp.Pending) { return New-AfDetection -State Info -Current $(if ($vmp.State -eq 'Enabled') { (T 'Se activa al reiniciar') } else { (T 'Se apaga al reiniciar') }) }
            New-AfDetection -State Improvable -Current (T 'Activada') -Target (T 'Apagada') -Note (T 'WSL, Docker y los emuladores de Android dejarían de funcionar') `
                -What (T 'Se desactiva la característica VirtualMachinePlatform. Pide reiniciar.')
        }
        Apply = { param($inv, $detected, $tx) Set-AfWindowsFeature -Tx $tx -Name 'VirtualMachinePlatform' -Enabled $false | Out-Null }
    }

    @{
        Id = 'cleanup.promo-apps'; Category = 'optional'
        Title = (T 'Apps promocionales preinstaladas')
        Why = (T 'Vienen con Windows, ocupan espacio y algunas se actualizan solas en segundo plano.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Lista cerrada de apps promocionales'); Undo = (T 'Se vuelven a instalar; algunas desde la Microsoft Store, con internet')
        AppliesTo = { param($inv) $null -ne $inv.Apps }
        Detect = {
            param($inv)
            # Quitarlas se hace para la cuenta del proceso: con otra cuenta elevada no se podrían volver a registrar para el dueño.
            if ($inv.User -and -not $inv.User.IsSameAsProcess) { return New-AfDetection -State NotApplicable -Note (T 'Abre Afina con la cuenta del dueño para quitarlas') }
            $promo = @($inv.Apps.Promo)
            if (-not $promo.Count) { return New-AfDetection -State Ok -Current (T 'Ninguna') }
            $choices = @($promo | ForEach-Object {
                    $restorable = [bool]($_.Provisioned -or $_.StoreId)
                    [pscustomobject]@{
                        Name = $_.Name; PackageName = $_.PackageName; PackageFullName = $_.PackageFullName; PackageFamilyName = $_.PackageFamilyName; StoreId = $_.StoreId
                        Label = $(if ($restorable) { $_.Name } else { (T '{0} (no se puede reinstalar)') -f $_.Name }); Preselected = $restorable; Selected = $false
                    }
                })
            New-AfDetection -State Improvable -Current (Join-AfNames @($promo.Name)) -Target (T 'Quitadas') -Data @{ Apps = $promo; Choices = $choices; ChoicesLabel = (T 'Apps') } `
                -Title $(if ($promo.Count -eq 1) { '1 app promocional' } else { (T '{0} apps promocionales') -f $promo.Count }) `
                -What (T 'Se quitan para esta cuenta con Remove-AppxPackage.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($app in @($detected.Data.Choices | Where-Object { $_.Selected })) { Remove-AfAppxPackage -Tx $tx -App $app | Out-Null }
        }
    }

    @{
        Id = 'cleanup.ads'; Category = 'optional'
        Title = (T 'Sin anuncios ni sugerencias de Windows')
        Why = (T 'Windows muestra sugerencias en Inicio, la pantalla de bloqueo y Configuración, e instala apps promocionadas.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Configuración de privacidad de Windows'); Undo = (T 'Se puede deshacer')
        Reads = Get-AfAdsReads
        Detect = {
            param($inv)
            $on = @(Get-AfAdsReads | Where-Object { $inv.Registry[$_] -ne 0 })
            if (-not $on.Count) { return New-AfDetection -State Ok -Current (T 'Apagados') }
            New-AfDetection -State Improvable -Current ((T '{0} opciones activas') -f $on.Count) -Target (T 'Apagadas') -Note (T 'Inicio, pantalla de bloqueo y Configuración') -Data @{ Values = $on } `
                -What (T 'Se apagan las sugerencias, las apps promocionadas que se instalan solas y el ID de publicidad.')
        }
        Apply = {
            param($inv, $detected, $tx)
            foreach ($read in @($detected.Data.Values)) {
                $path, $name = $read -split '\|', 2
                Set-AfRegistryValue -Tx $tx -Path $path -Name $name -Type DWord -Value 0 | Out-Null
            }
        }
    }

    @{
        Id = 'cleanup.diagnostics'; Category = 'optional'
        Title = (T 'Datos de diagnóstico al mínimo')
        Why = (T 'Windows manda menos datos de uso a Microsoft y deja de personalizar sugerencias con ellos.')
        Impact = 'Low'; Risk = 'Safe'; Kind = 'Auto'; Preselect = $false; NeedsReboot = $false
        Source = (T 'Microsoft: datos de diagnóstico de Windows'); SourceUrl = 'https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization'
        Undo = (T 'Se puede deshacer')
        Reads = @(
            'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection|AllowTelemetry'
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled'
        )
        AppliesTo = { param($inv) -not $inv.Os.IsInsider }
        Detect = {
            param($inv)
            $policy = $inv.Registry['HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection|AllowTelemetry']
            # La elección de Configuración (no es una directiva, aunque la clave se llame Policies).
            $setting = $inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry']
            $tailored = $inv.Registry['HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy|TailoredExperiencesWithDiagnosticDataEnabled']
            $level = if ($null -ne $policy) { $policy } else { $setting }
            $levelOk = $null -ne $level -and $level -le 1
            if ($levelOk -and $tailored -eq 0) { return New-AfDetection -State Ok -Current (T 'Mínimo') }
            # Afina no escribe directivas.
            if ($null -ne $policy) { return New-AfDetection -State Info -Current $(if ($levelOk) { (T 'Mínimo') } else { (T 'Opcionales') }) -Note (T 'Lo fija una directiva de la organización') }
            New-AfDetection -State Improvable -Current $(if ($levelOk) { (T 'Con experiencias personalizadas') } else { (T 'Opcionales') }) -Target (T 'Mínimo') `
                -What (T 'Datos de diagnóstico obligatorios (el mínimo que ofrece Configuración) y sin experiencias personalizadas.')
        }
        Apply = {
            param($inv, $detected, $tx)
            $level = $inv.Registry['HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection|AllowTelemetry']
            if ($null -eq $level -or $level -gt 1) { Set-AfRegistryValue -Tx $tx -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -Type DWord -Value 1 | Out-Null }
            Set-AfRegistryValue -Tx $tx -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Type DWord -Value 0 | Out-Null
        }
    }
}

# Generado por tools\Export-PhosphorIcons.ps1. No editar a mano.
# Iconos: Phosphor Icons 2.1.1 (https://phosphoricons.com). Licencia MIT.
# Copyright (c) 2023 Phosphor Icons. Se permite usar, copiar, modificar y distribuir con este aviso.
$script:AfIcons = @{
    'lightning|Bold' = 'F1 M219.71,117.38a12,12,0,0,0-7.25-8.52L161.28,88.39l10.59-70.61a12,12,0,0,0-20.64-10l-112,120a12,12,0,0,0,4.31,19.33l51.18,20.47L84.13,238.22a12,12,0,0,0,20.64,10l112-120A12,12,0,0,0,219.71,117.38ZM113.6,203.55l6.27-41.77a12,12,0,0,0-7.41-12.92L68.74,131.37,142.4,52.45l-6.27,41.77a12,12,0,0,0,7.41,12.92l43.72,17.49Z'
    'game-controller|Bold' = 'F1 M176,116H152a12,12,0,0,1,0-24h24a12,12,0,0,1,0,24ZM104,92h-4V88a12,12,0,0,0-24,0v4H72a12,12,0,0,0,0,24h4v4a12,12,0,0,0,24,0v-4h4a12,12,0,0,0,0-24ZM244.76,202.94a40,40,0,0,1-61,5.35,7,7,0,0,1-.53-.56L144.67,164H111.33L72.81,207.73c-.17.19-.35.38-.53.56A40,40,0,0,1,4.62,173.05a1.18,1.18,0,0,1,0-.2L21,88.79A63.88,63.88,0,0,1,83.88,36H172a64.08,64.08,0,0,1,62.93,52.48,1.8,1.8,0,0,1,0,.19l16.36,84.17a1.77,1.77,0,0,1,0,.2A39.74,39.74,0,0,1,244.76,202.94ZM172,140a40,40,0,0,0,0-80H83.89A39.9,39.9,0,0,0,44.62,93.06a1.55,1.55,0,0,0,0,.21l-16.34,84a16,16,0,0,0,13,18.44,16.07,16.07,0,0,0,13.86-4.21L96.9,144.07a12,12,0,0,1,9-4.07Zm55.76,37.31-7-35.95a63.84,63.84,0,0,1-44.27,22.46l24.41,27.72a16,16,0,0,0,26.85-14.23Z'
    'wifi-high|Bold' = 'F1 M144,204a16,16,0,1,1-16-16A16,16,0,0,1,144,204ZM239.61,83.91a176,176,0,0,0-223.22,0,12,12,0,1,0,15.23,18.55,152,152,0,0,1,192.76,0,12,12,0,1,0,15.23-18.55Zm-32.16,35.73a128,128,0,0,0-158.9,0,12,12,0,0,0,14.9,18.81,104,104,0,0,1,129.1,0,12,12,0,0,0,14.9-18.81ZM175.07,155.3a80.05,80.05,0,0,0-94.14,0,12,12,0,0,0,14.14,19.4,56,56,0,0,1,65.86,0,12,12,0,1,0,14.14-19.4Z'
    'rocket-launch|Bold' = 'F1 M227.85,46.89a20,20,0,0,0-18.74-18.74c-13.13-.77-46.65.42-74.48,28.24L131,60H74.36a19.83,19.83,0,0,0-14.14,5.86L25.87,100.19a20,20,0,0,0,11.35,33.95l37.14,5.18,42.32,42.32,5.19,37.18A19.88,19.88,0,0,0,135.34,235a20.13,20.13,0,0,0,6.37,1,19.9,19.9,0,0,0,14.1-5.87l34.34-34.35A19.85,19.85,0,0,0,196,181.64V125l3.6-3.59C227.43,93.54,228.62,60,227.85,46.89ZM76,84h31L75.75,115.28l-27.23-3.8ZM151.6,73.37A72.27,72.27,0,0,1,204,52a72.17,72.17,0,0,1-21.38,52.41L128,159,97,128ZM172,180l-27.49,27.49-3.8-27.23L172,149Zm-72,22c-8.71,11.85-26.19,26-60,26a12,12,0,0,1-12-12c0-33.84,14.12-51.32,26-60A12,12,0,1,1,68.18,175.3C62.3,179.63,55.51,187.8,53,203c15.21-2.51,23.37-9.3,27.7-15.18A12,12,0,1,1,100,202Z'
    'hard-drives|Bold' = 'F1 M208,36H48A20,20,0,0,0,28,56V200a20,20,0,0,0,20,20H208a20,20,0,0,0,20-20V56A20,20,0,0,0,208,36Zm-4,24v56H52V60ZM52,196V140H204v56ZM160,88a16,16,0,1,1,16,16A16,16,0,0,1,160,88Zm32,80a16,16,0,1,1-16-16A16,16,0,0,1,192,168Z'
    'shield-check|Bold' = 'F1 M208,36H48A20,20,0,0,0,28,56v56c0,54.29,26.32,87.22,48.4,105.29,23.71,19.39,47.44,26,48.44,26.29a12.1,12.1,0,0,0,6.32,0c1-.28,24.73-6.9,48.44-26.29,22.08-18.07,48.4-51,48.4-105.29V56A20,20,0,0,0,208,36Zm-4,76c0,35.71-13.09,64.69-38.91,86.15A126.28,126.28,0,0,1,128,219.38a126.14,126.14,0,0,1-37.09-21.23C65.09,176.69,52,147.71,52,112V60H204ZM79.51,144.49a12,12,0,1,1,17-17L112,143l47.51-47.52a12,12,0,0,1,17,17l-56,56a12,12,0,0,1-17,0Z'
    'wrench|Bold' = 'F1 M230.47,67.5a12,12,0,0,0-19.26-4.32L172.43,99l-12.68-2.72L157,83.57l35.79-38.78a12,12,0,0,0-4.32-19.26A76.07,76.07,0,0,0,88.41,121.64L30.92,174.18a4.68,4.68,0,0,0-.39.38,36,36,0,0,0,50.91,50.91l.38-.39,52.54-57.49A76.05,76.05,0,0,0,230.47,67.5ZM160,148a51.5,51.5,0,0,1-23.35-5.52,12,12,0,0,0-14.26,2.62L64.31,208.66a12,12,0,0,1-17-17l63.55-58.07a12,12,0,0,0,2.62-14.26A51.5,51.5,0,0,1,108,96a52.06,52.06,0,0,1,52-52h.89L135.17,71.87a12,12,0,0,0-2.91,10.65l5.66,26.35a12,12,0,0,0,9.21,9.21l26.35,5.66a12,12,0,0,0,10.65-2.91L212,95.12c0,.3,0,.59,0,.89A52.06,52.06,0,0,1,160,148Z'
    'sliders-horizontal|Bold' = 'F1 M40,92H70.06a36,36,0,0,0,67.88,0H216a12,12,0,0,0,0-24H137.94a36,36,0,0,0-67.88,0H40a12,12,0,0,0,0,24Zm64-24A12,12,0,1,1,92,80,12,12,0,0,1,104,68Zm112,96H201.94a36,36,0,0,0-67.88,0H40a12,12,0,0,0,0,24h94.06a36,36,0,0,0,67.88,0H216a12,12,0,0,0,0-24Zm-48,24a12,12,0,1,1,12-12A12,12,0,0,1,168,188Z'
    'check-circle|Bold' = 'F1 M176.49,95.51a12,12,0,0,1,0,17l-56,56a12,12,0,0,1-17,0l-24-24a12,12,0,1,1,17-17L112,143l47.51-47.52A12,12,0,0,1,176.49,95.51ZM236,128A108,108,0,1,1,128,20,108.12,108.12,0,0,1,236,128Zm-24,0a84,84,0,1,0-84,84A84.09,84.09,0,0,0,212,128Z'
    'squares-four|Bold' = 'F1 M100,36H56A20,20,0,0,0,36,56v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V56A20,20,0,0,0,100,36ZM96,96H60V60H96ZM200,36H156a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V56A20,20,0,0,0,200,36Zm-4,60H160V60h36Zm-96,40H56a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V156A20,20,0,0,0,100,136Zm-4,60H60V160H96Zm104-60H156a20,20,0,0,0-20,20v44a20,20,0,0,0,20,20h44a20,20,0,0,0,20-20V156A20,20,0,0,0,200,136Zm-4,60H160V160h36Z'
    'cpu|Bold' = 'F1 M156,88H100a12,12,0,0,0-12,12v56a12,12,0,0,0,12,12h56a12,12,0,0,0,12-12V100A12,12,0,0,0,156,88Zm-12,56H112V112h32Zm88-4H220V116h12a12,12,0,0,0,0-24H220V56a20,20,0,0,0-20-20H164V24a12,12,0,0,0-24,0V36H116V24a12,12,0,0,0-24,0V36H56A20,20,0,0,0,36,56V92H24a12,12,0,0,0,0,24H36v24H24a12,12,0,0,0,0,24H36v36a20,20,0,0,0,20,20H92v12a12,12,0,0,0,24,0V220h24v12a12,12,0,0,0,24,0V220h36a20,20,0,0,0,20-20V164h12a12,12,0,0,0,0-24Zm-36,56H60V60H196Z'
    'graphics-card|Bold' = 'F1 M232,44H16A12,12,0,0,0,4,56V208a12,12,0,0,0,24,0V196H44v12a12,12,0,0,0,24,0V196H84v12a12,12,0,0,0,24,0V196h16v12a12,12,0,0,0,24,0V196h84a20,20,0,0,0,20-20V64A20,20,0,0,0,232,44Zm-4,128H28V68H228Zm-52-12a40,40,0,1,0-40-40A40,40,0,0,0,176,160Zm0-56a16,16,0,1,1-16,16A16,16,0,0,1,176,104ZM80,160a40,40,0,1,0-40-40A40,40,0,0,0,80,160Zm0-56a16,16,0,1,1-16,16A16,16,0,0,1,80,104Z'
    'memory|Bold' = 'F1 M232,52H24A20,20,0,0,0,4,72V200a12,12,0,0,0,24,0V188H48v12a12,12,0,0,0,24,0V188H92v12a12,12,0,0,0,24,0V188h24v12a12,12,0,0,0,24,0V188h20v12a12,12,0,0,0,24,0V188h20v12a12,12,0,0,0,24,0V72A20,20,0,0,0,232,52ZM28,76H228v88H28Zm92,64V100a12,12,0,0,0-12-12H56a12,12,0,0,0-12,12v40a12,12,0,0,0,12,12h52A12,12,0,0,0,120,140ZM96,128H68V112H96Zm52,24h52a12,12,0,0,0,12-12V100a12,12,0,0,0-12-12H148a12,12,0,0,0-12,12v40A12,12,0,0,0,148,152Zm12-40h28v16H160Z'
    'windows-logo|Bold' = 'F1 M99.69,51.88a12,12,0,0,0-9.84-2.6l-60,10.91A12,12,0,0,0,20,72v36a12,12,0,0,0,12,12H92a12,12,0,0,0,12-12V61.09A12,12,0,0,0,99.69,51.88ZM80,96H44V82l36-6.54ZM215.69,30.79a12,12,0,0,0-9.84-2.6L129.85,42A12,12,0,0,0,120,53.82V108a12,12,0,0,0,12,12h76a12,12,0,0,0,12-12V40A12,12,0,0,0,215.69,30.79ZM196,96H144V63.83l52-9.45ZM92,136H32a12,12,0,0,0-12,12v36a12,12,0,0,0,9.85,11.81l60,10.91A12,12,0,0,0,104,194.91V148A12,12,0,0,0,92,136ZM80,180.53,44,174V160H80ZM208,136H132a12,12,0,0,0-12,12v54.18A12,12,0,0,0,129.85,214l76,13.82A12,12,0,0,0,220,216V148A12,12,0,0,0,208,136Zm-12,65.62-52-9.45V160h52Z'
    'plug-charging|Bold' = 'F1 M224,48H180V16a12,12,0,0,0-24,0V48H100V16a12,12,0,0,0-24,0V48H32.55C24.4,48,20,54.18,20,60A12,12,0,0,0,32,72H44v92a44.05,44.05,0,0,0,44,44h28v32a12,12,0,0,0,24,0V208h28a44.05,44.05,0,0,0,44-44V72h12a12,12,0,0,0,0-24ZM188,164a20,20,0,0,1-20,20H88a20,20,0,0,1-20-20V72H188Zm-85.86-29.17a12,12,0,0,1-1.38-11l12-32a12,12,0,1,1,22.48,8.42L129.32,116H144a12,12,0,0,1,11.24,16.21l-12,32a12,12,0,0,1-22.48-8.42L126.68,140H112A12,12,0,0,1,102.14,134.83Z'
    'clock-counter-clockwise|Bold' = 'F1 M140,80v41.21l34.17,20.5a12,12,0,1,1-12.34,20.58l-40-24A12,12,0,0,1,116,128V80a12,12,0,0,1,24,0ZM128,28A99.38,99.38,0,0,0,57.24,57.34c-4.69,4.74-9,9.37-13.24,14V64a12,12,0,0,0-24,0v40a12,12,0,0,0,12,12H72a12,12,0,0,0,0-24H57.77C63,86,68.37,80.22,74.26,74.26a76,76,0,1,1,1.58,109,12,12,0,0,0-16.48,17.46A100,100,0,1,0,128,28Z'
    'arrow-right|Bold' = 'F1 M224.49,136.49l-72,72a12,12,0,0,1-17-17L187,140H40a12,12,0,0,1,0-24H187L135.51,64.48a12,12,0,0,1,17-17l72,72A12,12,0,0,1,224.49,136.49Z'
    'arrow-clockwise|Bold' = 'F1 M244,56v48a12,12,0,0,1-12,12H184a12,12,0,1,1,0-24H201.1l-19-17.38c-.13-.12-.26-.24-.38-.37A76,76,0,1,0,127,204h1a75.53,75.53,0,0,0,52.15-20.72,12,12,0,0,1,16.49,17.45A99.45,99.45,0,0,1,128,228h-1.37A100,100,0,1,1,198.51,57.06L220,76.72V56a12,12,0,0,1,24,0Z'
    'arrow-counter-clockwise|Bold' = 'F1 M228,128a100,100,0,0,1-98.66,100H128a99.39,99.39,0,0,1-68.62-27.29,12,12,0,0,1,16.48-17.45,76,76,0,1,0-1.57-109c-.13.13-.25.25-.39.37L54.89,92H72a12,12,0,0,1,0,24H24a12,12,0,0,1-12-12V56a12,12,0,0,1,24,0V76.72L57.48,57.06A100,100,0,0,1,228,128Z'
    'caret-down|Bold' = 'F1 M216.49,104.49l-80,80a12,12,0,0,1-17,0l-80-80a12,12,0,0,1,17-17L128,159l71.51-71.52a12,12,0,0,1,17,17Z'
    'check|Bold' = 'F1 M232.49,80.49l-128,128a12,12,0,0,1-17,0l-56-56a12,12,0,1,1,17-17L96,183,215.51,63.51a12,12,0,0,1,17,17Z'
    'shield-warning|Bold' = 'F1 M116,132V96a12,12,0,0,1,24,0v36a12,12,0,0,1-24,0Zm12,56a16,16,0,1,0-16-16A16,16,0,0,0,128,188ZM228,56v56c0,54.29-26.32,87.22-48.4,105.29-23.71,19.39-47.44,26-48.44,26.29a12.1,12.1,0,0,1-6.32,0c-1-.28-24.73-6.9-48.44-26.29C54.32,199.22,28,166.29,28,112V56A20,20,0,0,1,48,36H208A20,20,0,0,1,228,56Zm-24,4H52v52c0,35.71,13.09,64.69,38.91,86.15A126.14,126.14,0,0,0,128,219.38a126.28,126.28,0,0,0,37.09-21.23C190.91,176.69,204,147.71,204,112Z'
    'warning-circle|Bold' = 'F1 M128,20A108,108,0,1,0,236,128,108.12,108.12,0,0,0,128,20Zm0,192a84,84,0,1,1,84-84A84.09,84.09,0,0,1,128,212Zm-12-80V80a12,12,0,0,1,24,0v52a12,12,0,0,1-24,0Zm28,40a16,16,0,1,1-16-16A16,16,0,0,1,144,172Z'
    'gear-six|Bold' = 'F1 M128,76a52,52,0,1,0,52,52A52.06,52.06,0,0,0,128,76Zm0,80a28,28,0,1,1,28-28A28,28,0,0,1,128,156Zm113.86-49.57A12,12,0,0,0,236,98.34L208.21,82.49l-.11-31.31a12,12,0,0,0-4.25-9.12,116,116,0,0,0-38-21.41,12,12,0,0,0-9.68.89L128,37.27,99.83,21.53a12,12,0,0,0-9.7-.9,116.06,116.06,0,0,0-38,21.47,12,12,0,0,0-4.24,9.1l-.14,31.34L20,98.35a12,12,0,0,0-5.85,8.11,110.7,110.7,0,0,0,0,43.11A12,12,0,0,0,20,157.66l27.82,15.85.11,31.31a12,12,0,0,0,4.25,9.12,116,116,0,0,0,38,21.41,12,12,0,0,0,9.68-.89L128,218.73l28.14,15.74a12,12,0,0,0,9.7.9,116.06,116.06,0,0,0,38-21.47,12,12,0,0,0,4.24-9.1l.14-31.34,27.81-15.81a12,12,0,0,0,5.85-8.11A110.7,110.7,0,0,0,241.86,106.43Zm-22.63,33.18-26.88,15.28a11.94,11.94,0,0,0-4.55,4.59c-.54,1-1.11,1.93-1.7,2.88a12,12,0,0,0-1.83,6.31L184.13,199a91.83,91.83,0,0,1-21.07,11.87l-27.15-15.19a12,12,0,0,0-5.86-1.53h-.29c-1.14,0-2.3,0-3.44,0a12.08,12.08,0,0,0-6.14,1.51L93,210.82A92.27,92.27,0,0,1,71.88,199l-.11-30.24a12,12,0,0,0-1.83-6.32c-.58-.94-1.16-1.91-1.7-2.88A11.92,11.92,0,0,0,63.7,155L36.8,139.63a86.53,86.53,0,0,1,0-23.24l26.88-15.28a12,12,0,0,0,4.55-4.58c.54-1,1.11-1.94,1.7-2.89a12,12,0,0,0,1.83-6.31L71.87,57A91.83,91.83,0,0,1,92.94,45.17l27.15,15.19a11.92,11.92,0,0,0,6.15,1.52c1.14,0,2.3,0,3.44,0a12.08,12.08,0,0,0,6.14-1.51L163,45.18A92.27,92.27,0,0,1,184.12,57l.11,30.24a12,12,0,0,0,1.83,6.32c.58.94,1.16,1.91,1.7,2.88A11.92,11.92,0,0,0,192.3,101l26.9,15.33A86.53,86.53,0,0,1,219.23,139.61Z'
    'info|Bold' = 'F1 M108,84a16,16,0,1,1,16,16A16,16,0,0,1,108,84Zm128,44A108,108,0,1,1,128,20,108.12,108.12,0,0,1,236,128Zm-24,0a84,84,0,1,0-84,84A84.09,84.09,0,0,0,212,128Zm-72,36.68V132a20,20,0,0,0-20-20,12,12,0,0,0-4,23.32V168a20,20,0,0,0,20,20,12,12,0,0,0,4-23.32Z'
    'squares-four|Fill' = 'F1 M120,56v48a16,16,0,0,1-16,16H56a16,16,0,0,1-16-16V56A16,16,0,0,1,56,40h48A16,16,0,0,1,120,56Zm80-16H152a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V56A16,16,0,0,0,200,40Zm-96,96H56a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V152A16,16,0,0,0,104,136Zm96,0H152a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16h48a16,16,0,0,0,16-16V152A16,16,0,0,0,200,136Z'
    'lightning|Fill' = 'F1 M213.85,125.46l-112,120a8,8,0,0,1-13.69-7l14.66-73.33L45.19,143.49a8,8,0,0,1-3-13l112-120a8,8,0,0,1,13.69,7L153.18,90.9l57.63,21.61a8,8,0,0,1,3,12.95Z'
    'game-controller|Fill' = 'F1 M247.44,173.75a.68.68,0,0,0,0-.14L231.05,89.44c0-.06,0-.12,0-.18A60.08,60.08,0,0,0,172,40H83.89a59.88,59.88,0,0,0-59,49.52L8.58,173.61a.68.68,0,0,0,0,.14,36,36,0,0,0,60.9,31.71l.35-.37L109.52,160h37l39.71,45.09c.11.13.23.25.35.37A36.08,36.08,0,0,0,212,216a36,36,0,0,0,35.43-42.25ZM104,112H96v8a8,8,0,0,1-16,0v-8H72a8,8,0,0,1,0-16h8V88a8,8,0,0,1,16,0v8h8a8,8,0,0,1,0,16Zm40-8a8,8,0,0,1,8-8h24a8,8,0,0,1,0,16H152A8,8,0,0,1,144,104Zm84.37,87.47a19.84,19.84,0,0,1-12.9,8.23A20.09,20.09,0,0,1,198,194.31L167.8,160H172a60,60,0,0,0,51-28.38l8.74,45A19.82,19.82,0,0,1,228.37,191.47Z'
    'wifi-high|Fill' = 'F1 M244.35,92.8l-104,125.43A15.93,15.93,0,0,1,128,224h0a15.93,15.93,0,0,1-12.31-5.77L11.65,92.8A15.65,15.65,0,0,1,8.11,80.91,15.93,15.93,0,0,1,14.28,70.1,186.67,186.67,0,0,1,128,32,186.67,186.67,0,0,1,241.72,70.1a15.93,15.93,0,0,1,6.17,10.81A15.65,15.65,0,0,1,244.35,92.8Z'
    'rocket-launch|Fill' = 'F1 M101.85,191.14C97.34,201,82.29,224,40,224a8,8,0,0,1-8-8c0-42.29,23-57.34,32.86-61.85a8,8,0,0,1,6.64,14.56c-6.43,2.93-20.62,12.36-23.12,38.91,26.55-2.5,36-16.69,38.91-23.12a8,8,0,1,1,14.56,6.64Zm122-144a16,16,0,0,0-15-15c-12.58-.75-44.73.4-71.4,27.07h0L88,108.7A8,8,0,0,1,76.67,97.39l26.56-26.57A4,4,0,0,0,100.41,64H74.35A15.9,15.9,0,0,0,63,68.68L28.7,103a16,16,0,0,0,9.07,27.16l38.47,5.37,44.21,44.21,5.37,38.49a15.94,15.94,0,0,0,10.78,12.92,16.11,16.11,0,0,0,5.1.83A15.91,15.91,0,0,0,153,227.3L187.32,193A16,16,0,0,0,192,181.65V155.59a4,4,0,0,0-6.83-2.82l-26.57,26.56a8,8,0,0,1-11.71-.42,8.2,8.2,0,0,1,.6-11.1l49.27-49.27h0C223.45,91.86,224.6,59.71,223.85,47.12Z'
    'hard-drives|Fill' = 'F1 M208,40H48A16,16,0,0,0,32,56v48a16,16,0,0,0,16,16H208a16,16,0,0,0,16-16V56A16,16,0,0,0,208,40ZM180,92a12,12,0,1,1,12-12A12,12,0,0,1,180,92Z M208,136H48a16,16,0,0,0-16,16v48a16,16,0,0,0,16,16H208a16,16,0,0,0,16-16V152A16,16,0,0,0,208,136Zm-28,52a12,12,0,1,1,12-12A12,12,0,0,1,180,188Z'
    'shield-check|Fill' = 'F1 M208,40H48A16,16,0,0,0,32,56v56c0,52.72,25.52,84.67,46.93,102.19,23.06,18.86,46,25.26,47,25.53a8,8,0,0,0,4.2,0c1-.27,23.91-6.67,47-25.53C198.48,196.67,224,164.72,224,112V56A16,16,0,0,0,208,40Zm-34.32,69.66-56,56a8,8,0,0,1-11.32,0l-24-24a8,8,0,0,1,11.32-11.32L112,148.69l50.34-50.35a8,8,0,0,1,11.32,11.32Z'
    'wrench|Fill' = 'F1 M232,96a72,72,0,0,1-100.94,66L79,222.22c-.12.14-.26.29-.39.42a32,32,0,0,1-45.26-45.26c.14-.13.28-.27.43-.39L94,124.94a72.07,72.07,0,0,1,83.54-98.78,8,8,0,0,1,3.93,13.19L144,80l5.66,26.35L176,112l40.65-37.52a8,8,0,0,1,13.19,3.93A72.6,72.6,0,0,1,232,96Z'
    'sliders-horizontal|Fill' = 'F1 M32,80a8,8,0,0,1,8-8H77.17a28,28,0,0,1,53.66,0H216a8,8,0,0,1,0,16H130.83a28,28,0,0,1-53.66,0H40A8,8,0,0,1,32,80Zm184,88H194.83a28,28,0,0,0-53.66,0H40a8,8,0,0,0,0,16H141.17a28,28,0,0,0,53.66,0H216a8,8,0,0,0,0-16Z'
    'check-circle|Fill' = 'F1 M128,24A104,104,0,1,0,232,128,104.11,104.11,0,0,0,128,24Zm45.66,85.66-56,56a8,8,0,0,1-11.32,0l-24-24a8,8,0,0,1,11.32-11.32L112,148.69l50.34-50.35a8,8,0,0,1,11.32,11.32Z'
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Get-AfIconNames {
    'lightning', 'game-controller', 'wifi-high', 'rocket-launch', 'hard-drives', 'shield-check', 'wrench', 'sliders-horizontal',
    'check-circle', 'squares-four', 'cpu', 'graphics-card', 'memory', 'windows-logo', 'plug-charging', 'clock-counter-clockwise',
    'arrow-right', 'arrow-clockwise', 'arrow-counter-clockwise', 'caret-down', 'check', 'shield-warning', 'warning-circle', 'gear-six', 'info'
}

# Variante rellena: categoría activa en la navegación y círculo de "hecho".
function Get-AfFillIconNames {
    'squares-four', 'lightning', 'game-controller', 'wifi-high', 'rocket-launch', 'hard-drives', 'shield-check', 'wrench', 'sliders-horizontal', 'check-circle'
}

function Get-AfIconData {
    param([Parameter(Mandatory)][string]$Name, [ValidateSet('Bold', 'Fill')][string]$Variant = 'Bold')
    $key = '{0}|{1}' -f $Name, $Variant
    if (-not $script:AfIcons -or -not $script:AfIcons.ContainsKey($key)) { throw "Icono no incluido: $key" }
    $script:AfIcons[$key]
}

function Get-AfThemeColors {
    param([ValidateSet('Black', 'White')][string]$Name = 'Black')
    if ($Name -eq 'Black') {
        [ordered]@{
            Bg = '#FF0A0A0B'; Rail = '#FF0E0E10'; Panel = '#FF131315'; Raised = '#FF19191C'
            Line = '#12FFFFFF'; Line2 = '#21FFFFFF'
            Text = '#FFF5F5F4'; Text2 = '#FFA1A1A6'; Text3 = '#FF7A7A80'
            Red = '#FFFF3B47'; RedText = '#FFEF3340'; RedFill = '#FFD11F2C'
            CheckBg = '#FFF5F5F4'; CheckFg = '#FF0A0A0B'
            Tick = '#2BFFFFFF'; TickMajor = '#73FFFFFF'
        }
    } else {
        [ordered]@{
            Bg = '#FFF5F5F3'; Rail = '#FFEDEDEA'; Panel = '#FFFFFFFF'; Raised = '#FFF8F8F6'
            Line = '#12000000'; Line2 = '#24000000'
            Text = '#FF111113'; Text2 = '#FF5C5C63'; Text3 = '#FF6B6B72'
            Red = '#FFE0202E'; RedText = '#FFC8102E'; RedFill = '#FFD11F2C'
            CheckBg = '#FF111113'; CheckFg = '#FFFFFFFF'
            Tick = '#2B000000'; TickMajor = '#80000000'
        }
    }
}

function Get-AfThemeXaml {
    param([ValidateSet('Black', 'White')][string]$Name = 'Black')
    $colors = Get-AfThemeColors -Name $Name
    $brushes = ($colors.Keys | ForEach-Object { '    <SolidColorBrush x:Key="{0}" Color="{1}"/>' -f $_, $colors[$_] }) -join "`r`n"
    @"
<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
$brushes
    <FontFamily x:Key="DisplayFont">Bahnschrift</FontFamily>
    <FontFamily x:Key="TextFont">Segoe UI Variable Text, Segoe UI</FontFamily>
</ResourceDictionary>
"@
}

function Resolve-AfTheme {
    param([ValidateSet('System', 'Black', 'White')][string]$Setting = 'System', $User)
    if ($Setting -ne 'System') { return $Setting }
    $light = Get-AfRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -User $User
    if ($light -eq 1) { 'White' } else { 'Black' }
}

function Test-AfMotionEnabled {
    param([ValidateSet('Auto', 'Always', 'Never')][string]$Setting = 'Auto')
    switch ($Setting) {
        'Always' { $true }
        'Never' { $false }
        default { [bool][System.Windows.SystemParameters]::ClientAreaAnimation }
    }
}

# Curvas de la sección 9 del diseño (cubic-bezier → KeySpline).
function New-AfKeySpline {
    param([ValidateSet('Out', 'InOut', 'Icon', 'Linear')][string]$Ease = 'Out')
    switch ($Ease) {
        'Out' { New-Object System.Windows.Media.Animation.KeySpline(0.23, 1, 0.32, 1) }
        'InOut' { New-Object System.Windows.Media.Animation.KeySpline(0.77, 0, 0.175, 1) }
        'Icon' { New-Object System.Windows.Media.Animation.KeySpline(0.2, 0, 0, 1) }
        default { New-Object System.Windows.Media.Animation.KeySpline(0, 0, 1, 1) }
    }
}

# Anima una propiedad double. Sin movimiento, pone el valor final al instante.
function Start-AfAnimation {
    param(
        [Parameter(Mandatory)]$Target,
        [Parameter(Mandatory)][System.Windows.DependencyProperty]$Property,
        [double]$From = [double]::NaN,
        [Parameter(Mandatory)][double]$To,
        [int]$DurationMs = 200,
        [int]$DelayMs = 0,
        [ValidateSet('Out', 'InOut', 'Icon', 'Linear')][string]$Ease = 'Out',
        [bool]$Enabled = $true
    )
    if (-not $Enabled) {
        $Target.BeginAnimation($Property, $null)
        $Target.SetValue($Property, $To)
        return
    }
    if (-not [double]::IsNaN($From)) {
        $Target.BeginAnimation($Property, $null)
        $Target.SetValue($Property, $From)
    }
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds($DurationMs))
    $animation.BeginTime = [TimeSpan]::FromMilliseconds($DelayMs)
    $animation.FillBehavior = [System.Windows.Media.Animation.FillBehavior]::HoldEnd
    $frame = New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($To, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds($DurationMs)), (New-AfKeySpline -Ease $Ease))
    [void]$animation.KeyFrames.Add($frame)
    $Target.BeginAnimation($Property, $animation)
    $animation
}

function Get-AfWindowXaml {
    @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Afina" Width="1100" Height="720" MinWidth="960" MinHeight="600"
        WindowStartupLocation="CenterScreen" ResizeMode="CanResize"
        Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}"
        FontFamily="{DynamicResource TextFont}" FontSize="13"
        UseLayoutRounding="True" SnapsToDevicePixels="True"
        TextOptions.TextFormattingMode="Ideal">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="40" ResizeBorderThickness="6" GlassFrameThickness="0" CornerRadius="8" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <Style x:Key="CaptionButton" TargetType="Button">
      <Setter Property="Width" Value="46"/>
      <Setter Property="Height" Value="40"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="10"/>
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
              <Trigger Property="Tag" Value="close">
                <Setter Property="FontSize" Value="10"/>
              </Trigger>
              <MultiTrigger>
                <MultiTrigger.Conditions>
                  <Condition Property="Tag" Value="close"/>
                  <Condition Property="IsMouseOver" Value="True"/>
                </MultiTrigger.Conditions>
                <Setter TargetName="Bd" Property="Background" Value="#FFC42B1C"/>
                <Setter Property="Foreground" Value="White"/>
              </MultiTrigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="TitleButton" TargetType="Button">
      <Setter Property="Height" Value="40"/>
      <Setter Property="Padding" Value="12,0"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Focusable" Value="False"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="WindowChrome.IsHitTestVisibleInChrome" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PressButton" TargetType="Button">
      <Setter Property="Height" Value="36"/>
      <Setter Property="Padding" Value="16,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Medium"/>
      <Setter Property="Foreground" Value="{DynamicResource Text}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderBrush" Value="{DynamicResource Line2}"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="9" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}" RenderTransformOrigin="0.5,0.5" ClipToBounds="True">
              <Border.RenderTransform><ScaleTransform x:Name="Sc"/></Border.RenderTransform>
              <ContentPresenter VerticalAlignment="Center" HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.92"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="0.97" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="0.97" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Sc" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource PressButton}">
      <Setter Property="Background" Value="{DynamicResource RedFill}"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="White"/>
    </Style>

    <Style x:Key="SmallButton" TargetType="Button" BasedOn="{StaticResource PressButton}">
      <Setter Property="Height" Value="28"/>
      <Setter Property="Padding" Value="12,0"/>
      <Setter Property="FontSize" Value="12"/>
    </Style>

    <Style x:Key="NavButton" TargetType="Button">
      <Setter Property="Height" Value="32"/>
      <Setter Property="Margin" Value="0,0,0,2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="8" Background="{TemplateBinding Background}" Padding="12,0,10,0">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Line}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="AfCheck" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="Box" Width="18" Height="18" CornerRadius="5" BorderThickness="1.5" BorderBrush="{DynamicResource Line2}" Background="Transparent">
              <Path x:Name="Mark" Width="11" Height="11" Stretch="Uniform" Fill="{DynamicResource CheckFg}" Data="{DynamicResource CheckGeometry}" Opacity="0" RenderTransformOrigin="0.5,0.5">
                <Path.RenderTransform><ScaleTransform x:Name="MarkScale" ScaleX="0.25" ScaleY="0.25"/></Path.RenderTransform>
              </Path>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Box" Property="Background" Value="{DynamicResource CheckBg}"/>
                <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource CheckBg}"/>
                <Trigger.EnterActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Mark" Storyboard.TargetProperty="Opacity"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.16" Value="1" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.EnterActions>
                <Trigger.ExitActions>
                  <BeginStoryboard>
                    <Storyboard>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="Mark" Storyboard.TargetProperty="Opacity"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleX"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0.25" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                      <DoubleAnimationUsingKeyFrames Storyboard.TargetName="MarkScale" Storyboard.TargetProperty="ScaleY"><SplineDoubleKeyFrame KeyTime="0:0:0.12" Value="0.25" KeySpline="0.23,1 0.32,1"/></DoubleAnimationUsingKeyFrames>
                    </Storyboard>
                  </BeginStoryboard>
                </Trigger.ExitActions>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Box" Property="BorderBrush" Value="{DynamicResource Text3}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="Segment" TargetType="RadioButton">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="{DynamicResource Text2}"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="Bd" CornerRadius="7" Padding="6,5" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="{DynamicResource Raised}"/>
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Foreground" Value="{DynamicResource Text}"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb>
                  <Thumb.Template>
                    <ControlTemplate TargetType="Thumb">
                      <Border Margin="3,2" CornerRadius="3" Background="{DynamicResource Line2}"/>
                    </ControlTemplate>
                  </Thumb.Template>
                </Thumb>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid x:Name="Root" Background="{DynamicResource Bg}">
    <Grid.RowDefinitions>
      <RowDefinition Height="40"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Border x:Name="TitleBar" Grid.Row="0" Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,0,0,1">
      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="18,0,0,0">
          <Border Width="2" Height="16" CornerRadius="1" Background="{DynamicResource Red}"/>
          <TextBlock Text="Afina" Margin="10,0,0,1" FontFamily="{DynamicResource DisplayFont}" FontSize="15" FontWeight="Medium" VerticalAlignment="Center"/>
          <TextBlock x:Name="Version" Margin="10,0,0,0" FontFamily="{DynamicResource DisplayFont}" FontSize="12" Foreground="{DynamicResource Text3}" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="HistoryButton" Style="{StaticResource TitleButton}" ToolTip="Sesiones anteriores y deshacer">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="HistoryIcon" Width="14" Height="14" Stretch="Uniform" Fill="{DynamicResource Text2}" VerticalAlignment="Center"/>
              <TextBlock Text="Historial" Margin="7,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="PrefsButton" Style="{StaticResource CaptionButton}" ToolTip="Preferencias"/>
          <Button x:Name="MinButton" Style="{StaticResource CaptionButton}" Content="&#xE921;" ToolTip="Minimizar"/>
          <Button x:Name="MaxButton" Style="{StaticResource CaptionButton}" Content="&#xE922;" ToolTip="Maximizar"/>
          <Button x:Name="CloseButton" Style="{StaticResource CaptionButton}" Tag="close" Content="&#xE8BB;" ToolTip="Cerrar"/>
        </StackPanel>
      </Grid>
    </Border>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="244"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Border Grid.Column="0" Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,0,1,0" Padding="14,22,14,12">
        <DockPanel LastChildFill="False">
          <StackPanel x:Name="PcCard" DockPanel.Dock="Top" Margin="8,0,8,0" Opacity="0">
            <TextBlock x:Name="PcName" FontFamily="{DynamicResource DisplayFont}" FontSize="17" FontWeight="Medium" TextTrimming="CharacterEllipsis"/>
            <TextBlock x:Name="PcKind" FontSize="12" Foreground="{DynamicResource Text3}" Margin="0,3,0,0"/>
            <StackPanel x:Name="Specs" Margin="0,16,0,0"/>
          </StackPanel>
          <Grid x:Name="NavHost" DockPanel.Dock="Top" Margin="0,24,0,0">
            <StackPanel x:Name="Nav"/>
            <Border x:Name="NavIndicator" Width="2" Height="32" CornerRadius="2" Background="{DynamicResource Red}" HorizontalAlignment="Left" VerticalAlignment="Top">
              <Border.RenderTransform><TranslateTransform x:Name="NavIndicatorTransform"/></Border.RenderTransform>
            </Border>
          </Grid>
        </DockPanel>
      </Border>

      <Grid Grid.Column="1">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="32,26,32,14">
          <TextBlock x:Name="Title" Text="Analizando esta PC" FontFamily="{DynamicResource DisplayFont}" FontSize="28" FontWeight="Light"/>
          <StackPanel x:Name="GaugeArea">
          <Grid x:Name="Gauge" Height="46" Margin="0,22,0,0">
            <Canvas x:Name="Ticks" Height="20" VerticalAlignment="Bottom" Margin="0,0,0,8"/>
            <Canvas x:Name="LitTicks" Height="20" VerticalAlignment="Bottom" Margin="0,0,0,8" IsHitTestVisible="False"/>
            <Canvas x:Name="Needle" Width="2" Height="38" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="0,0,0,2" Opacity="1">
              <Canvas.RenderTransform><TranslateTransform x:Name="NeedleTransform"/></Canvas.RenderTransform>
              <Ellipse x:Name="NeedleHalo" Width="146" Height="72" Canvas.Left="-72" Canvas.Top="-16" IsHitTestVisible="False" Opacity="0.26"/>
              <Rectangle Width="2" Height="38" RadiusX="1" RadiusY="1" Fill="{DynamicResource Red}"/>
              <Polygon Points="-3,-6 5,-6 1,0" Fill="{DynamicResource Red}"/>
            </Canvas>
          </Grid>
          <Grid Margin="0,6,0,0">
            <TextBlock Text="Desafinado" FontSize="11.5" Foreground="{DynamicResource Text3}"/>
            <TextBlock Text="Afinado" FontSize="11.5" Foreground="{DynamicResource Text3}" HorizontalAlignment="Right"/>
          </Grid>
          </StackPanel>
          <TextBlock x:Name="Summary" Margin="0,14,0,0" FontSize="13.5" Foreground="{DynamicResource Text2}" TextWrapping="Wrap" MinHeight="20"/>
        </StackPanel>
        <ScrollViewer x:Name="ListScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="32,4,32,28" Focusable="False">
          <Grid>
            <Border x:Name="PanelBorder" Background="{DynamicResource Panel}" CornerRadius="14" BorderBrush="{DynamicResource Line}" BorderThickness="1" Visibility="Collapsed">
              <StackPanel x:Name="Groups" Margin="0,0,0,6"/>
            </Border>
            <Border x:Name="HistoryPanel" Visibility="Collapsed">
              <StackPanel x:Name="HistoryList"/>
            </Border>
          </Grid>
        </ScrollViewer>
      </Grid>
    </Grid>

    <Border Grid.Row="2" Background="{DynamicResource Rail}" BorderBrush="{DynamicResource Line}" BorderThickness="0,1,0,0" Padding="32,14">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,24,0">
          <DockPanel>
            <Path x:Name="NoteIcon" DockPanel.Dock="Left" Width="16" Height="16" Stretch="Uniform" Fill="{DynamicResource Text3}" VerticalAlignment="Top" Margin="0,1,0,0"/>
            <TextBlock x:Name="NoteText" Text="Se crea un punto de restauración antes de aplicar" Margin="8,0,0,0" FontSize="12.5" Foreground="{DynamicResource Text2}" TextWrapping="Wrap" VerticalAlignment="Center"/>
          </DockPanel>
          <StackPanel x:Name="RestoreRow" Orientation="Horizontal" Margin="24,9,0,0" Visibility="Collapsed">
            <CheckBox x:Name="RestoreOption" Style="{StaticResource AfCheck}" IsChecked="True" VerticalAlignment="Center"/>
            <TextBlock x:Name="RestoreLabel" Text="Activar Restaurar sistema en C:" Margin="9,0,0,0" FontSize="12.5" Foreground="{DynamicResource Text}" VerticalAlignment="Center" Cursor="Hand"/>
          </StackPanel>
        </StackPanel>
        <StackPanel x:Name="Actions" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Opacity="0" IsHitTestVisible="False">
          <Button x:Name="ExtraButton" Style="{StaticResource PressButton}" Margin="0,0,10,0" Visibility="Collapsed">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="ExtraIcon" Width="15" Height="15" Stretch="Uniform" Fill="{DynamicResource Text}" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <TextBlock x:Name="ExtraText" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="GhostButton" Style="{StaticResource PressButton}" Margin="0,0,10,0">
            <StackPanel Orientation="Horizontal">
              <Path x:Name="GhostIcon" Width="15" Height="15" Stretch="Uniform" Fill="{DynamicResource Text}" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <TextBlock x:Name="GhostText" Text="Volver a analizar" VerticalAlignment="Center"/>
            </StackPanel>
          </Button>
          <Button x:Name="PrimaryButton" Style="{StaticResource PrimaryButton}">
            <Grid>
              <StackPanel x:Name="PrimaryText" Orientation="Horizontal" ClipToBounds="True">
                <TextBlock x:Name="PrimaryLead"/>
                <TextBlock x:Name="PrimaryNumber">
                  <TextBlock.RenderTransform><TranslateTransform x:Name="PrimaryNumberShift"/></TextBlock.RenderTransform>
                </TextBlock>
                <TextBlock x:Name="PrimaryTail"/>
              </StackPanel>
              <Rectangle x:Name="PrimaryProgress" Height="2" VerticalAlignment="Bottom" Margin="-16,0,-16,-9" Fill="#E6FFFFFF" RenderTransformOrigin="0,0.5">
                <Rectangle.RenderTransform><ScaleTransform x:Name="PrimaryProgressScale" ScaleX="0"/></Rectangle.RenderTransform>
              </Rectangle>
            </Grid>
          </Button>
        </StackPanel>
      </Grid>
    </Border>

    <Popup x:Name="Prefs" StaysOpen="False" Placement="Bottom" AllowsTransparency="True" PopupAnimation="Fade" HorizontalOffset="-200" VerticalOffset="4">
      <Border Background="{DynamicResource Panel}" CornerRadius="12" BorderBrush="{DynamicResource Line2}" BorderThickness="1" Padding="14" Width="280">
        <StackPanel>
          <TextBlock Text="Tema" FontSize="12" Foreground="{DynamicResource Text3}"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,14">
            <UniformGrid Rows="1">
              <RadioButton x:Name="ThemeSystem" GroupName="Theme" Style="{StaticResource Segment}" Content="Sistema"/>
              <RadioButton x:Name="ThemeBlack" GroupName="Theme" Style="{StaticResource Segment}" Content="Negro"/>
              <RadioButton x:Name="ThemeWhite" GroupName="Theme" Style="{StaticResource Segment}" Content="Blanco"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Animaciones" FontSize="12" Foreground="{DynamicResource Text3}"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,0">
            <UniformGrid Rows="1">
              <RadioButton x:Name="MotionAuto" GroupName="Motion" Style="{StaticResource Segment}" Content="Automático"/>
              <RadioButton x:Name="MotionAlways" GroupName="Motion" Style="{StaticResource Segment}" Content="Siempre"/>
              <RadioButton x:Name="MotionNever" GroupName="Motion" Style="{StaticResource Segment}" Content="Nunca"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Automático sigue la opción Efectos de animación de Windows." FontSize="11.5" Foreground="{DynamicResource Text3}" TextWrapping="Wrap" Margin="0,8,0,0"/>
          <TextBlock Text="Idioma" FontSize="12" Foreground="{DynamicResource Text3}" Margin="0,16,0,0"/>
          <Border Background="{DynamicResource Line}" CornerRadius="10" Padding="3" Margin="0,6,0,0">
            <UniformGrid Rows="1">
              <RadioButton x:Name="LangAuto" GroupName="Lang" Style="{StaticResource Segment}" Content="Automático"/>
              <RadioButton x:Name="LangEs" GroupName="Lang" Style="{StaticResource Segment}" Content="Español"/>
              <RadioButton x:Name="LangEn" GroupName="Lang" Style="{StaticResource Segment}" Content="English"/>
            </UniformGrid>
          </Border>
          <TextBlock Text="Automático sigue el idioma de Windows." FontSize="11.5" Foreground="{DynamicResource Text3}" TextWrapping="Wrap" Margin="0,8,0,0"/>
        </StackPanel>
      </Border>
    </Popup>
  </Grid>
</Window>
'@
}

function New-AfIcon {
    param([Parameter(Mandatory)][string]$Name, [ValidateSet('Bold', 'Fill')][string]$Variant = 'Bold', [double]$Size = 16, [string]$Brush = 'Text3')
    $path = New-Object System.Windows.Shapes.Path
    $path.Data = [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name $Name -Variant $Variant))
    $path.Width = $Size
    $path.Height = $Size
    $path.Stretch = [System.Windows.Media.Stretch]::Uniform
    $path.VerticalAlignment = 'Center'
    $path.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $Brush)
    $path
}

function Set-AfIconData {
    param([Parameter(Mandatory)][System.Windows.Shapes.Path]$Path, [Parameter(Mandatory)][string]$Name, [string]$Variant = 'Bold')
    $Path.Data = [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name $Name -Variant $Variant))
}

function Set-AfTheme {
    param([Parameter(Mandatory)]$Window, [ValidateSet('Black', 'White')][string]$Theme = 'Black')
    $dictionary = [System.Windows.Markup.XamlReader]::Parse((Get-AfThemeXaml -Name $Theme))
    # .Add() y no $dictionary[...] = ...: el indexador guarda el objeto envuelto por PowerShell y WPF no lo reconoce.
    $dictionary.Add('CheckGeometry', [System.Windows.Media.Geometry]::Parse((Get-AfIconData -Name 'check' -Variant Bold)))
    # Halo de la aguja: el rojo del tema que se desvanece hacia transparente.
    $red = $dictionary['Red'].Color
    $halo = New-Object System.Windows.Media.RadialGradientBrush
    [void]$halo.GradientStops.Add((New-Object System.Windows.Media.GradientStop($red, 0)))
    [void]$halo.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromArgb(0, $red.R, $red.G, $red.B), 1)))
    $dictionary.Add('NeedleHaloBrush', $halo)
    $Window.Resources.MergedDictionaries.Clear()
    $Window.Resources.MergedDictionaries.Add($dictionary)
    $Window.Tag = if ($Window.Tag -is [hashtable]) { $Window.Tag } else { @{} }
    $Window.Tag.Theme = $Theme
}

# Textos fijos del XAML (escritos en español). La primera vez guarda el original de cada uno; siempre pone su traducción.
# Al cambiar de idioma se vuelve a llamar; los textos que pone el código se rehacen con el análisis nuevo.
function Set-AfStaticTexts {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag -isnot [hashtable]) { $Window.Tag = @{} }
    $s = $Window.Tag
    if (-not $s.StaticTexts) {
        $found = New-Object System.Collections.ArrayList
        $pending = New-Object System.Collections.Stack
        $pending.Push($Window)
        while ($pending.Count) {
            $node = $pending.Pop()
            if ($node -is [System.Windows.Controls.TextBlock]) {
                $inlines = @($node.Inlines)
                if ($inlines.Count -gt 1) {
                    foreach ($run in $inlines) { if ($run -is [System.Windows.Documents.Run] -and $run.Text -match '\p{L}') { [void]$found.Add(@{ Element = $run; Property = 'Text'; Spanish = $run.Text }) } }
                } elseif ($node.Text -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'Text'; Spanish = $node.Text }) }
            }
            if ($node -is [System.Windows.Controls.ContentControl] -and $node.Content -is [string] -and $node.Content -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'Content'; Spanish = $node.Content }) }
            if ($node -is [System.Windows.FrameworkElement] -and $node.ToolTip -is [string] -and $node.ToolTip -match '\p{L}') { [void]$found.Add(@{ Element = $node; Property = 'ToolTip'; Spanish = $node.ToolTip }) }
            foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($node)) { if ($child -is [System.Windows.DependencyObject]) { $pending.Push($child) } }
        }
        $s.StaticTexts = $found
    }
    foreach ($item in $s.StaticTexts) { $item.Element.($item.Property) = T $item.Spanish }
}

function New-AfWindow {
    param([ValidateSet('Black', 'White')][string]$Theme = 'Black')
    $window = [System.Windows.Markup.XamlReader]::Parse((Get-AfWindowXaml))
    Set-AfTheme -Window $window -Theme $Theme
    Set-AfStaticTexts -Window $window
    $window.FindName('NeedleHalo').SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'NeedleHaloBrush')
    $window.FindName('PrefsButton').Content = New-AfIcon -Name 'gear-six' -Size 15 -Brush 'Text2'
    Set-AfIconData -Path $window.FindName('HistoryIcon') -Name 'clock-counter-clockwise'
    Set-AfIconData -Path $window.FindName('NoteIcon') -Name 'shield-check'
    Set-AfIconData -Path $window.FindName('GhostIcon') -Name 'arrow-clockwise'
    $window.FindName('Version').Text = 'v' + (Get-AfVersion)
    $window
}

# Deja correr la interfaz (animaciones, diseño) un rato sin bloquear el hilo de WPF.
function Wait-AfUi {
    param([int]$Milliseconds = 300)
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($Milliseconds)
    $timer.Add_Tick({ $timer.Stop(); $frame.Continue = $false }.GetNewClosure())
    $timer.Start()
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

function Save-AfWindowSnapshot {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$Path, [double]$Scale = 1)
    if (-not $Window.IsVisible) {
        $Window.WindowStartupLocation = 'Manual'
        $Window.Left = -20000
        $Window.Top = -20000
        $Window.ShowActivated = $false
        $Window.Show()
    }
    Wait-AfUi -Milliseconds 450
    $Window.UpdateLayout()
    $root = $Window.Content
    $width = [int][math]::Round($root.ActualWidth * $Scale)
    $height = [int][math]::Round($root.ActualHeight * $Scale)
    $bitmap = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($width, $height, (96 * $Scale), (96 * $Scale), [System.Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($root)
    $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream = [System.IO.File]::Create($Path)
    try { $encoder.Save($stream) } finally { $stream.Dispose() }
}

function Get-AfRowXaml {
    @'
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="RowRoot" Padding="18,11,18,11" Cursor="Hand">
  <Border.Style>
    <Style TargetType="Border">
      <Setter Property="Background" Value="Transparent"/>
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="{DynamicResource Raised}"/>
        </Trigger>
      </Style.Triggers>
    </Style>
  </Border.Style>
  <Border.RenderTransform><TranslateTransform x:Name="RowShift"/></Border.RenderTransform>
  <Grid>
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="18"/>
      <ColumnDefinition Width="14"/>
      <ColumnDefinition Width="*"/>
      <ColumnDefinition Width="Auto"/>
    </Grid.ColumnDefinitions>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <Rectangle x:Name="Divider" Grid.ColumnSpan="4" Grid.Column="1" Height="1" VerticalAlignment="Top" Margin="0,-11,0,0" Fill="{DynamicResource Line}" Visibility="Collapsed"/>
    <Grid x:Name="Lead" Grid.Column="0" Width="18" Height="18" VerticalAlignment="Top" Margin="0,1,0,0"/>
    <StackPanel Grid.Column="2">
      <TextBlock x:Name="RowTitle" FontSize="13.5" FontWeight="Medium" Foreground="{DynamicResource Text}" TextWrapping="Wrap"/>
      <WrapPanel x:Name="RowSub" Margin="0,3,0,0"/>
      <TextBlock x:Name="RowNote" FontSize="12" Foreground="{DynamicResource Text3}" Margin="0,2,0,0" TextWrapping="Wrap" Visibility="Collapsed"/>
    </StackPanel>
    <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Top" Margin="12,1,0,0">
      <StackPanel x:Name="RowTag" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,14,0" Visibility="Collapsed"/>
      <StackPanel x:Name="Bars" Orientation="Horizontal" VerticalAlignment="Center" Height="12"/>
      <Border x:Name="Caret" Width="24" Height="24" CornerRadius="6" Margin="10,-3,0,0" RenderTransformOrigin="0.5,0.5" Background="Transparent">
        <Border.RenderTransform><RotateTransform x:Name="CaretRotate"/></Border.RenderTransform>
      </Border>
    </StackPanel>
    <Border x:Name="Detail" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Visibility="Collapsed" ClipToBounds="True" MaxHeight="0"/>
  </Grid>
</Border>
'@
}

function New-AfText {
    param([string]$Text, [double]$Size = 12.5, [string]$Brush = 'Text2', [switch]$Display, [string]$Weight = 'Normal')
    $block = New-Object System.Windows.Controls.TextBlock
    $block.Text = $Text
    $block.FontSize = $Size
    $block.FontWeight = $Weight
    $block.TextWrapping = 'Wrap'
    $block.VerticalAlignment = 'Center'
    if ($Display) { $block.SetResourceReference([System.Windows.Controls.TextBlock]::FontFamilyProperty, 'DisplayFont') }
    $block.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $Brush)
    $block
}

function New-AfSpinner {
    param([double]$Size = 14)
    $arc = New-Object System.Windows.Shapes.Ellipse
    $arc.Width = $Size
    $arc.Height = $Size
    $arc.StrokeThickness = 1.5
    $arc.StrokeDashArray = [System.Windows.Media.DoubleCollection]::Parse('6 3')
    $arc.SetResourceReference([System.Windows.Shapes.Shape]::StrokeProperty, 'Text2')
    $arc.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $rotate = New-Object System.Windows.Media.RotateTransform
    $arc.RenderTransform = $rotate
    $spin = New-Object System.Windows.Media.Animation.DoubleAnimation(0, 360, (New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(700))))
    $spin.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $rotate.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $spin)
    $arc
}

function Get-AfRowCheckBox {
    param([Parameter(Mandatory)]$Row)
    $lead = $Row.FindName('Lead')
    @($lead.Children | Where-Object { $_ -is [System.Windows.Controls.CheckBox] })[0]
}

function New-AfRowElement {
    param([Parameter(Mandatory)]$Result, [switch]$First)
    $row = [System.Windows.Markup.XamlReader]::Parse((Get-AfRowXaml))
    $row.Tag = $Result
    $check = $Result.Check
    $d = $Result.Detection
    if (-not $First) { $row.FindName('Divider').Visibility = 'Visible' }

    $lead = $row.FindName('Lead')
    $nextVersion = $check.Kind -eq 'Auto' -and $d.State -eq 'Improvable' -and -not (Test-AfCanApply -Check $check)
    if ($d.Data -and $d.Data.Async -and $d.State -eq 'Info') {
        [void]$lead.Children.Add((New-AfSpinner -Size 16))
    } elseif ($nextVersion) {
        [void]$lead.Children.Add((New-AfIcon -Name 'info' -Size 16))
    } elseif ($check.Kind -eq 'Auto' -and $d.State -eq 'Improvable') {
        $box = New-Object System.Windows.Controls.CheckBox
        $box.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'AfCheck')
        $box.IsChecked = [bool]$Result.Preselected
        $box.ToolTip = (T 'Incluir este cambio')
        [void]$lead.Children.Add($box)
    } else {
        $icon = switch ($d.State) {
            'Manual' { New-AfIcon -Name 'wrench' -Size 16 }
            'Info' { New-AfIcon -Name 'info' -Size 16 }
            'Error' { New-AfIcon -Name 'warning-circle' -Size 16 -Brush 'RedText' }
            default { New-AfIcon -Name 'check' -Size 15 }
        }
        [void]$lead.Children.Add($icon)
    }

    $row.FindName('RowTitle').Text = if ($d.Title) { $d.Title } else { $check.Title }

    $sub = $row.FindName('RowSub')
    $note = $d.Note
    if ($check.Risk -eq 'Advanced' -and $d.Note) {
        $risk = New-Object System.Windows.Controls.StackPanel
        $risk.Orientation = 'Horizontal'
        [void]$risk.Children.Add((New-AfIcon -Name 'shield-warning' -Size 14 -Brush 'RedText'))
        $text = New-AfText -Text $d.Note -Brush 'RedText'
        $text.Margin = '6,0,0,0'
        [void]$risk.Children.Add($text)
        [void]$sub.Children.Add($risk)
        $note = $null
    } elseif ($d.Current -and $d.Target) {
        $numeric = $d.Current -match '^\d' -and $d.Target -match '^\d'
        [void]$sub.Children.Add((New-AfText -Text $d.Current -Display:$numeric))
        $arrow = New-AfIcon -Name 'arrow-right' -Size 12
        $arrow.Margin = '7,0,7,0'
        [void]$sub.Children.Add($arrow)
        [void]$sub.Children.Add((New-AfText -Text $d.Target -Brush 'Text' -Display:$numeric))
    } elseif ($d.Current -and $d.State -ne 'Ok') {
        [void]$sub.Children.Add((New-AfText -Text $d.Current))
    } else {
        $sub.Visibility = 'Collapsed'
    }
    if ($note -and $d.State -ne 'Error') {
        $noteBlock = $row.FindName('RowNote')
        $noteBlock.Text = $note
        $noteBlock.Visibility = 'Visible'
    }

    $tag = $row.FindName('RowTag')
    $tagText = $null
    if ($nextVersion) { $tagText = (T 'En la próxima versión'); $tagIcon = 'info' }
    # Que no se deshace va antes que el reinicio: el reinicio ya lo dice la confirmación (diseño, sección 5).
    elseif ($check.NoUndo -and $d.State -eq 'Improvable') { $tagText = (T 'No se puede deshacer'); $tagIcon = 'warning-circle' }
    elseif ($check.NeedsReboot -and $d.State -eq 'Improvable') { $tagText = (T 'Pide reiniciar'); $tagIcon = 'arrow-clockwise' }
    if ($tagText) {
        [void]$tag.Children.Add((New-AfIcon -Name $tagIcon -Size 13))
        $t = New-AfText -Text $tagText -Size 12 -Brush 'Text3'
        $t.Margin = '5,0,0,0'
        [void]$tag.Children.Add($t)
        $tag.Visibility = 'Visible'
    }

    $bars = $row.FindName('Bars')
    $heights = 5, 8, 12
    for ($i = 0; $i -lt 3; $i++) {
        $bar = New-Object System.Windows.Shapes.Rectangle
        $bar.Width = 3
        $bar.Height = $heights[$i]
        $bar.RadiusX = 1
        $bar.RadiusY = 1
        $bar.Margin = '0,0,2,0'
        $bar.VerticalAlignment = 'Bottom'
        $bar.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $(if ($i -lt $Result.Weight) { 'Text' } else { 'Line2' }))
        [void]$bars.Children.Add($bar)
    }
    $bars.ToolTip = @('', (T 'Impacto bajo'), (T 'Impacto medio'), (T 'Impacto alto'))[$Result.Weight]

    $row.FindName('Caret').Child = New-AfIcon -Name 'caret-down' -Size 12
    $row.FindName('Detail').Child = New-AfDetailContent -Result $Result -Row $row
    $row
}

# Opciones dentro del detalle (por ejemplo, qué programas de inicio desactivar). Marcan Selected en los datos de la detección.
function New-AfChoiceList {
    param([Parameter(Mandatory)]$Result, $Row)
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '0,4,0,2'
    $boxes = New-Object System.Collections.ArrayList
    foreach ($choice in @($Result.Detection.Data.Choices)) {
        $line = New-Object System.Windows.Controls.StackPanel
        $line.Orientation = 'Horizontal'
        $line.Margin = '0,0,0,7'
        $box = New-Object System.Windows.Controls.CheckBox
        $box.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'AfCheck')
        $box.IsChecked = [bool]$choice.Selected
        $box.Tag = @{ Choice = $choice; Row = $Row }
        $box.Add_Click({ param($sender, $e) Sync-AfChoice -Box $sender })
        $label = New-AfText -Text $choice.Label -Size 12.5 -Brush 'Text2'
        $label.Margin = '10,0,0,0'
        $label.Cursor = 'Hand'
        $label.Tag = $box
        if ($choice.Path) { $label.ToolTip = $choice.Path }
        $label.Add_MouseLeftButtonUp({ param($sender, $e) $sender.Tag.IsChecked = -not $sender.Tag.IsChecked; Sync-AfChoice -Box $sender.Tag; $e.Handled = $true })
        [void]$line.Children.Add($box)
        [void]$line.Children.Add($label)
        [void]$panel.Children.Add($line)
        [void]$boxes.Add($box)
    }
    if ($Row) { $Row.Resources['ChoiceBoxes'] = $boxes }
    $panel
}

# Una opción cambió: la casilla de la fila queda marcada si hay alguna elegida.
function Sync-AfChoice {
    param([Parameter(Mandatory)]$Box)
    $Box.Tag.Choice.Selected = [bool]$Box.IsChecked
    $row = $Box.Tag.Row
    if (-not $row) { return }
    $parent = Get-AfRowCheckBox -Row $row
    if ($parent) { $parent.IsChecked = @($row.Resources['ChoiceBoxes'] | Where-Object { $_.IsChecked }).Count -gt 0 }
    $window = [System.Windows.Window]::GetWindow($row)
    if ($window) { Update-AfPrimary -Window $window -Roll $true }
}

# Se marcó la fila sin opciones elegidas: vuelven las preseleccionadas.
function Reset-AfChoices {
    param([Parameter(Mandatory)]$Row)
    # Sin opciones, el recurso no existe: @($null) contaría como una casilla.
    $boxes = @($Row.Resources['ChoiceBoxes'] | Where-Object { $_ })
    if (-not $boxes.Count -or @($boxes | Where-Object { $_.IsChecked }).Count) { return }
    foreach ($box in $boxes) {
        $choice = $box.Tag.Choice
        $choice.Selected = [bool]$choice.Preselected
        $box.IsChecked = $choice.Selected
    }
}

function New-AfDetailContent {
    param([Parameter(Mandatory)]$Result, $Row)
    $d = $Result.Detection
    $check = $Result.Check
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = '0,10,0,2'
    $whyBlock = New-AfText -Text $check.Why -Size 12.5 -Brush 'Text2'
    $whyBlock.Margin = '0,0,0,8'
    [void]$panel.Children.Add($whyBlock)

    if ($check.Kind -eq 'Auto' -and $d.State -eq 'Improvable') {
        $grid = New-Object System.Windows.Controls.Grid
        $labelColumn = New-Object System.Windows.Controls.ColumnDefinition
        $labelColumn.Width = New-Object System.Windows.GridLength(92)
        [void]$grid.ColumnDefinitions.Add($labelColumn)
        [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
        # El tercer valor dice qué fila es: el texto de la etiqueta cambia con el idioma.
        $rows = @(@((T 'Qué cambia'), $d.What, 'what'), @((T 'Deshacer'), $check.Undo, 'undo'), @((T 'Fuente'), $check.Source, 'source')) | Where-Object { $_[1] }
        $i = 0
        foreach ($pair in $rows) {
            $gridRow = New-Object System.Windows.Controls.RowDefinition
            $gridRow.Height = [System.Windows.GridLength]::Auto
            [void]$grid.RowDefinitions.Add($gridRow)
            $label = New-AfText -Text $pair[0] -Size 12.5 -Brush 'Text3'
            $label.Margin = '0,0,0,6'
            $label.VerticalAlignment = 'Top'
            [System.Windows.Controls.Grid]::SetRow($label, $i)
            $value = New-AfText -Text $pair[1] -Size 12.5 -Brush $(if ($pair[2] -eq 'source') { 'Text' } else { 'Text2' })
            $value.Margin = '0,0,0,6'
            $value.VerticalAlignment = 'Top'
            if ($pair[2] -eq 'source' -and $check.SourceUrl) { $value.TextDecorations = [System.Windows.TextDecorations]::Underline; $value.ToolTip = $check.SourceUrl }
            [System.Windows.Controls.Grid]::SetRow($value, $i)
            [System.Windows.Controls.Grid]::SetColumn($value, 1)
            [void]$grid.Children.Add($label)
            [void]$grid.Children.Add($value)
            $i++
        }
        [void]$panel.Children.Add($grid)
        if ($d.Data -and $d.Data.Choices -and (Test-AfCanApply -Check $check)) {
            $choicesLabel = New-AfText -Text $(if ($d.Data.ChoicesLabel) { $d.Data.ChoicesLabel } else { (T 'Programas') }) -Size 12.5 -Brush 'Text3'
            $choicesLabel.Margin = '0,4,0,8'
            [void]$panel.Children.Add($choicesLabel)
            [void]$panel.Children.Add((New-AfChoiceList -Result $Result -Row $Row))
        }
    } elseif (@($d.Steps).Count) {
        $n = 1
        foreach ($step in $d.Steps) {
            $line = New-AfText -Text ('{0}. {1}' -f $n, $step) -Size 12.5 -Brush 'Text2'
            $line.Margin = '0,0,0,4'
            [void]$panel.Children.Add($line)
            $n++
        }
    }
    $panel
}

function Switch-AfRowDetail {
    param([Parameter(Mandatory)]$Row, [bool]$Motion = $true)
    $detail = $Row.FindName('Detail')
    $caret = $Row.FindName('CaretRotate')
    $opening = $detail.Tag -ne 'open'
    if ($opening) {
        $detail.Tag = 'open'
        $detail.Visibility = 'Visible'
        $detail.Child.Measure((New-Object System.Windows.Size([double]::PositiveInfinity, [double]::PositiveInfinity)))
        $height = $detail.Child.DesiredSize.Height + 4
        Start-AfAnimation -Target $detail -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -From 0 -To $height -DurationMs 250 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $detail -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To 180 -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null
    } else {
        $detail.Tag = 'closed'
        Start-AfAnimation -Target $detail -Property ([System.Windows.FrameworkElement]::MaxHeightProperty) -To 0 -DurationMs 150 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $detail -Property ([System.Windows.UIElement]::OpacityProperty) -To 0 -DurationMs 120 -Ease Out -Enabled $Motion | Out-Null
        Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To 0 -DurationMs 150 -Ease Out -Enabled $Motion | Out-Null
        if (-not $Motion) { $detail.Visibility = 'Collapsed' }
    }
}

# Estado de una fila mientras se aplica o se deshace: casilla → indicador giratorio → hecho, no se pudo o vuelta atrás.
function Set-AfRowStatus {
    param(
        [Parameter(Mandatory)]$Row,
        [Parameter(Mandatory)][ValidateSet('Applying', 'Applied', 'Failed', 'Reverted', 'Undoing')][string]$Status,
        [string]$Message,
        [bool]$Motion = $false
    )
    $lead = $Row.FindName('Lead')
    $lead.Children.Clear()
    $element = switch ($Status) {
        'Applied' { New-AfIcon -Name 'check-circle' -Variant Fill -Size 17 -Brush 'Text' }
        'Failed' { New-AfIcon -Name 'warning-circle' -Size 16 -Brush 'RedText' }
        'Reverted' { New-AfIcon -Name 'arrow-counter-clockwise' -Size 16 -Brush 'Text3' }
        default { New-AfSpinner -Size 16 }
    }
    [void]$lead.Children.Add($element)
    Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Icon -Enabled $Motion | Out-Null
    if ($Message) { Set-AfRowNote -Row $Row -Text $Message }
}

function Set-AfRowNote {
    param([Parameter(Mandatory)]$Row, [string]$Text)
    $note = $Row.FindName('RowNote')
    $note.Text = $Text
    $note.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, 'Text2')
    $note.Visibility = 'Visible'
}

# Vuelve a dibujar la fila como antes de aplicar (tras deshacer), con la casilla marcada.
function Reset-AfRow {
    param([Parameter(Mandatory)]$Row, [bool]$Motion = $false)
    $group = $Row.Parent
    $index = $group.Children.IndexOf($Row)
    $first = $Row.FindName('Divider').Visibility -ne 'Visible'
    $new = New-AfRowElement -Result $Row.Tag -First:$first
    $box = Get-AfRowCheckBox -Row $new
    if ($box) { $box.IsChecked = $true }
    Add-AfRowHandlers -Row $new
    # WPF no deja reemplazar por índice sin soltar antes la fila vieja.
    $group.Children.RemoveAt($index)
    $group.Children.Insert($index, $new)
    Start-AfAnimation -Target $new -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $Motion | Out-Null
    $new
}

function New-AfGroupElement {
    param([Parameter(Mandatory)]$Category, [object[]]$Results = @(), [switch]$First)
    $group = New-Object System.Windows.Controls.StackPanel
    $group.Tag = $Category.Id
    if (-not $First) {
        $line = New-Object System.Windows.Shapes.Rectangle
        $line.Height = 1
        $line.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line')
        [void]$group.Children.Add($line)
    }
    $header = New-Object System.Windows.Controls.StackPanel
    $header.Orientation = 'Horizontal'
    $header.Margin = '18,14,18,4'
    [void]$header.Children.Add((New-AfIcon -Name $Category.Icon -Size 14))
    $label = New-AfText -Text $Category.Name -Size 12 -Brush 'Text3'
    $label.Margin = '8,0,0,0'
    [void]$header.Children.Add($label)
    [void]$group.Children.Add($header)
    $firstRow = $true
    foreach ($result in $Results) {
        [void]$group.Children.Add((New-AfRowElement -Result $result -First:$firstRow))
        $firstRow = $false
    }
    $group
}

function Format-AfCpuName {
    param([string]$Name)
    $n = $Name -replace '\((R|TM)\)', '' -replace '\s+with\s+Radeon.*$', '' -replace '\s+(CPU|Processor)\b.*$', '' -replace '\s+@.*$', ''
    $n = $n -replace '^\d+th Gen\s+', '' -replace '^Intel\s+', '' -replace '^AMD\s+', '' -replace '\s{2,}', ' '
    $n.Trim()
}

function Format-AfGpuName {
    param([string]$Name)
    ($Name -replace '^NVIDIA\s+(GeForce\s+)?', '' -replace '^AMD\s+', '' -replace '^Intel\(R\)\s+', '' -replace '\s+GPU$', '').Trim()
}

function Format-AfPcName {
    param($Device)
    $maker = switch -Regex ([string]$Device.Manufacturer) {
        '^LENOVO' { 'Lenovo'; break }
        '^ASUSTeK|^ASUS' { 'ASUS'; break }
        '^Hewlett|^HP' { 'HP'; break }
        '^Dell' { 'Dell'; break }
        '^Acer' { 'Acer'; break }
        '^Micro-Star|^MSI' { 'MSI'; break }
        '^(System manufacturer|To be filled|Default string)' { ''; break }
        default { [string]$Device.Manufacturer }
    }
    $model = ([string]$Device.Model -replace '_.*$', '' -replace '^(ASUS|Lenovo|HP|Dell|Acer|MSI)\s+', '').Trim()
    if ($model -match '^(System Product Name|To be filled|Default string)$') { $model = '' }
    $name = ('{0} {1}' -f $maker, $model).Trim()
    if ($name) { $name } else { (T 'Esta PC') }
}

function Get-AfUiState {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag -isnot [hashtable]) { $Window.Tag = @{} }
    $s = $Window.Tag
    foreach ($key in 'Motion', 'Filter', 'NeedleF', 'Results') {
        if (-not $s.ContainsKey($key)) {
            $s[$key] = switch ($key) { 'Motion' { $false } 'Filter' { 'all' } 'NeedleF' { 0.0 } 'Results' { New-Object System.Collections.ArrayList } }
        }
    }
    if (-not $s.Initialized) {
        $s.Initialized = $true
        New-AfNav -Window $Window
        $Window.FindName('Gauge').Add_SizeChanged({ param($sender, $e) Update-AfGaugeLayout -Window ([System.Windows.Window]::GetWindow($sender)) })
        Update-AfGaugeLayout -Window $Window
    }
    $s
}

function New-AfSpecRow {
    param([string]$Icon, [string]$Text)
    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = 'Horizontal'
    $row.Margin = '0,0,0,9'
    [void]$row.Children.Add((New-AfIcon -Name $Icon -Size 15))
    $label = New-AfText -Text $Text -Size 12.5 -Brush 'Text2'
    $label.Margin = '9,0,0,0'
    $label.TextWrapping = 'NoWrap'
    $label.TextTrimming = 'CharacterEllipsis'
    $label.MaxWidth = 180
    [void]$row.Children.Add($label)
    $row
}

function Set-AfPcCard {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Inventory, [bool]$Animate = $false)
    $inv = $Inventory
    $Window.FindName('PcName').Text = Format-AfPcName -Device $inv.Device
    $discrete = @($inv.Gpus | Where-Object IsDiscrete)[0]
    $kind = if ($inv.Device.IsLaptop) { (T 'Laptop') } else { (T 'Escritorio') }
    if ($discrete) { $kind += ' gamer' }
    $Window.FindName('PcKind').Text = $kind
    $specs = $Window.FindName('Specs')
    $specs.Children.Clear()
    if ($inv.Cpu) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'cpu' -Text (Format-AfCpuName -Name $inv.Cpu.Name))) }
    $gpu = if ($discrete) { $discrete } else { @($inv.Gpus)[0] }
    if ($gpu) {
        $gpuText = if ($gpu.HasDriver -eq $false) { if ($gpu.Vendor -in 'NVIDIA', 'AMD', 'Intel') { (T '{0}, sin driver') -f $gpu.Vendor } else { (T 'Gráfica sin driver') } } else { Format-AfGpuName -Name $gpu.Name }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'graphics-card' -Text $gpuText))
    }
    if ($inv.Memory) {
        $channel = if ($inv.Memory.Socketed -and @($inv.Memory.Modules).Count -eq 1) { (T ', un canal') } elseif ($inv.Memory.Socketed -and @($inv.Memory.Modules).Count -ge 2) { ', doble canal' } else { '' }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'memory' -Text ('{0} GB{1}' -f $inv.Memory.TotalGB, $channel)))
    }
    if ($inv.Storage) {
        $media = if ($inv.Storage.MediaType -eq 'HDD') { (T 'Disco') } else { 'SSD' }
        [void]$specs.Children.Add((New-AfSpecRow -Icon 'hard-drives' -Text ((T '{0} {1} GB, {2} GB libres') -f $media, $inv.Storage.SizeGB, $inv.Storage.FreeGB)))
    }
    if ($inv.Os) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'windows-logo' -Text (([string]$inv.Os.Caption -replace '^Microsoft\s+', '')))) }
    if ($inv.Device.IsLaptop) { [void]$specs.Children.Add((New-AfSpecRow -Icon 'plug-charging' -Text $(if ($inv.Device.OnBattery) { (T 'En batería') } else { (T 'Con cargador') }))) }
    $card = $Window.FindName('PcCard')
    Start-AfAnimation -Target $card -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $Animate | Out-Null
}

function Get-AfNavEntries {
    @([pscustomobject]@{ Id = 'all'; Name = (T 'Todo'); Icon = 'squares-four' }) + @(Get-AfCategories) + @([pscustomobject]@{ Id = 'ok'; Name = (T 'En orden'); Icon = 'check-circle' })
}

function New-AfNav {
    param([Parameter(Mandatory)]$Window)
    $nav = $Window.FindName('Nav')
    $nav.Children.Clear()
    $refs = @{}
    foreach ($entry in Get-AfNavEntries) {
        $button = New-Object System.Windows.Controls.Button
        $button.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'NavButton')
        $button.Tag = $entry.Id
        $grid = New-Object System.Windows.Controls.Grid
        foreach ($width in 'Auto', '*', 'Auto') {
            $column = New-Object System.Windows.Controls.ColumnDefinition
            $column.Width = if ($width -eq '*') { New-Object System.Windows.GridLength(1, 'Star') } else { [System.Windows.GridLength]::Auto }
            [void]$grid.ColumnDefinitions.Add($column)
        }
        $iconHost = New-Object System.Windows.Controls.Grid
        $iconOff = New-AfIcon -Name $entry.Icon -Size 16 -Brush 'Text2'
        $iconOn = New-AfIcon -Name $entry.Icon -Variant Fill -Size 16 -Brush 'Text'
        $iconOn.Visibility = 'Collapsed'
        [void]$iconHost.Children.Add($iconOff)
        [void]$iconHost.Children.Add($iconOn)
        $label = New-AfText -Text $entry.Name -Size 13 -Brush 'Text2'
        $label.Margin = '10,0,0,0'
        $label.TextWrapping = 'NoWrap'
        [System.Windows.Controls.Grid]::SetColumn($label, 1)
        $countHost = New-Object System.Windows.Controls.Grid
        $countHost.MinWidth = 18
        $countHost.HorizontalAlignment = 'Right'
        [System.Windows.Controls.Grid]::SetColumn($countHost, 2)
        [void]$grid.Children.Add($iconHost)
        [void]$grid.Children.Add($label)
        [void]$grid.Children.Add($countHost)
        $button.Content = $grid
        $button.Add_Click({ param($sender, $e) Set-AfFilter -Window ([System.Windows.Window]::GetWindow($sender)) -Filter $sender.Tag })
        [void]$nav.Children.Add($button)
        $refs[$entry.Id] = @{ Button = $button; IconOff = $iconOff; IconOn = $iconOn; Label = $label; CountHost = $countHost; Count = 0 }
    }
    $Window.Tag.Nav = $refs
    Set-AfNavActive -Window $Window -Filter 'all' -Motion $false
}

function Set-AfNavSpinners {
    param([Parameter(Mandatory)]$Window)
    foreach ($id in $Window.Tag.Nav.Keys) {
        if ($id -eq 'all') { continue }
        $hostGrid = $Window.Tag.Nav[$id].CountHost
        $hostGrid.Children.Clear()
        [void]$hostGrid.Children.Add((New-AfSpinner -Size 12))
    }
}

function Get-AfPendingCount {
    param([string]$Category, [object[]]$Results = @())
    if ($Category -eq 'ok') { return @($Results | Where-Object { $_.Detection.State -eq 'Ok' }).Count }
    @($Results | Where-Object { $_.Check.Category -eq $Category -and ($_.Detection.State -eq 'Manual' -or ($_.Detection.State -eq 'Improvable' -and $_.Check.Kind -eq 'Auto')) }).Count
}

function Set-AfNavCount {
    param([Parameter(Mandatory)]$Window, [string]$Category, [int]$Count, [bool]$Motion = $false)
    $ref = $Window.Tag.Nav[$Category]
    if (-not $ref) { return }
    $ref.Count = $Count
    $hostGrid = $ref.CountHost
    $hostGrid.Children.Clear()
    if ($Count -gt 0 -or $Category -eq 'ok') {
        $text = New-AfText -Text ([string]$Count) -Size 12 -Brush $(if ($Category -eq 'ok') { 'Text3' } else { 'Text' }) -Display -Weight 'Medium'
        $text.HorizontalAlignment = 'Right'
        $element = $text
    } else {
        $element = New-AfIcon -Name 'check' -Size 13
        $element.HorizontalAlignment = 'Right'
    }
    [void]$hostGrid.Children.Add($element)
    Start-AfAnimation -Target $element -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Icon -Enabled $Motion | Out-Null
}

function Get-AfNavCount {
    param([Parameter(Mandatory)]$Window, [string]$Category)
    $Window.Tag.Nav[$Category].Count
}

function Update-AfNavCounts {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [string[]]$Only, [bool]$Motion = $false)
    foreach ($entry in Get-AfNavEntries) {
        if ($entry.Id -eq 'all') { continue }
        if ($Only -and $entry.Id -notin $Only) { continue }
        Set-AfNavCount -Window $Window -Category $entry.Id -Count (Get-AfPendingCount -Category $entry.Id -Results $Results) -Motion $Motion
    }
}

function Set-AfNavActive {
    param([Parameter(Mandatory)]$Window, [string]$Filter, [bool]$Motion = $false)
    foreach ($id in $Window.Tag.Nav.Keys) {
        $ref = $Window.Tag.Nav[$id]
        $on = $id -eq $Filter
        if ($on) { $ref.Button.SetResourceReference([System.Windows.Controls.Control]::BackgroundProperty, 'Line') } else { $ref.Button.Background = [System.Windows.Media.Brushes]::Transparent }
        $ref.IconOn.Visibility = if ($on) { 'Visible' } else { 'Collapsed' }
        $ref.IconOff.Visibility = if ($on) { 'Collapsed' } else { 'Visible' }
        $ref.Label.SetResourceReference([System.Windows.Controls.TextBlock]::ForegroundProperty, $(if ($on) { 'Text' } else { 'Text2' }))
    }
    $index = @(Get-AfNavEntries).Id.IndexOf($Filter)
    $y = [math]::Max(0, $index) * 34
    Start-AfAnimation -Target $Window.FindName('NavIndicatorTransform') -Property ([System.Windows.Media.TranslateTransform]::YProperty) -To $y -DurationMs 200 -Ease InOut -Enabled $Motion | Out-Null
}

function Set-AfFilter {
    param([Parameter(Mandatory)]$Window, [string]$Filter)
    $state = $Window.Tag
    # Desde el Historial, elegir una categoría vuelve a la lista; mientras deshace, se queda.
    if ($Window.FindName('HistoryPanel').Visibility -eq 'Visible') {
        if (Test-AfBusyPhase -Phase $state.Phase) { return }
        Hide-AfHistory -Window $Window
    }
    $state.Filter = $Filter
    Set-AfNavActive -Window $Window -Filter $Filter -Motion $state.Motion
    foreach ($group in $Window.FindName('Groups').Children) {
        $show = $Filter -eq 'all' -or $group.Tag -eq $Filter
        $group.Visibility = if ($show) { 'Visible' } else { 'Collapsed' }
        if ($group.Tag -eq 'ok' -and $Filter -eq 'ok') { Set-AfOkGroupOpen -Group $group -Open $true -Motion $false }
    }
    $Window.FindName('ListScroll').ScrollToTop()
}

function Update-AfGaugeLayout {
    param([Parameter(Mandatory)]$Window)
    $gauge = $Window.FindName('Gauge')
    $width = $gauge.ActualWidth
    if ($width -le 0) { return }
    foreach ($canvasName in 'Ticks', 'LitTicks') {
        $canvas = $Window.FindName($canvasName)
        if ($canvas.Children.Count -ne 61) {
            $canvas.Children.Clear()
            for ($i = 0; $i -le 60; $i++) {
                $tick = New-Object System.Windows.Shapes.Rectangle
                $tick.Width = if ($i -eq 60) { 2 } else { 1 }
                $tick.Height = if ($i -eq 60) { 20 } elseif ($i % 10 -eq 0) { 13 } else { 7 }
                $tick.RadiusX = 0.5
                $tick.RadiusY = 0.5
                $brush = if ($canvasName -eq 'LitTicks' -or $i -eq 60) { 'Red' } elseif ($i % 10 -eq 0) { 'TickMajor' } else { 'Tick' }
                $tick.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, $brush)
                if ($canvasName -eq 'LitTicks') { $tick.Opacity = 0 } elseif (-not $Window.Tag.TicksHidden) { $tick.Opacity = 1 } else { $tick.Opacity = 0 }
                [System.Windows.Controls.Canvas]::SetBottom($tick, 0)
                [void]$canvas.Children.Add($tick)
            }
        }
        for ($i = 0; $i -le 60; $i++) {
            $x = if ($i -eq 60) { $width - 2 } else { [math]::Round($i * ($width - 2) / 60) }
            [System.Windows.Controls.Canvas]::SetLeft($canvas.Children[$i], $x)
        }
    }
    $needle = $Window.FindName('NeedleTransform')
    $needle.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null)
    $needle.X = $Window.Tag.NeedleF * ($width - 2)
}

function Show-AfTicks {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $Window.Tag.TicksHidden = $false
    $i = 0
    foreach ($tick in $Window.FindName('Ticks').Children) {
        Start-AfAnimation -Target $tick -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -DelayMs (120 + $i * 9) -Ease Linear -Enabled $Motion | Out-Null
        $i++
    }
}

function Set-AfNeedle {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false, [int]$DurationMs = 700, [string]$Ease = 'Out')
    $Window.Tag.NeedleF = $Fraction
    $width = $Window.FindName('Gauge').ActualWidth - 2
    Start-AfAnimation -Target $Window.FindName('NeedleTransform') -Property ([System.Windows.Media.TranslateTransform]::XProperty) -To ([math]::Max(0, $Fraction * $width)) -DurationMs $DurationMs -Ease $Ease -Enabled $Motion | Out-Null
}

# Autotest del arranque: la aguja recorre la escala hasta "Afinado" y vuelve.
function Start-AfNeedleSweep {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $Window.Tag.NeedleF = 0
    $transform = $Window.FindName('NeedleTransform')
    if (-not $Motion) { $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $null); $transform.X = 0; return }
    $width = $Window.FindName('Gauge').ActualWidth - 2
    $animation = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
    $animation.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1500))
    [void]$animation.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame($width, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(780)), (New-AfKeySpline -Ease InOut))))
    [void]$animation.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(1500)), (New-AfKeySpline -Ease InOut))))
    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animation)
}

function Start-AfCelebration {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    if (-not $Motion) { return }
    $i = 0
    foreach ($tick in $Window.FindName('LitTicks').Children) {
        $flash = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
        $flash.BeginTime = [TimeSpan]::FromMilliseconds($i * 9)
        $flash.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(560))
        [void]$flash.KeyFrames.Add((New-Object System.Windows.Media.Animation.LinearDoubleKeyFrame(1, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(196)))))
        [void]$flash.KeyFrames.Add((New-Object System.Windows.Media.Animation.SplineDoubleKeyFrame(0, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromMilliseconds(560)), (New-AfKeySpline -Ease Out))))
        $tick.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $flash)
        $i++
    }
}

function Set-AfTextAnimated {
    param([Parameter(Mandatory)]$Block, [string]$Text, [bool]$Motion = $false)
    $Block.Text = $Text
    Start-AfAnimation -Target $Block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

function Set-AfSummary {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Summary, [bool]$Motion = $false)
    $block = $Window.FindName('Summary')
    $block.Inlines.Clear()
    if ($Summary.Ready -gt 0) {
        $lead = New-Object System.Windows.Documents.Run($(if ($Summary.Ready -eq 1) { (T '1 cambio listo') } else { (T '{0} cambios listos') -f $Summary.Ready }))
        $lead.FontWeight = 'Medium'
        $lead.SetResourceReference([System.Windows.Documents.TextElement]::ForegroundProperty, 'Text')
        $block.Inlines.Add($lead)
        $rest = (T ', {0} para hacer a mano y {1} en orden.') -f $Summary.Manual, $Summary.Ok
        $block.Inlines.Add((New-Object System.Windows.Documents.Run($rest)))
    } else {
        $block.Inlines.Add((New-Object System.Windows.Documents.Run(((T 'Todo lo que Afina puede ajustar ya está en orden. {0} para hacer a mano.') -f $Summary.Manual))))
    }
    Start-AfAnimation -Target $block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

function Add-AfRowHandlers {
    param([Parameter(Mandatory)]$Row)
    $Row.Add_MouseLeftButtonUp({
            param($sender, $e)
            # Los clics dentro del detalle abierto (opciones, textos) no lo cierran.
            $detail = $sender.FindName('Detail')
            $source = $e.OriginalSource
            if ($detail.Tag -eq 'open' -and $source -is [System.Windows.Media.Visual] -and $detail.IsAncestorOf($source)) { return }
            $w = [System.Windows.Window]::GetWindow($sender)
            Switch-AfRowDetail -Row $sender -Motion ([bool]$w.Tag.Motion)
        })
    $box = Get-AfRowCheckBox -Row $Row
    if ($box) {
        $box.Tag = $Row
        $box.Add_Click({
                param($sender, $e)
                if ($sender.IsChecked -and $sender.Tag) { Reset-AfChoices -Row $sender.Tag }
                Update-AfPrimary -Window ([System.Windows.Window]::GetWindow($sender)) -Roll $true
            })
    }
}

function Add-AfCategoryGroup {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Category, [object[]]$Results = @(), [bool]$Motion = $false)
    $visible = @($Results | Where-Object { $_.Detection.State -in 'Improvable', 'Manual', 'Info', 'Error' })
    if (-not $visible.Count) { return }
    $groups = $Window.FindName('Groups')
    $Window.FindName('PanelBorder').Visibility = 'Visible'
    $first = @($groups.Children | Where-Object { $_.Tag -ne 'ok' }).Count -eq 0
    $group = New-AfGroupElement -Category $Category -Results $visible -First:$first
    $filter = $Window.Tag.Filter
    $group.Visibility = if ($filter -eq 'all' -or $filter -eq $Category.Id) { 'Visible' } else { 'Collapsed' }
    $okGroup = @($groups.Children | Where-Object { $_.Tag -eq 'ok' })[0]
    if ($okGroup) { $groups.Children.Insert($groups.Children.IndexOf($okGroup), $group) } else { [void]$groups.Children.Add($group) }
    $k = 0
    foreach ($child in $group.Children) {
        if ($child -is [System.Windows.Controls.Border] -and $child.Tag) { Add-AfRowHandlers -Row $child }
        if ($Motion) {
            $child.Opacity = 0
            $shift = New-Object System.Windows.Media.TranslateTransform(0, 8)
            $child.RenderTransform = $shift
            Start-AfAnimation -Target $child -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -DelayMs ($k * 50) -Ease Out -Enabled $true | Out-Null
            Start-AfAnimation -Target $shift -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 8 -To 0 -DurationMs 300 -DelayMs ($k * 50) -Ease Out -Enabled $true | Out-Null
            $k++
        }
    }
}

function Set-AfOkGroupOpen {
    param([Parameter(Mandatory)]$Group, [bool]$Open, [bool]$Motion = $false)
    $list = $Group.Children[$Group.Children.Count - 1]
    $Group.Resources['Open'] = $Open
    $list.Visibility = if ($Open) { 'Visible' } else { 'Collapsed' }
    $caret = $Group.Resources['Caret']
    if ($caret) { Start-AfAnimation -Target $caret -Property ([System.Windows.Media.RotateTransform]::AngleProperty) -To $(if ($Open) { 180 } else { 0 }) -DurationMs 200 -Ease Out -Enabled $Motion | Out-Null }
    if ($Open) { Start-AfAnimation -Target $list -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 250 -Ease Out -Enabled $Motion | Out-Null }
}

function Add-AfOkGroup {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [bool]$Motion = $false)
    $ok = @($Results | Where-Object { $_.Detection.State -eq 'Ok' })
    if (-not $ok.Count) { return }
    $groups = $Window.FindName('Groups')
    $Window.FindName('PanelBorder').Visibility = 'Visible'
    $group = New-Object System.Windows.Controls.StackPanel
    $group.Tag = 'ok'
    if ($groups.Children.Count) {
        $line = New-Object System.Windows.Shapes.Rectangle
        $line.Height = 1
        $line.SetResourceReference([System.Windows.Shapes.Shape]::FillProperty, 'Line')
        [void]$group.Children.Add($line)
    }
    $header = New-Object System.Windows.Controls.Border
    $header.Padding = '18,12,18,12'
    $header.Background = [System.Windows.Media.Brushes]::Transparent
    $header.Cursor = 'Hand'
    $headerGrid = New-Object System.Windows.Controls.DockPanel
    $caretRotate = New-Object System.Windows.Media.RotateTransform
    $caret = New-AfIcon -Name 'caret-down' -Size 12
    $caret.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $caret.RenderTransform = $caretRotate
    [System.Windows.Controls.DockPanel]::SetDock($caret, 'Right')
    $count = New-AfText -Text ([string]$ok.Count) -Size 12 -Brush 'Text3' -Display
    $count.Margin = '0,0,12,0'
    [System.Windows.Controls.DockPanel]::SetDock($count, 'Right')
    [void]$headerGrid.Children.Add($caret)
    [void]$headerGrid.Children.Add($count)
    [void]$headerGrid.Children.Add((New-AfIcon -Name 'check-circle' -Size 17))
    $label = New-AfText -Text (T 'En orden') -Size 13 -Brush 'Text2'
    $label.Margin = '14,0,0,0'
    [void]$headerGrid.Children.Add($label)
    $header.Child = $headerGrid
    [void]$group.Children.Add($header)
    $list = New-Object System.Windows.Controls.StackPanel
    $list.Margin = '0,0,0,8'
    foreach ($result in $ok) {
        $item = New-Object System.Windows.Controls.StackPanel
        $item.Orientation = 'Horizontal'
        $item.Margin = '18,6,18,6'
        $mark = New-AfIcon -Name 'check' -Size 14
        $mark.Margin = '2,0,16,0'
        [void]$item.Children.Add($mark)
        $title = if ($result.Detection.Title) { $result.Detection.Title } else { $result.Check.Title }
        $text = New-AfText -Text $title -Size 12.5 -Brush 'Text2'
        [void]$item.Children.Add($text)
        if ($result.Detection.Current) {
            $value = New-AfText -Text ('  ' + $result.Detection.Current) -Size 12.5 -Brush 'Text3'
            [void]$item.Children.Add($value)
        }
        [void]$list.Children.Add($item)
    }
    [void]$group.Children.Add($list)
    $group.Resources['Caret'] = $caretRotate
    $header.Add_MouseLeftButtonUp({ param($sender, $e)
            $g = $sender.Parent
            $w = [System.Windows.Window]::GetWindow($sender)
            Set-AfOkGroupOpen -Group $g -Open (-not [bool]$g.Resources['Open']) -Motion ([bool]$w.Tag.Motion)
        })
    Set-AfOkGroupOpen -Group $group -Open $false
    $filter = $Window.Tag.Filter
    $group.Visibility = if ($filter -eq 'all' -or $filter -eq 'ok') { 'Visible' } else { 'Collapsed' }
    [void]$groups.Children.Add($group)
    if ($Motion) { Start-AfAnimation -Target $group -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled $true | Out-Null }
}

function Get-AfRows {
    param([Parameter(Mandatory)]$Window)
    foreach ($group in $Window.FindName('Groups').Children) {
        foreach ($child in $group.Children) {
            if ($child -is [System.Windows.Controls.Border] -and $child.Tag -and $child.Tag.Check) { $child }
        }
    }
}

function Get-AfRowById {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$Id)
    @(Get-AfRows -Window $Window | Where-Object { $_.Tag.Check.Id -eq $Id })[0]
}

# Resultados con la casilla marcada, en el orden de la lista.
function Get-AfSelectedResults {
    param([Parameter(Mandatory)]$Window)
    foreach ($row in @(Get-AfRows -Window $Window)) {
        $box = Get-AfRowCheckBox -Row $row
        if ($box -and $box.IsChecked) { $row.Tag }
    }
}

function Get-AfSelectedCount {
    param([Parameter(Mandatory)]$Window)
    @(Get-AfSelectedResults -Window $Window).Count
}

function Update-AfPrimary {
    param([Parameter(Mandatory)]$Window, [bool]$Roll = $false)
    # Fuera de "listo para optimizar", el botón lo maneja Set-AfFooter.
    if ($Window.Tag.Phase -and $Window.Tag.Phase -ne 'ready') { return }
    $n = Get-AfSelectedCount -Window $Window
    $lead = $Window.FindName('PrimaryLead')
    $number = $Window.FindName('PrimaryNumber')
    $tail = $Window.FindName('PrimaryTail')
    if ($n -eq 0) {
        $lead.Text = (T 'Elige qué optimizar')
        $number.Text = ''
        $tail.Text = ''
        return
    }
    # Los espacios van en el código: las traducciones no llevan espacios al principio ni al final.
    $lead.Text = (T 'Optimizar') + ' '
    $number.Text = [string]$n
    $tail.Text = ' ' + $(if ($n -eq 1) { (T 'cambio') } else { (T 'cambios') })
    if ($Roll -and $Window.Tag.Motion) {
        Start-AfAnimation -Target $number -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 180 -Ease Out | Out-Null
        Start-AfAnimation -Target $Window.FindName('PrimaryNumberShift') -Property ([System.Windows.Media.TranslateTransform]::YProperty) -From 8 -To 0 -DurationMs 180 -Ease Out | Out-Null
    }
}

function Show-AfResults {
    param([Parameter(Mandatory)]$Window, [object[]]$Results = @(), [bool]$Animate = $false)
    $state = Get-AfUiState -Window $Window
    $state.Phase = 'ready'
    $state.Results = New-Object System.Collections.ArrayList(, @($Results))
    $Window.FindName('Groups').Children.Clear()
    foreach ($category in Get-AfCategories) {
        Add-AfCategoryGroup -Window $Window -Category $category -Results @($Results | Where-Object { $_.Check.Category -eq $category.Id }) -Motion $Animate
    }
    Add-AfOkGroup -Window $Window -Results $Results -Motion $Animate
    Update-AfNavCounts -Window $Window -Results $Results -Motion $Animate
    Set-AfSummary -Window $Window -Summary (Get-AfSummary -Results $Results) -Motion $Animate
    $Window.FindName('Title').Text = (T 'Afinación')
    $Window.FindName('Actions').Opacity = 1
    $Window.FindName('Actions').IsHitTestVisible = $true
    $Window.FindName('PcCard').Opacity = 1
    Update-AfPrimary -Window $Window
    Set-AfNeedle -Window $Window -Fraction (Get-AfScore -Results $Results) -Motion $Animate
}

# Confirmación, aplicando, listo y deshacer (diseño, sección 8, pasos 4 a 8).

function Set-AfFooterButton {
    param($Button, $TextBlock, $IconPath, [string]$Text, [string]$Icon)
    if (-not $Text) { $Button.Visibility = 'Collapsed'; return }
    $Button.Visibility = 'Visible'
    $TextBlock.Text = $Text
    if ($Icon) { Set-AfIconData -Path $IconPath -Name $Icon; $IconPath.Visibility = 'Visible' } else { $IconPath.Visibility = 'Collapsed' }
}

# Pie de la ventana: nota, opción de Restaurar sistema y hasta tres botones. Un botón sin texto se oculta.
function Set-AfFooter {
    param(
        [Parameter(Mandatory)]$Window,
        [string]$Note,
        [string]$NoteIcon = 'shield-check',
        [string]$Ghost,
        [string]$GhostIcon,
        [string]$Extra,
        [string]$ExtraIcon,
        [string]$Primary,
        [switch]$PrimaryOptimize,
        [switch]$Busy,
        $RestoreOption = $null,
        [bool]$Motion = $false
    )
    if ($PSBoundParameters.ContainsKey('Note')) {
        $block = $Window.FindName('NoteText')
        if ($block.Text -ne $Note) { Set-AfTextAnimated -Block $block -Text $Note -Motion $Motion }
        Set-AfIconData -Path $Window.FindName('NoteIcon') -Name $NoteIcon
    }
    $restoreRow = $Window.FindName('RestoreRow')
    if ($null -ne $RestoreOption) {
        $restoreRow.Visibility = 'Visible'
        $Window.FindName('RestoreOption').IsChecked = [bool]$RestoreOption
    } else {
        $restoreRow.Visibility = 'Collapsed'
    }
    Set-AfFooterButton -Button $Window.FindName('GhostButton') -TextBlock $Window.FindName('GhostText') -IconPath $Window.FindName('GhostIcon') -Text $Ghost -Icon $GhostIcon
    Set-AfFooterButton -Button $Window.FindName('ExtraButton') -TextBlock $Window.FindName('ExtraText') -IconPath $Window.FindName('ExtraIcon') -Text $Extra -Icon $ExtraIcon
    $button = $Window.FindName('PrimaryButton')
    $button.IsHitTestVisible = -not $Busy
    if ($PrimaryOptimize) {
        $button.Visibility = 'Visible'
        Update-AfPrimary -Window $Window
    } elseif ($Primary) {
        $button.Visibility = 'Visible'
        $Window.FindName('PrimaryLead').Text = $Primary
        $Window.FindName('PrimaryNumber').Text = ''
        $Window.FindName('PrimaryTail').Text = ''
    } else {
        $button.Visibility = 'Collapsed'
    }
}

function Get-AfConfirmText {
    param([int]$Count, [bool]$Network = $false, [bool]$Display = $false, [int]$Reboot = 0, [ValidateSet('create', 'enable', 'off', 'blocked')][string]$Restore = 'create', [bool]$Updates = $false, [int]$Advanced = 0)
    $parts = @()
    $parts += if ($Count -eq 1) { (T 'Se aplicará 1 cambio.') } else { (T 'Se aplicarán {0} cambios.') -f $Count }
    if ($Updates) { $parts += (T 'Las actualizaciones pueden tardar varios minutos.') }
    if ($Advanced -eq 1) { $parts += (T '1 cambio baja la seguridad de Windows.') } elseif ($Advanced -gt 1) { $parts += (T '{0} cambios bajan la seguridad de Windows.') -f $Advanced }
    if ($Display) { $parts += (T 'La pantalla cambia y pide confirmar.') }
    if ($Network) { $parts += (T 'La red se cortará unos segundos.') }
    if ($Reboot -gt 0) { $parts += (T 'Al final pide reiniciar.') }
    $parts += switch ($Restore) {
        'create' { (T 'Se crea un punto de restauración antes.') }
        'enable' { (T 'Se activa Restaurar sistema y se crea un punto antes.') }
        'off' { (T 'Sin punto de restauración: Restaurar sistema está apagado. Los valores originales igual se guardan.') }
        'blocked' { (T 'Restaurar sistema está bloqueado en esta PC; los valores originales igual se guardan.') }
    }
    $parts -join ' '
}

function Get-AfDoneText {
    param([int]$Applied, [int]$Failed = 0, [int]$Reboot = 0, [int]$Manual = 0)
    $lead = switch ($Applied) { 0 { (T 'Ningún cambio aplicado') } 1 { (T '1 cambio aplicado') } default { (T '{0} cambios aplicados') -f $Applied } }
    # Los espacios van en el código: las traducciones no llevan espacios al principio ni al final.
    $rest = ''
    if ($Failed -eq 1) { $rest += ' ' + (T 'y 1 no se pudo') } elseif ($Failed -gt 1) { $rest += ' ' + ((T 'y {0} no se pudieron') -f $Failed) }
    $rest += '.'
    if ($Reboot -eq 1) { $rest += ' ' + (T 'Reinicia para terminar 1.') } elseif ($Reboot -gt 1) { $rest += ' ' + ((T 'Reinicia para terminar {0}.') -f $Reboot) }
    if ($Manual -eq 1) { $rest += ' ' + (T 'Queda 1 para hacer a mano.') } elseif ($Manual -gt 1) { $rest += ' ' + ((T 'Quedan {0} para hacer a mano.') -f $Manual) }
    [pscustomobject]@{ Lead = $lead; Rest = $rest; Text = $lead + $rest }
}

function Get-AfDisplayPrompt {
    param([int]$Seconds = 15)
    (T '¿Se ve bien la pantalla? Vuelve sola al modo anterior en {0} s.') -f $Seconds
}

function Set-AfLeadSummary {
    param([Parameter(Mandatory)]$Window, [string]$Lead, [string]$Rest, [bool]$Motion = $false)
    $block = $Window.FindName('Summary')
    $block.Inlines.Clear()
    $run = New-Object System.Windows.Documents.Run($Lead)
    $run.FontWeight = 'Medium'
    $run.SetResourceReference([System.Windows.Documents.TextElement]::ForegroundProperty, 'Text')
    $block.Inlines.Add($run)
    if ($Rest) { $block.Inlines.Add((New-Object System.Windows.Documents.Run($Rest))) }
    Start-AfAnimation -Target $block -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 220 -Ease Out -Enabled $Motion | Out-Null
}

# Los resultados con lo ya aplicado como "en orden": así se mueven la aguja, el resumen y los contadores.
function Get-AfEffectiveResults {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    foreach ($result in @($s.Results)) {
        $change = if ($s.Applied) { $s.Applied[$result.Check.Id] } else { $null }
        if ($change -and $change.Status -eq 'Applied') {
            [pscustomobject]@{ Check = $result.Check; Detection = (New-AfDetection -State Ok -Title $result.Detection.Title -Current $result.Detection.Target); Weight = $result.Weight; Preselected = $false }
        } else {
            $result
        }
    }
}

function Update-AfProgressView {
    param([Parameter(Mandatory)]$Window, [bool]$Motion = $false)
    $effective = @(Get-AfEffectiveResults -Window $Window)
    Set-AfNeedle -Window $Window -Fraction (Get-AfScore -Results $effective) -Motion $Motion -DurationMs 460 -Ease InOut
    Update-AfNavCounts -Window $Window -Results $effective -Motion $Motion
}

function Set-AfProgress {
    param([Parameter(Mandatory)]$Window, [double]$Fraction, [bool]$Motion = $false)
    Start-AfAnimation -Target $Window.FindName('PrimaryProgressScale') -Property ([System.Windows.Media.ScaleTransform]::ScaleXProperty) -To ([math]::Min(1, [math]::Max(0, $Fraction))) -DurationMs 460 -Ease InOut -Enabled $Motion | Out-Null
}

function Get-AfReadyNote { (T 'Se crea un punto de restauración antes de aplicar') }

function Set-AfReadyView {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    $Window.FindName('Groups').IsHitTestVisible = $true
    $effective = @(Get-AfEffectiveResults -Window $Window)
    $summary = Get-AfSummary -Results $effective
    $score = Get-AfScore -Results $effective
    $Window.FindName('Title').Text = if ($summary.Ready -eq 0 -and $score -ge 0.999) { (T 'Afinada') } else { (T 'Afinación') }
    Set-AfSummary -Window $Window -Summary $summary -Motion $s.Motion
    Set-AfProgress -Window $Window -Fraction 0 -Motion $s.Motion
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
}

function Set-AfDoneView {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'done'
    $Window.FindName('Groups').IsHitTestVisible = $true
    $changes = @($s.Applied.Values)
    $applied = @($changes | Where-Object { $_.Status -eq 'Applied' })
    $notApplied = @($changes | Where-Object { $_.Status -in 'Failed', 'Reverted' }).Count
    $reboot = @($applied | Where-Object { $_.NeedsReboot }).Count
    $effective = @(Get-AfEffectiveResults -Window $Window)
    $summary = Get-AfSummary -Results $effective
    $score = Get-AfScore -Results $effective
    $text = Get-AfDoneText -Applied $applied.Count -Failed $notApplied -Reboot $reboot -Manual $summary.Manual
    $Window.FindName('Title').Text = if ($summary.Ready -eq 0 -and $score -ge 0.999) { (T 'Afinada') } else { (T 'Afinación') }
    Set-AfLeadSummary -Window $Window -Lead $text.Lead -Rest $text.Rest -Motion $s.Motion
    Set-AfProgress -Window $Window -Fraction 0 -Motion $s.Motion
    $extra = if (@($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count) { (T 'Deshacer') } else { $null }
    $note = (T 'Valores originales guardados. Se puede deshacer desde Historial.')
    if ($s.RebootPending) {
        Set-AfFooter -Window $Window -Note $note -NoteIcon 'shield-check' -Extra $extra -ExtraIcon 'arrow-counter-clockwise' -Ghost (T 'Más tarde') -Primary (T 'Reiniciar ahora') -Motion $s.Motion
    } else {
        Set-AfFooter -Window $Window -Note $note -NoteIcon 'shield-check' -Extra $extra -ExtraIcon 'arrow-counter-clockwise' -Primary (T 'Volver a analizar') -Motion $s.Motion
    }
}

function Enter-AfConfirm {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $selected = @(Get-AfSelectedResults -Window $Window)
    if (-not $selected.Count) { return }
    if (-not $s.DemoCode -and -not (Test-AfAdmin)) {
        Set-AfFooter -Window $Window -Note (T 'Para aplicar cambios, abre Afina como administrador.') -NoteIcon 'warning-circle' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
        return
    }
    $status = Get-AfRestoreStatus
    $restore = if ($status.Enabled) { 'create' } elseif ($status.Blocked) { 'blocked' } else { 'enable' }
    $s.Confirm = [pscustomobject]@{
        Selected = $selected
        Restore = $restore
        Count = $selected.Count
        Network = @($selected | Where-Object { $_.Check.Category -eq 'network' }).Count -gt 0
        Display = @($selected | Where-Object { $_.Check.Id -eq 'display.refresh' }).Count -gt 0
        Reboot = @($selected | Where-Object { $_.Check.NeedsReboot }).Count
        Updates = @($selected | Where-Object { $_.Check.Id -like 'updates.*' }).Count -gt 0
        Advanced = @($selected | Where-Object { $_.Check.Risk -eq 'Advanced' }).Count
    }
    $s.Phase = 'confirm'
    $Window.FindName('Groups').IsHitTestVisible = $false
    $option = if ($restore -eq 'enable') { $true } else { $null }
    Set-AfFooter -Window $Window -Note (Get-AfConfirmNote -Window $Window) -NoteIcon 'shield-check' -Ghost (T 'Cancelar') -Primary (T 'Aplicar') -RestoreOption $option -Motion $s.Motion
}

# El texto de la confirmación según lo elegido y la casilla de Restaurar sistema.
function Get-AfConfirmNote {
    param([Parameter(Mandatory)]$Window)
    $c = $Window.Tag.Confirm
    $restore = $c.Restore
    if ($restore -eq 'enable' -and $Window.FindName('RestoreRow').Visibility -eq 'Visible' -and -not $Window.FindName('RestoreOption').IsChecked) { $restore = 'off' }
    Get-AfConfirmText -Count $c.Count -Network $c.Network -Display $c.Display -Reboot $c.Reboot -Restore $restore -Updates ([bool]$c.Updates) -Advanced ([int]$c.Advanced)
}

function Exit-AfConfirm {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    $Window.FindName('Groups').IsHitTestVisible = $true
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize -Motion $s.Motion
}

function Get-AfWorkerCode {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag.DemoCode) { $Global:AfCode + "`r`n" + $Window.Tag.DemoCode } else { $Global:AfCode }
}

function Start-AfApply {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $c = $s.Confirm
    $restore = $c.Restore
    if ($restore -eq 'enable' -and -not $Window.FindName('RestoreOption').IsChecked) { $restore = 'off' }
    $action = if ($restore -in 'create', 'enable') { $restore } else { 'none' }
    $s.Phase = 'applying'
    $s.Applied = @{}
    $s.RebootPending = $false
    $s.ApplyTotal = $c.Count
    $s.ApplyIndex = 0
    $s.ApplyCount = 0
    $s.ApplyNote = 'Preparando…'
    $s.Shared = [hashtable]::Synchronized(@{ DisplayAnswer = $null; ContinueWithoutRestore = $null; Current = $null })
    $s.ApplyQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $plan = [pscustomobject]@{
        Mode = 'Apply'
        Items = @($c.Selected | ForEach-Object { [pscustomobject]@{ Id = $_.Check.Id; Detection = $_.Detection } })
        Inventory = $s.Inventory
        RestoreAction = $action
        BackupDirectory = $s.BackupDirectory
        Version = Get-AfVersion
        LogPath = Get-AfLogPath
        Language = Get-AfLanguage
    }
    Set-AfFooter -Window $Window -Note $s.ApplyNote -NoteIcon 'shield-check' -Primary (T 'Preparando…') -Busy -Motion $s.Motion
    Set-AfProgress -Window $Window -Fraction 0
    Write-AfLog -Level Info -Message ('Aplicar {0} cambios: {1}' -f $c.Count, (@($plan.Items.Id) -join ', '))
    $s.ApplyWorker = Start-AfApplyWorker -Code (Get-AfWorkerCode -Window $Window) -Queue $s.ApplyQueue -Shared $s.Shared -Plan $plan
}

function Set-AfApplyingFooter {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $label = if ($s.ApplyIndex -gt 0) { (T 'Aplicando {0} de {1}') -f $s.ApplyIndex, $s.ApplyTotal } else { 'Preparando…' }
    Set-AfFooter -Window $Window -Note $s.ApplyNote -NoteIcon 'shield-check' -Primary $label -Busy -Motion $s.Motion
}

function Start-AfDisplayCountdown {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.DisplayTimer) { $s.DisplayTimer.Stop() }
    $s.DisplaySeconds = 15
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Tag = $Window
    $timer.Add_Tick({
            param($sender, $e)
            $w = $sender.Tag
            $w.Tag.DisplaySeconds--
            if ($w.Tag.DisplaySeconds -le 0 -or $w.Tag.Phase -ne 'display') { $sender.Stop(); return }
            $w.FindName('NoteText').Text = Get-AfDisplayPrompt -Seconds $w.Tag.DisplaySeconds
        })
    $s.DisplayTimer = $timer
    $timer.Start()
}

function Stop-AfDisplayCountdown {
    param([Parameter(Mandatory)]$Window)
    if ($Window.Tag.DisplayTimer) { $Window.Tag.DisplayTimer.Stop() }
}

function Start-AfUndo {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)][string]$SessionPath, [string[]]$ChangeIds = @(), [switch]$FromHistory)
    $s = $Window.Tag
    $s.UndoFromHistory = [bool]$FromHistory
    $s.Phase = 'undoing'
    $s.UndoIndex = 0
    $session = Import-AfSession -Path $SessionPath
    $s.UndoTotal = @($session.Changes | Where-Object { ($ChangeIds.Count -eq 0 -or $ChangeIds -contains $_.CheckId) -and (Test-AfChangeUndoable -Change $_) }).Count
    if ($FromHistory) { $Window.FindName('HistoryList').IsHitTestVisible = $false } else { $Window.FindName('Groups').IsHitTestVisible = $false }
    Set-AfFooter -Window $Window -Note (T 'Deshaciendo con los valores originales guardados…') -NoteIcon 'arrow-counter-clockwise' -Primary (T 'Deshaciendo…') -Busy -Motion $s.Motion
    $s.Shared = [hashtable]::Synchronized(@{})
    $s.ApplyQueue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $plan = [pscustomobject]@{ Mode = 'Undo'; SessionPath = $SessionPath; ChangeIds = @($ChangeIds); LogPath = Get-AfLogPath; Language = Get-AfLanguage }
    Write-AfLog -Level Info -Message "Deshacer $SessionPath ($(if ($ChangeIds.Count) { $ChangeIds -join ', ' } else { 'todo' }))"
    $s.ApplyWorker = Start-AfApplyWorker -Code (Get-AfWorkerCode -Window $Window) -Queue $s.ApplyQueue -Shared $s.Shared -Plan $plan
}

function Complete-AfUndo {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.UndoFromHistory) {
        $s.NeedsRescan = $true
        Show-AfHistory -Window $Window
        return
    }
    Set-AfReadyView -Window $Window
    Update-AfProgressView -Window $Window -Motion $s.Motion
}

function Receive-AfApplyEvent {
    param([Parameter(Mandatory)]$Window, [Parameter(Mandatory)]$Item)
    $s = $Window.Tag
    switch ($Item.Type) {
        'Stage' {
            $s.ApplyNote = $Item.Text
            Set-AfApplyingFooter -Window $Window
        }
        'RestorePoint' {
            if ($Item.Ok) {
                $s.ApplyNote = (T 'Punto de restauración creado a las {0}.') -f (Format-AfTime -Date ([datetime]$Item.At))
                Set-AfApplyingFooter -Window $Window
            } else {
                $s.Phase = 'restore'
                Set-AfFooter -Window $Window -Note ((T 'No se pudo crear el punto de restauración: {0}. Los valores originales igual se guardan en Afina.') -f $Item.Message) -NoteIcon 'warning-circle' -Ghost (T 'Cancelar') -Primary (T 'Seguir sin punto') -Motion $s.Motion
            }
        }
        'Cancelled' { Set-AfReadyView -Window $Window }
        'ChangeStart' {
            $s.ApplyIndex++
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) { Set-AfRowStatus -Row $row -Status Applying -Motion $s.Motion }
            Set-AfApplyingFooter -Window $Window
        }
        'ChangeProgress' {
            # Avance de un cambio largo (actualizaciones): solo cambia la nota, el indicador sigue girando.
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) { Set-AfRowNote -Row $row -Text $Item.Text }
        }
        'ConfirmDisplay' {
            $s.Phase = 'display'
            Set-AfFooter -Window $Window -Note (Get-AfDisplayPrompt -Seconds 15) -NoteIcon 'info' -Ghost (T 'Volver al anterior') -Primary (T 'Mantener') -Motion $s.Motion
            Start-AfDisplayCountdown -Window $Window
        }
        'ChangeDone' {
            Stop-AfDisplayCountdown -Window $Window
            $s.Phase = 'applying'
            $change = $Item.Change
            $s.Applied[$Item.Id] = $change
            $s.ApplyCount++
            if ($change.Status -eq 'Applied' -and $change.NeedsReboot) { $s.RebootPending = $true }
            $row = Get-AfRowById -Window $Window -Id $Item.Id
            if ($row) {
                $message = if ($change.Status -eq 'Applied') { $change.Note } else { $change.Message }
                Set-AfRowStatus -Row $row -Status $change.Status -Message $message -Motion $s.Motion
            }
            Set-AfProgress -Window $Window -Fraction ($s.ApplyCount / [math]::Max(1, $s.ApplyTotal)) -Motion $s.Motion
            Update-AfProgressView -Window $Window -Motion $s.Motion
            Set-AfApplyingFooter -Window $Window
        }
        'ApplyDone' {
            $s.SessionPath = $Item.SessionPath
            Set-AfDoneView -Window $Window
            $score = Get-AfScore -Results @(Get-AfEffectiveResults -Window $Window)
            Set-AfNeedle -Window $Window -Fraction $score -Motion $s.Motion -DurationMs 700 -Ease Out
            if ($score -ge 0.999) { Start-AfCelebration -Window $Window -Motion $s.Motion }
            Write-AfLog -Level Info -Message "Sesión guardada en $($Item.SessionPath)"
        }
        'UndoStart' {
            $s.UndoIndex++
            if (-not $s.UndoFromHistory) {
                $row = Get-AfRowById -Window $Window -Id $Item.Id
                if ($row) { Set-AfRowStatus -Row $row -Status Undoing -Motion $s.Motion }
            }
            Set-AfFooter -Window $Window -Primary ((T 'Deshaciendo {0} de {1}') -f $s.UndoIndex, [math]::Max($s.UndoIndex, $s.UndoTotal)) -Busy
        }
        'UndoDone' {
            if (-not $s.UndoFromHistory) {
                $row = Get-AfRowById -Window $Window -Id $Item.Id
                if ($Item.Change.Status -eq 'Undone') {
                    if ($s.Applied) { $s.Applied.Remove($Item.Id) }
                    if ($row) { Reset-AfRow -Row $row -Motion $s.Motion | Out-Null }
                } elseif ($row) {
                    Set-AfRowStatus -Row $row -Status Failed -Message $Item.Change.Message -Motion $s.Motion
                }
                Update-AfProgressView -Window $Window -Motion $s.Motion
            }
        }
        'UndoFinished' { Complete-AfUndo -Window $Window }
        'Error' {
            Stop-AfDisplayCountdown -Window $Window
            Write-AfLog -Level Error -Message "Aplicar o deshacer falló: $($Item.Message)"
            $undoing = $s.Phase -eq 'undoing'
            if ($undoing -and $s.UndoFromHistory) { Show-AfHistory -Window $Window }
            elseif ($s.Applied -and @($s.Applied.Values).Count) { Set-AfDoneView -Window $Window }
            else { Set-AfReadyView -Window $Window }
            $text = if ($undoing) { (T 'No se pudo deshacer: {0}.') -f $Item.Message } else { (T 'No se pudo aplicar: {0}. Lo que no aparece como hecho no se cambió.') -f $Item.Message }
            Set-AfNote -Window $Window -Text $text -Icon 'warning-circle' -Motion $s.Motion
        }
    }
}

# Cambia solo la nota del pie, sin tocar los botones.
function Set-AfNote {
    param([Parameter(Mandatory)]$Window, [string]$Text, [string]$Icon = 'shield-check', [bool]$Motion = $false)
    Set-AfTextAnimated -Block $Window.FindName('NoteText') -Text $Text -Motion $Motion
    Set-AfIconData -Path $Window.FindName('NoteIcon') -Name $Icon
}

function Restart-AfComputer {
    Write-AfLog -Level Info -Message 'Reinicio pedido desde Afina.'
    Invoke-AfProcess -FilePath (Join-Path $env:SystemRoot 'System32\shutdown.exe') -Arguments '/r /t 0' -TimeoutMs 15000 | Out-Null
}

# Historial: sesiones guardadas en esta PC; se deshacen completas o cambio por cambio (diseño, sección 8, paso 7).

function Format-AfSessionDate {
    param([string]$Text)
    try { $date = [datetimeoffset]::Parse($Text, [System.Globalization.CultureInfo]::InvariantCulture).LocalDateTime } catch { return [string]$Text }
    if ((Get-AfLanguage) -eq 'en') { return '{0}, {1}' -f $date.ToString('MMM d, yyyy', (Get-AfCulture)), (Format-AfTime -Date $date) }
    $month = (Get-AfCulture).DateTimeFormat.GetAbbreviatedMonthName($date.Month).TrimEnd('.')
    '{0} {1} {2}, {3}' -f $date.Day, $month, $date.Year, (Format-AfTime -Date $date)
}

function Get-AfSessionStateText {
    param([Parameter(Mandatory)]$Session)
    $summary = Get-AfSessionSummary -Session $Session
    if ($summary.Applied + $summary.Undone -eq 0) { (T 'Sin cambios') }
    elseif ($summary.Applied -eq 0) { (T 'Deshecha') }
    elseif ($summary.Undone -gt 0) { (T 'Deshecha en parte') }
    else { (T 'Aplicada') }
}

function Get-AfChangeStateText {
    param([Parameter(Mandatory)]$Change)
    switch ($Change.Status) {
        'Applied' { if (Test-AfChangeUndoable -Change $Change) { (T 'Aplicado') } else { (T 'Aplicado, no se puede deshacer') } }
        'Undone' { (T 'Deshecho') }
        'UndoFailed' { (T 'No se pudo deshacer') }
        'Reverted' { (T 'Volvió al valor anterior') }
        default { (T 'No se pudo aplicar') }
    }
}

function New-AfUndoButton {
    param([string]$Text, [string]$SessionPath, [string[]]$Ids = @())
    $button = New-Object System.Windows.Controls.Button
    $button.SetResourceReference([System.Windows.FrameworkElement]::StyleProperty, 'SmallButton')
    $button.Content = $Text
    $button.Tag = [pscustomobject]@{ SessionPath = $SessionPath; Ids = @($Ids) }
    $button.Add_Click({
            param($sender, $e)
            Start-AfUndo -Window ([System.Windows.Window]::GetWindow($sender)) -SessionPath $sender.Tag.SessionPath -ChangeIds $sender.Tag.Ids -FromHistory
        })
    $button
}

# El título guardado si la sesión es del idioma actual; si no, el de la revisión en el idioma actual.
function Get-AfChangeTitle {
    param([Parameter(Mandatory)]$Change, $Session)
    if (-not $Session) { return [string]$Change.Title }
    # Las sesiones de antes de los idiomas no guardan Language: son en español.
    $language = if ($Session.Language) { $Session.Language } else { 'es' }
    if ($language -eq (Get-AfLanguage)) { return [string]$Change.Title }
    $check = @(Get-AfCatalog | Where-Object { $_.Id -eq $Change.CheckId })[0]
    if ($check) { [string]$check.Title } else { [string]$Change.Title }
}

function New-AfHistorySession {
    param([Parameter(Mandatory)]$Session)
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = 14
    $card.BorderThickness = 1
    $card.Padding = '18,14,18,8'
    $card.Margin = '0,0,0,14'
    $card.SetResourceReference([System.Windows.Controls.Border]::BackgroundProperty, 'Panel')
    $card.SetResourceReference([System.Windows.Controls.Border]::BorderBrushProperty, 'Line')
    $card.Tag = $Session.Path
    $stack = New-Object System.Windows.Controls.StackPanel
    $changes = @($Session.Changes)

    $header = New-Object System.Windows.Controls.DockPanel
    $header.Margin = '0,0,0,8'
    if (@($changes | Where-Object { Test-AfChangeUndoable -Change $_ }).Count) {
        $all = New-AfUndoButton -Text (T 'Deshacer todo') -SessionPath $Session.Path
        [System.Windows.Controls.DockPanel]::SetDock($all, 'Right')
        [void]$header.Children.Add($all)
    }
    $titles = New-Object System.Windows.Controls.StackPanel
    $date = New-AfText -Text (Format-AfSessionDate -Text $Session.StartedAt) -Size 14 -Brush 'Text' -Display -Weight 'Medium'
    [void]$titles.Children.Add($date)
    $count = if ($changes.Count -eq 1) { (T '1 cambio') } else { (T '{0} cambios') -f $changes.Count }
    $sub = New-AfText -Text ('{0} · {1}' -f $count, (Get-AfSessionStateText -Session $Session)) -Size 12 -Brush 'Text3'
    $sub.Margin = '0,2,0,0'
    [void]$titles.Children.Add($sub)
    [void]$header.Children.Add($titles)
    [void]$stack.Children.Add($header)

    foreach ($change in $changes) {
        $line = New-Object System.Windows.Controls.DockPanel
        $line.Margin = '0,6,0,6'
        if (Test-AfChangeUndoable -Change $change) {
            $action = New-AfUndoButton -Text (T 'Deshacer') -SessionPath $Session.Path -Ids @($change.CheckId)
            [System.Windows.Controls.DockPanel]::SetDock($action, 'Right')
            [void]$line.Children.Add($action)
        } else {
            $state = New-AfText -Text (Get-AfChangeStateText -Change $change) -Size 12 -Brush 'Text3'
            [System.Windows.Controls.DockPanel]::SetDock($state, 'Right')
            [void]$line.Children.Add($state)
        }
        $icon = switch ($change.Status) {
            'Applied' { New-AfIcon -Name 'check-circle' -Variant Fill -Size 15 -Brush 'Text' }
            'Undone' { New-AfIcon -Name 'arrow-counter-clockwise' -Size 15 }
            default { New-AfIcon -Name 'warning-circle' -Size 15 -Brush 'RedText' }
        }
        $icon.Margin = '0,0,12,0'
        [System.Windows.Controls.DockPanel]::SetDock($icon, 'Left')
        [void]$line.Children.Add($icon)
        $title = New-AfText -Text (Get-AfChangeTitle -Change $change -Session $Session) -Size 12.5 -Brush 'Text2'
        $title.TextTrimming = 'CharacterEllipsis'
        $title.TextWrapping = 'NoWrap'
        if ($change.Message) { $title.ToolTip = $change.Message }
        [void]$line.Children.Add($title)
        [void]$stack.Children.Add($line)
    }
    $card.Child = $stack
    $card
}

function Show-AfHistory {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    if ($s.Phase -ne 'history' -and $s.Phase -ne 'undoing') { $s.PhaseBeforeHistory = $s.Phase }
    $s.Phase = 'history'
    $Window.FindName('Title').Text = (T 'Historial')
    $Window.FindName('GaugeArea').Visibility = 'Collapsed'
    $Window.FindName('PanelBorder').Visibility = 'Collapsed'
    $Window.FindName('HistoryPanel').Visibility = 'Visible'
    $Window.FindName('Summary').Inlines.Clear()
    $Window.FindName('Summary').Text = (T 'Cada sesión guarda los valores originales. Se puede deshacer completa o cambio por cambio.')
    $list = $Window.FindName('HistoryList')
    $list.IsHitTestVisible = $true
    $list.Children.Clear()
    $sessions = @(Get-AfSessions -Directory $s.BackupDirectory)
    if (-not $sessions.Count) {
        $empty = New-AfText -Text (T 'Todavía no se aplicaron cambios en esta PC.') -Size 13 -Brush 'Text2'
        $empty.Margin = '2,4,0,0'
        [void]$list.Children.Add($empty)
    }
    foreach ($session in $sessions) { [void]$list.Children.Add((New-AfHistorySession -Session $session)) }
    $Window.FindName('ListScroll').ScrollToTop()
    $Window.FindName('Actions').Opacity = 1
    $Window.FindName('Actions').IsHitTestVisible = $true
    Set-AfFooter -Window $Window -Note (T 'Los respaldos quedan en ProgramData\Afina\respaldos.') -NoteIcon 'clock-counter-clockwise' -Ghost (T 'Volver') -Motion ([bool]$s.Motion)
}

function Hide-AfHistory {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $Window.FindName('HistoryPanel').Visibility = 'Collapsed'
    $Window.FindName('GaugeArea').Visibility = 'Visible'
    if ($Window.FindName('Groups').Children.Count) { $Window.FindName('PanelBorder').Visibility = 'Visible' }
    if ($s.NeedsRescan -or -not $s.Results -or -not @($s.Results).Count) {
        $s.NeedsRescan = $false
        Start-AfScan -Window $Window
        return
    }
    if ($s.PhaseBeforeHistory -eq 'done') { Set-AfDoneView -Window $Window } else { Set-AfReadyView -Window $Window }
}

# El análisis corre en un runspace aparte y solo encola eventos; la ventana los lee con un DispatcherTimer.
function Start-AfScanWorker {
    param([Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)]$Queue, [ValidateSet('es', 'en')][string]$Language = 'es')
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('AfQueue', $Queue)
    $runspace.SessionStateProxy.SetVariable('AfCodeText', $Code)
    $runspace.SessionStateProxy.SetVariable('AfLanguageName', $Language)
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
            try {
                . ([scriptblock]::Create($AfCodeText))
                # Los textos del catálogo y de las detecciones salen en el idioma de la ventana.
                Set-AfLanguage -Language $AfLanguageName
                $catalog = @(Get-AfCatalog)
                $inventory = Get-AfInventory -Reads (Get-AfCatalogReads -Catalog $catalog) -OnProgress { param($part) $AfQueue.Enqueue([pscustomobject]@{ Type = 'Part'; Part = $part }) }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Inventory'; Inventory = $inventory })
                foreach ($category in Get-AfCategories) {
                    $results = @($catalog | Where-Object { $_.Category -eq $category.Id } | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inventory })
                    $AfQueue.Enqueue([pscustomobject]@{ Type = 'Category'; Category = $category.Id; Results = $results })
                }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Done' })
                foreach ($check in @($catalog | Where-Object { $_.Async })) {
                    try { $detection = & $check.AsyncDetect $inventory } catch { $detection = New-AfDetection -State Error -Note $_.Exception.Message }
                    $AfQueue.Enqueue([pscustomobject]@{ Type = 'Async'; Id = $check.Id; Detection = $detection })
                }
            } catch {
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Error'; Message = $_.Exception.Message })
            }
        })
    $handle = $ps.BeginInvoke()
    [pscustomobject]@{ PowerShell = $ps; Runspace = $runspace; Handle = $handle }
}

# Aplicar y deshacer también corren aparte: recargan el código y buscan las revisiones por Id (sin pasar scriptblocks entre hilos).
function Start-AfApplyWorker {
    param([Parameter(Mandatory)][string]$Code, [Parameter(Mandatory)]$Queue, [Parameter(Mandatory)]$Shared, [Parameter(Mandatory)]$Plan)
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable('AfQueue', $Queue)
    $runspace.SessionStateProxy.SetVariable('AfShared', $Shared)
    $runspace.SessionStateProxy.SetVariable('AfPlan', $Plan)
    $runspace.SessionStateProxy.SetVariable('AfCodeText', $Code)
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript({
            try {
                . ([scriptblock]::Create($AfCodeText))
                if ($AfPlan.LogPath) { Set-AfLogPath -Path $AfPlan.LogPath }
                if ($AfPlan.Mode -eq 'Undo') { Invoke-AfUndoPlan -Plan $AfPlan -Queue $AfQueue }
                else { Invoke-AfApplyPlan -Plan $AfPlan -Queue $AfQueue -Shared $AfShared }
            } catch {
                $reason = (T 'Windows no aceptó el cambio')
                try { $reason = Get-AfApplyReason -ErrorRecord $_; Write-AfLog -Level Error -Message "Trabajo de aplicar: $($_.Exception.Message)" } catch { }
                $AfQueue.Enqueue([pscustomobject]@{ Type = 'Error'; Message = $reason })
            }
        })
    $handle = $ps.BeginInvoke()
    [pscustomobject]@{ PowerShell = $ps; Runspace = $runspace; Handle = $handle }
}

function Stop-AfScanWorker {
    param($Worker)
    if (-not $Worker) { return }
    try { [void]$Worker.PowerShell.BeginStop($null, $null) } catch { }
}

function Get-AfPartPhrase {
    param([string]$Part)
    switch ($Part) {
        'Memory' { (T 'Revisando las pantallas…') }
        { $_ -in 'Displays', 'Power' } { (T 'Revisando la energía…') }
        { $_ -in 'VendorTools', 'Network' } { (T 'Revisando la red…') }
        'Wlan' { (T 'Revisando la seguridad…') }
        { $_ -in 'Security', 'Apps', 'Startup' } { (T 'Revisando lo que arranca con Windows…') }
        'Autostart' { (T 'Revisando el almacenamiento…') }
        'Storage' { (T 'Revisando la configuración de Windows…') }
        'Registry' { (T 'Comparando con lo recomendado…') }
        default { (T 'Revisando el hardware…') }
    }
}

function Set-AfActionsVisible {
    param([Parameter(Mandatory)]$Window, [bool]$Visible, [bool]$Motion = $false)
    $actions = $Window.FindName('Actions')
    $actions.IsHitTestVisible = $Visible
    Start-AfAnimation -Target $actions -Property ([System.Windows.UIElement]::OpacityProperty) -To $(if ($Visible) { 1 } else { 0 }) -DurationMs 300 -Ease Out -Enabled $Motion | Out-Null
}

function Start-AfScan {
    param([Parameter(Mandatory)]$Window)
    $s = Get-AfUiState -Window $Window
    Stop-AfScanWorker -Worker $s.Worker
    $s.Phase = 'scanning'
    $s.ScanDone = $false
    $s.Applied = @{}
    $s.RebootPending = $false
    $s.NeedsRescan = $false
    $Window.FindName('HistoryPanel').Visibility = 'Collapsed'
    $Window.FindName('GaugeArea').Visibility = 'Visible'
    $Window.FindName('Groups').IsHitTestVisible = $true
    $Window.FindName('PrimaryProgressScale').BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $null)
    $Window.FindName('PrimaryProgressScale').ScaleX = 0
    $s.Pending = New-Object System.Collections.Queue
    $s.LastReveal = [datetime]::MinValue
    $s.Results = New-Object System.Collections.ArrayList
    $s.Filter = 'all'
    $s.StartedAt = Get-Date
    Set-AfNavActive -Window $Window -Filter 'all' -Motion $false
    $Window.FindName('Groups').Children.Clear()
    $Window.FindName('PanelBorder').Visibility = 'Collapsed'
    $Window.FindName('Title').Text = (T 'Analizando esta PC')
    Set-AfTextAnimated -Block $Window.FindName('Summary') -Text (T 'Revisando el hardware…') -Motion $s.Motion
    Set-AfActionsVisible -Window $Window -Visible $false
    Set-AfNavSpinners -Window $Window
    $s.TicksHidden = $true
    Update-AfGaugeLayout -Window $Window
    foreach ($tick in $Window.FindName('Ticks').Children) { $tick.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null); $tick.Opacity = 0 }
    Show-AfTicks -Window $Window -Motion $s.Motion
    $needle = $Window.FindName('Needle')
    $needle.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $needle.Opacity = 1
    Start-AfNeedleSweep -Window $Window -Motion $s.Motion
    # Tras el autotest, la aguja queda atenuada mientras se analiza.
    Start-AfAnimation -Target $needle -Property ([System.Windows.UIElement]::OpacityProperty) -To 0.4 -DurationMs 300 -DelayMs $(if ($s.Motion) { 1500 } else { 0 }) -Ease Out -Enabled $true | Out-Null
    $s.Queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $s.Worker = Start-AfScanWorker -Code $Global:AfCode -Queue $s.Queue -Language (Get-AfLanguage)
}

function Update-AfAsyncResult {
    param([Parameter(Mandatory)]$Window, [string]$Id, $Detection)
    foreach ($group in $Window.FindName('Groups').Children) {
        for ($i = 0; $i -lt $group.Children.Count; $i++) {
            $row = $group.Children[$i]
            if ($row -isnot [System.Windows.Controls.Border] -or -not $row.Tag -or -not $row.Tag.Check -or $row.Tag.Check.Id -ne $Id) { continue }
            $old = $row.Tag
            $result = [pscustomobject]@{ Check = $old.Check; Detection = $Detection; Weight = $old.Weight; Preselected = $false }
            $index = $Window.Tag.Results.IndexOf($old)
            if ($index -ge 0) { $Window.Tag.Results[$index] = $result }
            if ($Detection.State -notin 'Improvable', 'Manual', 'Info', 'Error') {
                $group.Children.RemoveAt($i)
            } else {
                $newRow = New-AfRowElement -Result $result -First:($row.FindName('Divider').Visibility -ne 'Visible')
                Add-AfRowHandlers -Row $newRow
                $group.Children.RemoveAt($i)
                $group.Children.Insert($i, $newRow)
                Start-AfAnimation -Target $newRow -Property ([System.Windows.UIElement]::OpacityProperty) -From 0 -To 1 -DurationMs 300 -Ease Out -Enabled ([bool]$Window.Tag.Motion) | Out-Null
            }
            Update-AfNavCounts -Window $Window -Results @($Window.Tag.Results) -Only @('optional')
            Update-AfPrimary -Window $Window
            return
        }
    }
}

function Complete-AfScan {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $s.Phase = 'ready'
    $results = @($s.Results)
    Add-AfOkGroup -Window $Window -Results $results -Motion $s.Motion
    Update-AfNavCounts -Window $Window -Results $results -Only @('ok') -Motion $s.Motion
    $summary = Get-AfSummary -Results $results
    $score = Get-AfScore -Results $results
    Set-AfTextAnimated -Block $Window.FindName('Title') -Text $(if ($summary.Ready -eq 0 -and $score -ge 0.999) { (T 'Afinada') } else { (T 'Afinación') }) -Motion $s.Motion
    Set-AfSummary -Window $Window -Summary $summary -Motion $s.Motion
    $needle = $Window.FindName('Needle')
    Start-AfAnimation -Target $needle -Property ([System.Windows.UIElement]::OpacityProperty) -To 1 -DurationMs 200 -Ease Out -Enabled $s.Motion | Out-Null
    Set-AfNeedle -Window $Window -Fraction $score -Motion $s.Motion -DurationMs 700 -Ease Out
    if ($score -ge 0.999) { Start-AfCelebration -Window $Window -Motion $s.Motion }
    Set-AfFooter -Window $Window -Note (Get-AfReadyNote) -NoteIcon 'shield-check' -Ghost (T 'Volver a analizar') -GhostIcon 'arrow-clockwise' -PrimaryOptimize
    Set-AfActionsVisible -Window $Window -Visible $true -Motion $s.Motion
    Write-AfLog -Level Info -Message ('Análisis terminado en {0:N1} s: {1} listos, {2} a mano, {3} en orden.' -f ((Get-Date) - $s.StartedAt).TotalSeconds, $summary.Ready, $summary.Manual, $summary.Ok)
    if ($s.Snapshot) {
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromMilliseconds(1200)
        $timer.Tag = $Window
        $timer.Add_Tick({ param($sender, $e) $sender.Stop(); $w = $sender.Tag; Save-AfWindowSnapshot -Window $w -Path $w.Tag.Snapshot; $w.Close() })
        $timer.Start()
    }
}

function Receive-AfEvents {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $item = $null
    if ($s.ApplyQueue) {
        while ($s.ApplyQueue.TryDequeue([ref]$item)) { Receive-AfApplyEvent -Window $Window -Item $item }
    }
    if (-not $s.Queue) { return }
    while ($s.Queue.TryDequeue([ref]$item)) {
        switch ($item.Type) {
            'Part' { if ($s.Phase -eq 'scanning') { $Window.FindName('Summary').Text = Get-AfPartPhrase -Part $item.Part } }
            'Inventory' { $s.Inventory = $item.Inventory; Set-AfPcCard -Window $Window -Inventory $item.Inventory -Animate $s.Motion }
            'Category' { $s.Pending.Enqueue($item) }
            'Done' { $s.ScanDone = $true }
            'Async' { Update-AfAsyncResult -Window $Window -Id $item.Id -Detection $item.Detection }
            'Error' {
                $s.ScanDone = $true
                Write-AfLog -Level Error -Message "El análisis falló: $($item.Message)"
                $Window.FindName('Summary').Text = (T 'El análisis no pudo terminar. Revisa el registro en ProgramData\Afina.')
            }
        }
    }
    if ($s.Pending.Count -gt 0) {
        $gap = if ($s.Motion) { 260 } else { 0 }
        if (((Get-Date) - $s.LastReveal).TotalMilliseconds -ge $gap) {
            $next = $s.Pending.Dequeue()
            foreach ($result in $next.Results) { [void]$s.Results.Add($result) }
            $category = Get-AfCategories | Where-Object Id -eq $next.Category
            Add-AfCategoryGroup -Window $Window -Category $category -Results $next.Results -Motion $s.Motion
            Update-AfNavCounts -Window $Window -Results @($s.Results) -Only @($next.Category) -Motion $s.Motion
            $s.LastReveal = Get-Date
        }
    } elseif ($s.ScanDone -and $s.Phase -eq 'scanning') {
        Complete-AfScan -Window $Window
    }
}

function Initialize-AfPrefs {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    $map = @{ ThemeSystem = 'System'; ThemeBlack = 'Black'; ThemeWhite = 'White'; MotionAuto = 'Auto'; MotionAlways = 'Always'; MotionNever = 'Never'; LangAuto = 'Auto'; LangEs = 'es'; LangEn = 'en' }
    # Un idioma guardado que no se conoce cuenta como Automático.
    $language = if ($s.Config.Language -in 'es', 'en') { $s.Config.Language } else { 'Auto' }
    foreach ($name in $map.Keys) {
        $radio = $Window.FindName($name)
        $radio.IsChecked = switch -Wildcard ($name) {
            'Theme*' { $s.Config.Theme -eq $map[$name] }
            'Motion*' { $s.Config.Motion -eq $map[$name] }
            default { $language -eq $map[$name] }
        }
        $radio.Tag = $map[$name]
        $radio.Add_Checked({
                param($sender, $e)
                $w = [System.Windows.Window]::GetWindow($sender)
                $state = $w.Tag
                if ($sender.GroupName -eq 'Theme') {
                    $state.Config.Theme = $sender.Tag
                    Set-AfTheme -Window $w -Theme (Resolve-AfTheme -Setting $sender.Tag -User $state.User)
                } elseif ($sender.GroupName -eq 'Motion') {
                    $state.Config.Motion = $sender.Tag
                    $state.Motion = Test-AfMotionEnabled -Setting $sender.Tag
                } else {
                    $state.Config.Language = $sender.Tag
                    $chosen = Resolve-AfLanguage -Setting $sender.Tag
                    # Todo se vuelve a armar en el idioma nuevo: los textos fijos ahora y los resultados con un análisis nuevo.
                    if ($chosen -ne (Get-AfLanguage)) {
                        Set-AfLanguage -Language $chosen
                        Set-AfStaticTexts -Window $w
                        if ($state.Nav) { foreach ($entry in Get-AfNavEntries) { if ($state.Nav[$entry.Id]) { $state.Nav[$entry.Id].Label.Text = $entry.Name } } }
                        if ($state.Phase -in 'ready', 'done', 'history') { Start-AfScan -Window $w }
                    }
                }
                if ($state.ConfigPath) { try { Set-AfConfig -Path $state.ConfigPath -Config $state.Config } catch { Write-AfLog -Level Warn -Message "No se pudo guardar la configuración: $($_.Exception.Message)" } }
            })
    }
}

# Mientras analiza, confirma, aplica o deshace no se cambia de idioma: lo que está en pantalla tiene que seguir siendo de ese proceso.
function Update-AfLanguageAvailability {
    param([Parameter(Mandatory)]$Window)
    $busy = $Window.Tag.Phase -in 'scanning', 'confirm', 'applying', 'display', 'restore', 'undoing'
    foreach ($name in 'LangAuto', 'LangEs', 'LangEn') {
        $radio = $Window.FindName($name)
        $radio.IsEnabled = -not $busy
        [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($radio, $true)
        $radio.ToolTip = if ($busy) { T 'Disponible al terminar' } else { $null }
    }
}

function Test-AfBusyPhase {
    param([string]$Phase)
    $Phase -in 'applying', 'display', 'restore', 'undoing'
}

function Invoke-AfPrimaryAction {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    switch ($s.Phase) {
        'ready' { Enter-AfConfirm -Window $Window }
        'confirm' { Start-AfApply -Window $Window }
        'display' { $s.Shared.DisplayAnswer = 'keep'; $s.Phase = 'applying'; Stop-AfDisplayCountdown -Window $Window; Set-AfApplyingFooter -Window $Window }
        'restore' { $s.Shared.ContinueWithoutRestore = $true; $s.Phase = 'applying'; $s.ApplyNote = (T 'Sin punto de restauración; los valores originales se guardan en Afina.'); Set-AfApplyingFooter -Window $Window }
        'done' {
            if (-not $s.RebootPending) { Start-AfScan -Window $Window }
            elseif ($s.DemoCode) { Set-AfNote -Window $Window -Text (T 'En la demostración no se reinicia la PC.') -Icon 'info' -Motion $s.Motion }
            else { Restart-AfComputer }
        }
    }
}

function Invoke-AfGhostAction {
    param([Parameter(Mandatory)]$Window)
    $s = $Window.Tag
    switch ($s.Phase) {
        'ready' { Start-AfScan -Window $Window }
        'confirm' { Exit-AfConfirm -Window $Window }
        'display' { $s.Shared.DisplayAnswer = 'revert'; $s.Phase = 'applying'; Stop-AfDisplayCountdown -Window $Window; Set-AfApplyingFooter -Window $Window }
        'restore' { $s.Shared.ContinueWithoutRestore = $false; $s.Phase = 'applying'; Set-AfApplyingFooter -Window $Window }
        'done' { $s.RebootPending = $false; Set-AfDoneView -Window $Window }
        'history' { Hide-AfHistory -Window $Window }
    }
}

function Show-AfApp {
    # OnShown es para automatizar (tools\Show-AfDemo.ps1 -AutoPlay): recibe la ventana, que abre fuera de la pantalla.
    param([hashtable]$Config = (Get-AfConfigDefaults), [string]$ConfigPath, [string]$Snapshot, [string]$BackupDirectory = (Get-AfBackupDirectory), [string]$DemoCode, [scriptblock]$OnShown)
    $user = Get-AfInteractiveUser
    Set-AfStartLanguage -Config $Config
    $window = New-AfWindow -Theme (Resolve-AfTheme -Setting $Config.Theme -User $user)
    $s = Get-AfUiState -Window $window
    $s.Motion = Test-AfMotionEnabled -Setting $Config.Motion
    $s.Config = $Config
    $s.ConfigPath = $ConfigPath
    $s.Snapshot = $Snapshot
    $s.User = $user
    $s.BackupDirectory = $BackupDirectory
    $s.DemoCode = $DemoCode
    if ($DemoCode) { $window.FindName('Version').Text += '  ·  ' + (T 'Demostración') }

    $area = [System.Windows.SystemParameters]::WorkArea
    if ($area.Width -lt $window.Width) { $window.Width = [math]::Max($window.MinWidth, $area.Width) }
    if ($area.Height -lt $window.Height) { $window.Height = [math]::Max($window.MinHeight, $area.Height) }
    $s.OnShown = $OnShown
    if ($Snapshot -or $OnShown) {
        $window.WindowStartupLocation = 'Manual'
        $window.Left = -20000
        $window.Top = -20000
        $window.ShowActivated = $false
    }

    $window.FindName('MinButton').Add_Click({ param($sender, $e) [System.Windows.Window]::GetWindow($sender).WindowState = 'Minimized' })
    $window.FindName('MaxButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $w.WindowState = if ($w.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
        })
    $window.Add_StateChanged({ param($sender, $e) $sender.FindName('MaxButton').Content = if ($sender.WindowState -eq 'Maximized') { [string][char]0xE923 } else { [string][char]0xE922 } })
    $window.FindName('CloseButton').Add_Click({ param($sender, $e) [System.Windows.Window]::GetWindow($sender).Close() })
    $prefs = $window.FindName('Prefs')
    $prefs.PlacementTarget = $window.FindName('PrefsButton')
    $window.FindName('PrefsButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            Update-AfLanguageAvailability -Window $w
            $w.FindName('Prefs').IsOpen = $true
        })
    Initialize-AfPrefs -Window $window
    $window.FindName('GhostButton').Add_Click({ param($sender, $e) Invoke-AfGhostAction -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window.FindName('PrimaryButton').Add_Click({ param($sender, $e) Invoke-AfPrimaryAction -Window ([System.Windows.Window]::GetWindow($sender)) })
    $window.FindName('ExtraButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -eq 'done' -and $w.Tag.SessionPath) { Start-AfUndo -Window $w -SessionPath $w.Tag.SessionPath }
        })
    $window.FindName('HistoryButton').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -in 'ready', 'done') { Show-AfHistory -Window $w }
        })
    $window.FindName('RestoreOption').Add_Click({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            if ($w.Tag.Phase -eq 'confirm') { Set-AfNote -Window $w -Text (Get-AfConfirmNote -Window $w) -Motion ([bool]$w.Tag.Motion) }
        })
    $window.FindName('RestoreLabel').Add_MouseLeftButtonUp({ param($sender, $e)
            $w = [System.Windows.Window]::GetWindow($sender)
            $option = $w.FindName('RestoreOption')
            $option.IsChecked = -not $option.IsChecked
            if ($w.Tag.Phase -eq 'confirm') { Set-AfNote -Window $w -Text (Get-AfConfirmNote -Window $w) -Motion ([bool]$w.Tag.Motion) }
        })
    # Nunca se cierra con cambios a medio aplicar o deshacer.
    $window.Add_Closing({ param($sender, $e)
            if (Test-AfBusyPhase -Phase $sender.Tag.Phase) {
                $e.Cancel = $true
                Set-AfNote -Window $sender -Text (T 'Espera a que termine: hay cambios a medio aplicar.') -Icon 'warning-circle'
            }
        })

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)
    $timer.Tag = $window
    $timer.Add_Tick({ param($sender, $e) Receive-AfEvents -Window $sender.Tag })
    $s.Timer = $timer
    $window.Add_ContentRendered({ param($sender, $e)
            Start-AfScan -Window $sender
            if ($sender.Tag.OnShown) { & $sender.Tag.OnShown $sender }
        })
    $window.Add_Closed({ param($sender, $e) $sender.Tag.Timer.Stop(); Stop-AfScanWorker -Worker $sender.Tag.Worker })
    $timer.Start()
    [void]$window.ShowDialog()
}

}
$Global:AfCode = $Global:AfCodeBlock.ToString()
. $Global:AfCodeBlock

$scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $null }
$configPath = Get-AfConfigPath -ScriptRoot $(if ($scriptPath) { Split-Path $scriptPath -Parent } else { $null })
$config = Get-AfConfig -Path $configPath
# Los avisos de la consola, -Scan y la ventana salen en el idioma guardado.
Set-AfStartLanguage -Config $config

$extra = @()
if ($Scan) { $extra += '-Scan' }
if ($Json) { $extra += '-Json' }
if ($Snapshot) { $extra += @('-Snapshot', ('"{0}"' -f $Snapshot)) }
$needsSta = [System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA' -and -not $Scan
if ((-not $NoElevate -and -not (Test-AfAdmin)) -or $needsSta) {
    # Abierto con "irm … | iex" no se relanza: un PowerShell elevado que descarga y ejecuta código es lo que Defender bloquea como malware.
    if (-not $scriptPath) {
        Write-Host (T 'Afina necesita permisos de administrador. Abre PowerShell como administrador (clic derecho en Inicio) y vuelve a pegar la línea.')
        return
    }
    Restart-AfElevated -Arguments (@('-STA') + (Get-AfRelaunchArguments -ScriptPath $scriptPath -Extra $extra))
    exit
}

[void](Start-AfLog -Directory (Join-Path $env:ProgramData 'Afina\registros'))
Write-AfLog -Level Info -Message ('Afina {0} en {1}' -f (Get-AfVersion), $env:COMPUTERNAME)

if ($Scan) {
    $catalog = @(Get-AfCatalog)
    $inventory = Get-AfInventory -Reads (Get-AfCatalogReads -Catalog $catalog)
    $results = @($catalog | ForEach-Object { Invoke-AfCheck -Check $_ -Inventory $inventory })
    $rows = @($results | ForEach-Object {
            [pscustomobject]@{
                Id = $_.Check.Id
                Category = $_.Check.Category
                State = $_.Detection.State
                Title = if ($_.Detection.Title) { $_.Detection.Title } else { $_.Check.Title }
                Current = $_.Detection.Current
                Target = $_.Detection.Target
                Note = $_.Detection.Note
                Preselected = $_.Preselected
            }
        })
    if ($Json) {
        [pscustomobject]@{ Version = Get-AfVersion; Score = Get-AfScore -Results $results; Summary = Get-AfSummary -Results $results; InventoryErrors = $inventory.Errors; Results = $rows } | ConvertTo-Json -Depth 5
    } else {
        $rows | Format-Table State, Id, Title, Current, Target -AutoSize
    }
    exit 0
}

Show-AfApp -Config $config -ConfigPath $configPath -Snapshot $Snapshot
# Sale en el acto: la búsqueda de Windows Update en segundo plano puede tardar minutos y no se puede cortar.
[Environment]::Exit(0)
