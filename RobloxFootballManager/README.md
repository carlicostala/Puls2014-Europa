# Football Manager en Roblox

Guía completa para montar un juego de **gestión de fútbol** (estilo Top
Eleven / Manager Eleven): construyes las instalaciones de tu club (gradas,
gimnasio, tienda, parking), fichas jugadores con ojeadores y cantera, y
compites en una **liga real de 12 clubes** contra otros jugadores — los
partidos se simulan por fórmula, así que no hace falta que tu rival esté
conectado a la vez que tú.

No hay mapa 3D que recorrer: todo pasa por una interfaz en pantalla. Solo
tienes que copiar y pegar 8 archivos en Roblox Studio, en el orden indicado.

## 1. Instalar y abrir Roblox Studio

1. Entra a https://create.roblox.com con tu cuenta y descarga **Roblox
   Studio**.
2. Crea un lugar nuevo con la plantilla **Baseplate**.

## 2. Ubicarte en el Explorer

Abre `View > Explorer` si no lo ves. Servicios que vamos a usar:

- **ReplicatedStorage**: configuración compartida y los "Remotes" (canales
  de comunicación cliente-servidor).
- **ServerScriptService**: toda la lógica del juego (solo corre en el
  servidor, los jugadores no pueden verla ni manipularla).
- **StarterPlayer > StarterPlayerScripts**: el script que construye la
  interfaz en la pantalla de cada jugador.

## 3. Orden de instalación

Para cada archivo: click derecho en el servicio > `Insert Object` > el tipo
indicado > borra el contenido de ejemplo > pega el archivo > renombra el
objeto exactamente como se indica.

| # | Archivo | Tipo de objeto | Nombre exacto | Va dentro de |
|---|---------|----------------|----------------|----------------|
| 1 | `modules/replicated/GameConfig.lua` | ModuleScript | `GameConfig` | ReplicatedStorage |
| 2 | `modules/server/PlayerGenerator.lua` | ModuleScript | `PlayerGenerator` | ServerScriptService |
| 3 | `modules/server/LeagueUtil.lua` | ModuleScript | `LeagueUtil` | ServerScriptService |
| 4 | `modules/server/ClubService.lua` | ModuleScript | `ClubService` | ServerScriptService |
| 5 | `scripts/1_Bootstrap.server.lua` | Script | (el que quieras) | ServerScriptService |
| 6 | `scripts/2_ClubServer.server.lua` | Script | (el que quieras) | ServerScriptService |
| 7 | `client/3_ClubUI.client.lua` | LocalScript | (el que quieras) | StarterPlayer > StarterPlayerScripts |

Importante: `GameConfig`, `PlayerGenerator`, `LeagueUtil` y `ClubService`
**deben** llamarse exactamente así, y los tres últimos deben quedar
**directamente** dentro de `ServerScriptService` (no en una carpeta), porque
`ClubService` los busca por nombre con `script.Parent:WaitForChild(...)`.

## 4. Activar el guardado de progreso (DataStore)

1. `Home > Game Settings > Security`.
2. Activa **"Enable Studio Access to API Services"**.
3. Guarda.

Sin esto, el juego funciona pero el progreso y la liga no se guardan entre
pruebas dentro de Studio (una vez publicado, funciona sin este paso).

## 5. Probar el juego

1. Pulsa **Play** (F5).
2. Arriba a la izquierda verás una ventana con pestañas: **Plantilla**,
   **Instalaciones**, **Ojeadores y Cantera**, **Mercado**, **Liga**.
3. Empiezas con $500, una plantilla de 16 jugadores generados al azar y tu
   club ya metido en una liga (esperando a que se llenen los 12 puestos).
4. Prueba a mejorar una instalación, enviar un ojeador, o fichar del
   mercado. Usa `Test > Clients and Servers` (2+ clientes) para simular
   varios jugadores fichando por distintos clubes a la vez.

### Para probar la liga rápido

