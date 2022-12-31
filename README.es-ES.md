[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/forkanonetwork/genesis/blob/main/README.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](https://github.com/forkanonetwork/genesis/blob/main/README.es-ES.md)

# Operando un nodo de Forkano y creando un Pool de Staking + Nodo Productor de Bloques
## Este repositorio incluye
    - Información "Génesis" de Forkano Network
    - Scripts para desplegar y correr un nodo y (opcionalmente) un pool de delegaciones)


## Instalación
### Dependencias/Requerimientos:
- Tener docker instalado y funcionando
- 3 GB de almacenamiento disponible para la imagen docker y la información de la blockchain
- 2 GM de RAM como mínimo para que se ejecute correctamente
- Conexión a internet
- Abrir un puerto para recibir conexiones entrantes (obligatorio sólo si se quiere recibir recompensas)

### Instrucciones para Linux

Clonar este repositorio **¡Está advertido! _este proyecto es experimental, sólo para fines educativos_**
```bash
git clone https://github.com/forkanonetwork/genesis.git
cd genesis
./00-init.sh
```

¡Esto podría tomar algo de tiempo, la imagen de docker (~2.5 GB) va a ser descargada por primera vez!

Si todo sale bien _(lo que significa "suerte")_ verás una salida en la pantalla de este tipo:

`Chain extended, new tip: ba3e79a37d5c31a4db0ef8bbc122fe769d080f1bc77e7e7c66b3a89ccdfa0e70 at slot 11`

¡Ese es tu nuevo nodo sincronizándose con la red principal de Forkano!

Ahora deberá esperar a que termine de sincronizar para poder registrar un nuevo pool de stakin. Refiérase a la **Sección gLiveView** para poder monitorear su nodo y saber cuándo terminó de sincronizar.

#### Mientras tanto puede ir donando algo de BTC, USDT or ADA para mantener este proyecto. Refiérase a la **Sección Contribuir** para las direcciones donde donar


## gLiveView

Luego de que haya donado (o no, como desee, _recuerde los fines educativos_) puede revisar el estado de su nodo abriendo una segunda terminal y ejecutando

```bash
cd genesis
./02-gLiveView-forkano_node.sh
```
Con suerte verá el siguiente panel:


![imagen](https://user-images.githubusercontent.com/1715667/207903021-916bae11-71fc-4faf-890d-f1a934a09a1b.png)

Una vez que **"Syncing"** alcance el "100%" podrá continuar ejecutando las siguientes operaciones **opcionales**

## Registrando su nodo como un pool de staking y Nodo Productor de Bloques
* * OBLIGATORIO: debe abrir un puerto directamente a la máquina ejecutando este contenedor de docker para poder recibir conexiones entrantes de otros nodos de Forkano Network. Si no lo hace **podrá operar pero sin recibir recompensas**.
* Su nodo podrá recibir delegaciones!
* ¡Su nodo ganará recompensas **en CAP (el token o moneda nativa de la red Forkano)** al producir bloques! (Sólo si ha permitido conexiones entrantes de otros nodos)
* Deberá proveer una dirección de la billetera de su nodo para poder recibir fondos iniciales. Esto lo hará completando el <a href="https://forkano.net/en/registro-de-pool-de-staking/" target="_blank">SIGUIENTE FORMULARIO (¡OBLIGATORIO!)</a>
* Debe monitorear su nodo para asegurar el correcto funcionamiento
* Eventualmente deberá rotar sus claves KES (no se preocupe, ¡también hay un script para ello!)

### Pero, ¿cómo puedo ver la dirección de la billetera de mi nodo?

Puede salir de gLiveVew presionando 'q' o directamente abriendo otra terminal

Luego acceda al contenedor corriendo el nodo ejecutando lo siguiente
```bash
./03-join-forkano_node.sh
 - Ahora está dentro del contenedor corriendo el nodo, ejecute
cd ~
./01-check-balance.sh
```
 
Este script va a mostrar en pantalla la dirección de su nodo y revisará el balance actual
Una vez que tenga fondos en esa dirección podrá continuar con el siguiente paso

```bash
# (así es... es OBLIGATORIO editar las variables que comienzan con POOL_ antes de ejecutar, lineas ~52-58)
# Este comando abrirá un editor (MC Editor), debe buscar esas líneas y editarlas de acuerdo a sus necesidades
# Para grabar presione F2 y para salir de la edición presione F1'
mcedit ./forkano_init/scripts/01-pools/02-register-new-pool.sh
# Luego ejecute
./forkano_init/scripts/01-pools/02-register-new-pool.sh 
```

Si este script finaliza sin errores, ahora podrá "demonizar" (hacer que se autoejecute) el contenedor docker

# Demonizando el nodo
Salir de todas las terminales y contenedores de docker y ejecute desde el directorio genesis el siguiente comando
```bash
./01-run-forkano_node_daemon.sh
```

# Accediendo a su nodo "demonizado"
```bash
./03-join-forkano_node.sh
```

# Revisando los logs
```bash
./02-tail-forkano_node.sh (esto monitoreará las "colas" de los logs desde dentro del container demonizado)
./02-tail-local.sh (esto monitoreará las "colas" de los logs desde su directorio local)
```

Una vez que su pool ha sido registrado, podrá revisar el estado del mismo ejecutando el script `./forkano_init/scripts/01-pools/03-query-pool-details.sh` desde dentro del contenedor demonizado

Y, nuevamente, ¡puede revisar el estado de las llaves KES, de los bloques producidos, conexiones, etcétera, con gLiveView!

## Contribuir


**BTC Address**: bc1qe4wre8qwtav3krd3psxyk3cfpyyrmjhdu5p7jt

**USDT Address TRC-20 network**: TXPNLaLYNGd5TFkkDif9BY8PcMUeChqrY2

**ADA Address over Cardano Network**: addr1qxtdszvk7y5py6yu6yka27fsxpej5c33cu570fk6zg7tshwpkr4eltx90uad3gx4pr6s747vc94g26954lpk06swhcnsdqv0c9



## Asegurando las llaves

**¡Es SU responsabilidad dónde/cómo guarda de manera segura sus llaves!**
Sus llaves privadas pueden ser almacenadas en un entorno "frío" y borradas del nodo.
Sólo serán requeridas para firmar transacciones (por ejemplo al rotar las llaves KES(
