# Mi Primer Tycoon en Roblox

Guía completa desde cero para crear un juego **Tycoon**: el jugador reclama una
parcela, compra mejoras en orden y gana dinero pasivo con el tiempo. El
progreso se guarda automáticamente.

No necesitas construir nada a mano en 3D: un script arma el mapa por código.
Solo tienes que copiar y pegar 6 scripts en Roblox Studio, en el orden que
se indica más abajo.

## 1. Instalar y abrir Roblox Studio

1. Entra a https://create.roblox.com con tu cuenta de Roblox (o crea una).
2. Descarga **Roblox Studio** desde esa misma página (botón "Create" /
   "Start Creating") y ábrelo.
3. En la pantalla de inicio, elige la plantilla **Baseplate** (lugar en
   blanco con un piso gris) y crea un nuevo lugar.

## 2. Ubicarte en el Explorer

En Studio, el panel **Explorer** (menú `View > Explorer` si no lo ves) muestra
todo lo que existe en tu juego, organizado en "servicios". Los que vamos a
usar:

- **ReplicatedStorage**: código y datos compartidos entre servidor y jugadores.
- **ServerScriptService**: scripts que solo corren en el servidor (la lógica
  del juego vive aquí).
- **Workspace**: el mundo 3D visible (ahí aparecerán las parcelas, creadas
  por código).

## 3. Cómo insertar cada script

Para cada archivo de este proyecto:

1. Click derecho sobre el servicio correspondiente en el Explorer (por
   ejemplo `ReplicatedStorage`).
2. `Insert Object` > elige **Script** o **ModuleScript** según se indique
   arriba de cada archivo.
3. Borra el contenido de ejemplo que trae por defecto y pega el contenido
   del archivo de este proyecto.
4. Renombra el objeto exactamente como se indica (click derecho > Rename, o
   doble click sobre el nombre) — el nombre importa porque el código lo
   busca por ese nombre exacto.

### Orden de instalación

| # | Archivo | Tipo de objeto | Nombre exacto | Va dentro de |
|---|---------|----------------|----------------|----------------|
| 1 | `modules/GameConfig.lua` | ModuleScript | `GameConfig` | ReplicatedStorage |
| 2 | `scripts/1_PlotBuilder.server.lua` | Script | (el que quieras) | ServerScriptService |
| 3 | `scripts/2_PlotManager.server.lua` | Script | (el que quieras) | ServerScriptService |
| 4 | `scripts/3_PurchaseHandler.server.lua` | Script | (el que quieras) | ServerScriptService |
| 5 | `scripts/4_IncomeLoop.server.lua` | Script | (el que quieras) | ServerScriptService |
| 6 | `scripts/5_DataStoreHandler.server.lua` | Script | (el que quieras) | ServerScriptService |

Importante: `GameConfig` **debe** llamarse así (sin cambios), porque los
demás scripts hacen `require(ReplicatedStorage:WaitForChild("GameConfig"))`.
Los scripts de `ServerScriptService` pueden llamarse como quieras, el orden
de la tabla es solo para que sepas en qué secuencia pegarlos.

## 4. Activar el guardado de progreso (DataStore)

Para probar el guardado dentro de Studio:

1. Ve a `Home > Game Settings > Security`.
2. Activa **"Enable Studio Access to API Services"**.
3. Guarda (`Save`).

Sin este paso, el juego funciona igual pero el progreso no se guardará
mientras pruebas dentro de Studio (sí funcionará normal una vez publicado).

## 5. Probar el juego

1. Pulsa **Play** (F5) arriba en la barra de Studio.
2. Verás 4 parcelas grises en fila, cada una con un cartel cian que dice
   "Toca para reclamar".
3. Camina hasta el cartel y tócalo: tu parcela pasa a tener tu nombre, y
   arriba a la derecha aparece tu **Cash** (marcador automático de Roblox).
4. Camina hasta el primer botón verde ("Generador de Efectivo", $25),
   tócalo para comprarlo cuando tengas suficiente Cash: sube tu ingreso por
   segundo y se activa el siguiente botón.
5. Para probar con "varios jugadores" a la vez, usa `Test > Clients and
   Servers` (elige 2 clientes) en vez del botón Play normal.

## 6. Cómo funciona por dentro

- **1_PlotBuilder**: al arrancar el servidor, crea 4 parcelas (`Plots.Plot1`
  ... `Plot4`) con su piso, su cartel de reclamo (`ClaimPad`) y sus botones
  de mejora (`Button_1` ... `Button_6`), usando los datos de `GameConfig`.
- **2_PlotManager**: crea el `Cash` (leaderstats) de cada jugador al entrar,
  y asigna la parcela libre cuyo `ClaimPad` se toque.
- **3_PurchaseHandler**: cuando el dueño de una parcela toca el botón activo
  (el siguiente en la secuencia) y tiene suficiente Cash, cobra el precio,
  suma el ingreso pasivo y desbloquea el botón siguiente.
- **4_IncomeLoop**: cada segundo, paga a cada dueño el ingreso pasivo
  acumulado de su parcela.
- **5_DataStoreHandler**: guarda el Cash y las mejoras compradas cuando el
  jugador sale (o el servidor cierra), y las restaura cuando vuelve a
  entrar y reclamar su parcela.

## 7. Cómo personalizar

Todo el balance del juego está en `GameConfig.lua`:

- `PlotCount`: cuántas parcelas existen (una por jugador simultáneo).
- `StartingIncomePerSecond`: ingreso base antes de comprar nada.
- `Upgrades`: la lista de mejoras, en orden de compra. Cada una tiene
  `Price` (costo) e `IncomeAdd` (cuánto suma al ingreso por segundo).

Puedes agregar más filas a `Upgrades` (con `Id` nuevos y correlativos) y
`1_PlotBuilder` creará el botón correspondiente automáticamente.

## 8. Publicar tu juego

1. `File > Publish to Roblox As...`
2. Ponle nombre, descripción y una miniatura.
3. Una vez publicado, desde https://create.roblox.com puedes configurar
   quién puede jugarlo (público o solo tú) y ver estadísticas.

## 9. Errores comunes

- **"GameConfig is not a valid member of ReplicatedStorage"**: el
  ModuleScript no se llama exactamente `GameConfig`, o no está dentro de
  `ReplicatedStorage`.
- **"attempt to index nil with 'GetChildren'"** en algún script de
  `ServerScriptService`: probablemente pegaste el script antes de crear
  `GameConfig`, o el objeto es de tipo `LocalScript` en vez de `Script`
  (los `LocalScript` no corren en `ServerScriptService`).
- **El Cash no se guarda entre sesiones**: revisa el paso 4 (Enable Studio
  Access to API Services). Fuera de Studio, en el juego ya publicado, el
  guardado funciona sin este paso.

## 10. Próximos pasos (opcional)

- Interfaz gráfica personalizada (ScreenGui) en vez de depender solo del
  leaderboard automático.
- Decorar cada parcela con modelos del catálogo de Roblox (`Toolbox`).
- Sonidos y efectos de partículas al comprar una mejora.
- Un sistema de "prestigio" o rebirths para tycoons más avanzados.