Con los valores por defecto, una jornada tarda **1 día real** en jugarse
(`GameConfig.MatchdayIntervalSeconds`), pensado para un juego publicado de
verdad. Para probarlo en Studio, baja ese número temporalmente (por ejemplo
a `60` para que una jornada se resuelva cada minuto) y sube
`GameConfig.LeagueSize` a un número más chico (por ejemplo `4`) para que la
liga se llene enseguida con pocos clientes de prueba. Vuelve a subir ambos
valores antes de publicar.

## 6. Cómo funciona por dentro

- **ClubService** (el módulo central) guarda cada club en un DataStore
  (`Clubs_v2`): nombre, dinero, plantilla, nivel de instalaciones, misión de
  ojeador/cantera y a qué liga pertenece.
- **Liga**: al entrar, `assignLeague` te mete en la liga abierta con hueco
  (`Leagues_v2`, contador global en `LeagueIndex_v2`). Cuando llega a 12
  miembros, se genera el calendario ida y vuelta con el método del círculo
  (22 jornadas).
- **Simulación de partidos**: cada club guarda dentro de la propia liga una
  "instantánea" de su fuerza (ataque/defensa promedio de la plantilla + bono
  del gimnasio). Cada ~30s, el servidor revisa si toca resolver la siguiente
  jornada de la liga de algún jugador conectado; si ha pasado el tiempo
  suficiente, calcula los resultados con esa instantánea (así funciona
  aunque tu rival esté offline) y actualiza la tabla de posiciones.
- **Instalaciones**: Gradas, Tienda y Parking dan dinero pasivo cada minuto;
  el Gimnasio sube el ataque/defensa promedio de tu plantilla.
- **Ojeadores y Cantera**: pagas, esperas un tiempo real, y al volver
  consigues un jugador nuevo (la cantera da jugadores más jóvenes y baratos
  que el ojeador).
- **Mercado de fichajes**: una lista compartida (`TransferMarket_v2`) de 8
  jugadores en venta, igual para todo el juego, que se renueva cada 30
  minutos. Comprar es del tipo "primero en llegar" — si dos jugadores
  intentan fichar al mismo a la vez, solo uno lo consigue.

## 7. Cómo personalizar

Todo el balance vive en `GameConfig.lua`:

- `LeagueSize`, `MatchdayIntervalSeconds`: tamaño y ritmo de la liga.
- `StartingCash`, `SquadSize`: punto de partida de cada club.
- `Facilities`: coste, nivel máximo e ingreso/bono de cada instalación.
- `ScoutCost` / `ScoutDurationSeconds`, `CanteraCost` /
  `CanteraDurationSeconds`: coste y tiempo de espera de cada vía de fichaje.
- `TransferMarketSize` / `TransferMarketRefreshSeconds`: tamaño y
  frecuencia de renovación del mercado.

## 8. Publicar tu juego

1. `File > Publish to Roblox As...`, con nombre, descripción y miniatura.
2. Desde https://create.roblox.com controlas quién puede jugarlo y ves
   estadísticas.

## 9. Errores comunes

- **"X is not a valid member of ReplicatedStorage/ServerScriptService"**:
  algún ModuleScript no tiene el nombre exacto de la tabla, o no quedó
  como hijo directo del servicio indicado.
- **La liga se queda en "esperando jugadores"**: necesitas 12 clubes reales
  (12 arranques de sesión distintos) para que se genere el calendario. Baja
  `LeagueSize` temporalmente para probar con menos.
- **El progreso no se guarda**: revisa el paso 4 (Enable Studio Access to
  API Services).

## 10. Próximos pasos (opcional)

- Alineación/táctica (elegir 11 titulares y una formación) en vez de usar
  toda la plantilla en la simulación.
- Ingresos de taquilla por partido de local en vez de (o además de) el
  ingreso pasivo de las gradas.
- Notificaciones más vistosas que el `print()` actual de resultados de
  acciones (usar un toast/label temporal en pantalla).
- Historial de resultados de partidos, no solo la tabla de posiciones.
