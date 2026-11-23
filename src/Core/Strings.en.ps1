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
Revisa el disco==>Check the disk
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
Ajustes de Windows==>Windows settings
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
Diagnóstico==>Diagnostics
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
Guardando el valor original==>Saving the original value
Aplicando==>Applying
Guardando el respaldo==>Saving the backup
Restaurando el valor original==>Restoring the original value
Optimizando==>Optimizing
{0} de {1}==>{0} of {1}
Seguir el avance==>Follow progress
Activando Restaurar sistema…==>Turning on System Restore…
{0} en orden==>{0} all good
Se revisaron {0} puntos y no hay nada para cambiar.==>{0} checks reviewed, nothing to change.
Se revisó 1 punto y no hay nada para cambiar.==>1 check reviewed, nothing to change.
No aplica==>Doesn't apply
Esta PC está afinada==>This PC is tuned up
{0} revisados==>{0} checked
Todavía no hay cambios en esta PC==>No changes on this PC yet
Laptop gamer==>Gaming laptop
Escritorio gamer==>Gaming desktop
, doble canal==>, dual channel
Cada vez que optimizas, Afina guarda aquí los valores originales para deshacerlos cuando quieras.==>Every time you optimize, Afina saves the original values here so you can undo them whenever you want.
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
Windows no dejó leer ese ajuste==>Windows wouldn't let it read that setting
Windows no aceptó el ajuste==>Windows didn't accept the setting
abre Afina con la cuenta del dueño para este ajuste==>open Afina with the owner's account for this setting
abre Afina con la cuenta del dueño para deshacerlo==>open Afina with the owner's account to undo it
Windows no aceptó el modo de Optimización de entrega==>Windows didn't accept the Delivery Optimization mode
una directiva fija el modo de Optimización de entrega; quítala para deshacerlo==>a policy sets the Delivery Optimization mode; remove it to undo this
Windows no activó el archivo de paginación automático==>Windows didn't turn on the automatic page file
la hibernación está desactivada==>hibernation is turned off
la hibernación tiene un tamaño personalizado==>hibernation has a custom size
Windows no aceptó el tipo de hibernación==>Windows didn't accept the hibernation type
falta espacio en el disco para volver a la hibernación completa==>not enough disk space to go back to full hibernation
Escrito, comprueba que se vea el cambio==>Written, check that the change shows
Windows tiene un modo de Optimización de entrega que Afina no sabe volver a poner==>Windows uses a Delivery Optimization mode that Afina can't set back
Windows no desactivó el archivo de paginación automático==>Windows didn't turn off the automatic page file
{0}: Windows lo marca en mal estado==>{0}: Windows marks it as unhealthy
{0}: Windows lo marca con advertencia==>{0}: Windows marks it with a warning
{0}: Windows reporta un problema de salud==>{0}: Windows reports a health problem
{0}: desgaste {1} %==>{0}: wear {1} %
{0}: errores sin corregir ({1})==>{0}: uncorrected errors ({1})
{0}: temperatura en su máximo ({1} °C)==>{0}: temperature at its maximum ({1} °C)
Buena, sin datos de desgaste==>Good, no wear data
Buena, desgaste {0} %==>Good, {0} % wear
Sin datos de desgaste==>No wear data
Windows predice una falla de disco==>Windows predicts a disk failure
Respalda tus archivos ya.==>Back up your files now.
Cambia el disco cuanto antes.==>Replace the disk as soon as possible.
Mantén un respaldo al día y vigila el disco.==>Keep a backup up to date and watch the disk.
Conserva el {0} % de su capacidad==>Holds {0} % of its capacity
{0} ciclos de carga==>{0} charge cycles
La batería ya dura menos que cuando era nueva.==>The battery now lasts less than when it was new.
La batería está muy gastada: conviene cambiarla.==>The battery is very worn: it's worth replacing.
Mientras tanto, usa la laptop con el cargador conectado.==>Meanwhile, use the laptop plugged in.
Sin datos recientes==>No recent data
Último arranque medido: {0}==>Last boot measured: {0}
{0} s hasta el escritorio==>{0} s to the desktop
Revisa los programas de la categoría Inicio: son lo que más alarga el arranque.==>Check the programs in the Startup category: they add the most to boot time.
Salud del disco==>Disk health
Un disco con desgaste alto o fallas puede dejar de funcionar sin aviso y llevarse tus archivos.==>A disk with high wear or faults can stop working without warning and take your files with it.
Contadores de confiabilidad del almacenamiento de Windows==>Windows storage reliability counters
No cambia nada==>Changes nothing
Revisando…==>Checking…
Salud de la batería==>Battery health
Una batería gastada dura menos y puede limitar el rendimiento de la laptop.==>A worn battery lasts less and can limit the laptop's performance.
Capacidad de diseño y de carga completa de la batería==>Battery design and full-charge capacity
Tiempo de arranque==>Boot time
Un arranque largo suele venir de programas que se abren con Windows.==>A long boot usually comes from programs that open with Windows.
Registro de rendimiento del arranque de Windows==>Windows boot performance log
Archivo de paginación==>Page file
Si el archivo de paginación está apagado o es muy chico, los juegos y apps pesadas pueden cerrarse por falta de memoria.==>If the page file is off or too small, games and heavy apps can close from lack of memory.
Configuración del archivo de paginación de Windows==>Windows page file settings
Vuelve a la configuración anterior==>Goes back to the previous setting
Automático==>Automatic
Lo maneja Windows==>Managed by Windows
{0} MB fijos==>{0} MB fixed
Apagado==>Off
Libera espacio primero: hacen falta al menos 4 GB libres.==>Free up space first: at least 4 GB must be free.
Deja que Windows maneje el archivo de paginación. Pide reiniciar.==>Lets Windows manage the page file. Needs a restart.
# Optimizaciones de rendimiento
El código nativo no está disponible==>Native code is not available
Edge sigue activo en segundo plano==>Edge keeps running in the background
Edge se queda en memoria aunque cierres todas sus ventanas, y arranca con Windows para abrir más rápido.==>Edge stays in memory even after you close all its windows, and starts with Windows to open faster.
Microsoft: Aumento de inicio de Edge==>Microsoft: Edge startup boost
Lo fija una directiva==>Set by a policy
Cierra Edge para revisarlo==>Close Edge to check it
Cerrado==>Closed
Edge corre sin ventanas==>Edge is running with no windows
Abre Edge y entra a edge://settings/system.==>Open Edge and go to edge://settings/system.
Apaga "Aumento de inicio".==>Turn off "Startup boost".
Apaga "Seguir ejecutando extensiones y aplicaciones en segundo plano".==>Turn off "Continue running background extensions and apps when Microsoft Edge is closed".
Optimización de entrega solo en la red local==>Delivery Optimization on the local network only
En modo Internet, Windows sube partes de sus actualizaciones a otros equipos y gasta tu conexión.==>In Internet mode, Windows uploads parts of its updates to other PCs and uses your connection.
Microsoft: Optimización de entrega==>Microsoft: Delivery Optimization
Solo red local o sin compartir==>Local network only or not sharing
Internet==>Internet
Red local==>Local network
El modo de descarga pasa de Internet a Red local. Se puede cambiar en Configuración, Windows Update, Opciones avanzadas.==>The download mode changes from Internet to Local network. It can be changed in Settings, Windows Update, Advanced options.
Aceleración del mouse apagada==>Mouse acceleration off
"Mejorar la precisión del puntero" mueve el cursor según la velocidad del mouse, y apuntar se vuelve menos predecible en los juegos.==>"Enhance pointer precision" moves the cursor based on how fast the mouse moves, so aiming becomes less predictable in games.
Microsoft: opciones del puntero del mouse==>Microsoft: mouse pointer options
Cambia cómo se siente el mouse==>Changes how the mouse feels
Se apaga "Mejorar la precisión del puntero". La velocidad del puntero no cambia.==>"Enhance pointer precision" is turned off. Pointer speed does not change.
Menos efectos visuales en esta PC==>Fewer visual effects on this PC
Con poca memoria o con disco HDD, las animaciones y la transparencia le quitan fluidez a Windows.==>With little memory or an HDD, animations and transparency make Windows feel less smooth.
Microsoft: efectos visuales de Windows==>Microsoft: Windows visual effects
Activos==>On
Apagados==>Off
Se apagan "Efectos de animación" y "Efectos de transparencia" de Accesibilidad. El suavizado de fuentes se queda como está.==>"Animation effects" and "Transparency effects" in Accessibility are turned off. Font smoothing stays as it is.
Archivo de hibernación más chico==>Smaller hibernation file
Con poco espacio libre, hiberfil.sys ocupa cerca de la mitad de la memoria RAM en el disco.==>With little free space, hiberfil.sys takes about half of the RAM size on disk.
Microsoft: powercfg y la hibernación==>Microsoft: powercfg and hibernation
En laptops no se reduce: sin hibernación completa, el trabajo sin guardar puede perderse al agotarse la batería==>Not reduced on laptops: without full hibernation, unsaved work can be lost when the battery runs out
Completo, {0}==>Full, {0}
Reducido==>Reduced
Si se va la luz mientras duerme, se pierde lo no guardado==>If the power goes out while it sleeps, unsaved work is lost
El archivo baja de 40 % a 20 % de la RAM, cerca de la mitad. Se conserva el inicio rápido; se pierden hibernar y el sueño híbrido.==>The file goes from 40 % to 20 % of RAM, about half. Fast startup is kept; hibernate and hybrid sleep are lost.
Sensor de almacenamiento activado==>Storage Sense on
Borra temporales solo cuando queda poco espacio, para que Windows no se quede sin lugar para actualizarse.==>Deletes temporary files only when space is low, so Windows does not run out of room to update.
Microsoft: Sensor de almacenamiento==>Microsoft: Storage Sense
Recall apagado==>Recall off
Borra las capturas guardadas de Recall y no se recuperan.==>Deletes the saved Recall snapshots and they can't be recovered.
Recall guarda capturas de lo que haces en pantalla para poder buscarlas después.==>Recall saves snapshots of what you do on screen so you can search them later.
Microsoft: administrar Recall==>Microsoft: manage Recall
Se deshace el ajuste; las capturas borradas no vuelven==>The setting is undone; deleted snapshots don't come back
Comprobando Recall…==>Checking Recall…
No se pudo leer el estado de Recall==>Couldn't read the Recall state
Activo==>On
Abre Configuración > Privacidad y seguridad > Recall y capturas.==>Open Settings > Privacy & security > Recall & snapshots.
Apaga Guardar capturas.==>Turn off Save snapshots.
Borra las capturas guardadas y no se recuperan==>Deletes the saved snapshots and they can't be recovered
Se apaga el análisis de lo que hay en pantalla con la directiva de Windows. Las capturas guardadas se borran y no se recuperan.==>Screen analysis is turned off with the Windows policy. Saved snapshots are deleted and can't be recovered.
Widgets apagados==>Widgets off
Los widgets y las noticias de la barra de tareas usan memoria y red en segundo plano.==>Taskbar widgets and news use memory and network in the background.
Microsoft: política NewsAndInterests==>Microsoft: NewsAndInterests policy
Haz clic derecho en la barra de tareas.==>Right-click the taskbar.
Abre Noticias e intereses y elige Desactivar.==>Open News and interests and choose Turn off.
Se apagan los widgets con la directiva de Windows. Pide reiniciar.==>Widgets are turned off with the Windows policy. Needs a restart.
Abre Configuración > Personalización > Barra de tareas.==>Open Settings > Personalization > Taskbar.
Apaga Widgets.==>Turn off Widgets.
Copilot quitado==>Copilot removed
La app de Copilot viene con Windows y se ejecuta en segundo plano.==>The Copilot app comes with Windows and runs in the background.
Microsoft: administrar Copilot==>Microsoft: manage Copilot
Se vuelve a instalar; desde la Microsoft Store, con internet==>It is reinstalled from the Microsoft Store, with internet
Abre Afina con la cuenta del dueño para quitarlo==>Open Afina with the owner's account to remove it
Quitado==>Removed
Se quita la app de Copilot para esta cuenta con Remove-AppxPackage.==>The Copilot app is removed for this account with Remove-AppxPackage.
Corre solo con poco espacio libre y solo sobre temporales. No toca la Papelera ni Descargas.==>Runs only when free space is low and only on temporary files. It does not touch the Recycle Bin or Downloads.
Extensiones de archivo visibles==>File extensions shown
Ver la extensión ayuda a notar un archivo disfrazado, como factura.pdf.exe.==>Seeing the extension helps you spot a disguised file, like invoice.pdf.exe.
Microsoft: Explorador de archivos==>Microsoft: File Explorer
Visibles==>Shown
Ocultas==>Hidden
El Explorador de archivos muestra la extensión de todos los archivos.==>File Explorer shows the extension of every file.
Finalizar tarea en la barra de tareas==>End task on the taskbar
Agrega "Finalizar tarea" al menú de cada app de la barra, para cerrar una que no responde sin abrir el Administrador de tareas.==>Adds "End task" to the menu of each taskbar app, to close one that is not responding without opening Task Manager.
Microsoft: configuración avanzada de Windows==>Microsoft: Windows advanced settings
Activado==>On
Apagado==>Off
Se activa "Finalizar tarea" en Configuración > Sistema > Para programadores.==>"End task" is turned on in Settings > System > For developers.
Porcentaje de batería en la barra==>Battery percentage on the taskbar
Muestra el porcentaje junto al icono de la batería, sin pasar el mouse por encima.==>Shows the percentage next to the battery icon, without hovering over it.
Microsoft: KB5067036==>Microsoft: KB5067036
Visible==>Shown
Oculto==>Hidden
Se activa el porcentaje de batería en la bandeja del sistema.==>The battery percentage is turned on in the system tray.
Menú contextual clásico==>Classic context menu
Vuelve el menú de clic derecho completo de Windows 10, sin tener que pulsar "Mostrar más opciones".==>Brings back the full Windows 10 right-click menu, without having to click "Show more options".
Pureinfotech (sin fuente de Microsoft)==>Pureinfotech (no Microsoft source)
Una actualización de Windows puede volver a romperlo==>A Windows update can break it again
Clásico==>Classic
Nuevo==>New
Se crean dos claves vacías en tu usuario que devuelven el menú clásico. Pide reiniciar.==>Two empty keys are created for your user that bring back the classic menu. Needs a restart.
Búsqueda sin resultados de internet==>Search without web results
El cuadro de búsqueda de Windows manda lo que escribes a Bing y mezcla resultados de la web con los de tu PC.==>The Windows search box sends what you type to Bing and mixes web results with those from your PC.
Microsoft: política de búsqueda==>Microsoft: search policy
Activa==>On
Apagada==>Off
Abre Configuración > Privacidad y seguridad > Permisos de búsqueda.==>Open Settings > Privacy and security > Search permissions.
Apaga "Búsqueda de contenido en la nube" y "Mostrar aspectos destacados de la búsqueda".==>Turn off "Cloud content search" and "Show search highlights".
Esto no quita Bing del todo: Windows Home no tiene un ajuste para eso.==>This does not remove Bing completely: Windows Home has no setting for that.
Se apaga la búsqueda web con la directiva de Windows. Pide reiniciar.==>Web search is turned off with the Windows policy. Needs a restart.
Se apagan las sugerencias del cuadro de búsqueda con la directiva de Windows. Microsoft solo documenta que quita las búsquedas recientes del Explorador; su efecto en Inicio viene de la comunidad.==>Search box suggestions are turned off with the Windows policy. Microsoft only documents that it removes recent searches in File Explorer; its effect on Start comes from the community.
Inicio sin recomendaciones==>Start without recommendations
El menú Inicio muestra archivos recientes, apps sugeridas y avisos de la cuenta que casi nadie usa.==>The Start menu shows recent files, suggested apps and account notices that almost nobody uses.
Microsoft: política de Inicio==>Microsoft: Start policy
Apagadas==>Off
Activas==>On
Se apagan los archivos recientes, los programas recomendados y los avisos de la cuenta en Inicio. En Pro y superiores también se oculta la sección Recomendado.==>Recent files, recommended programs and account notices are turned off in Start. On Pro and above the Recommended section is also hidden.
'@
foreach ($afLine in ($script:AfStringsEnText -split "`r?`n")) {
    if (-not $afLine -or $afLine.StartsWith('#')) { continue }
    $afAt = $afLine.IndexOf('==>')
    if ($afAt -gt 0) { $script:AfStringsEn[$afLine.Substring(0, $afAt)] = $afLine.Substring($afAt + 3) }
}
