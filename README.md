# Servicio distribuido de tuplas clave-valor en C (sockets TCP + pthreads + SQLite)

Práctica de **Sistemas Distribuidos** (Grado en Ingeniería Informática, UC3M, 2025), hecha en
pareja por Jorge Agramunt ([@Baisicol](https://github.com/Baisicol)) y Pablo Navarro
([@Pabcat222](https://github.com/Pabcat222)).

Un servidor concurrente guarda tuplas `<key, value1, value2, value3>` y los clientes las
manipulan mediante una API en C (`claves.h`) **sin saber que hay una red por medio**: la
comunicación queda escondida en una biblioteca dinámica (`libclaves.so`) que hace de proxy.

```
 app-cliente-*.c ──► libclaves.so (proxy-sock.c) ══ TCP ══► servidor-sock.c ──► claves.c ──► SQLite
      API claves.h        serializa y envía                  un hilo por conexión     mutex + consultas
```

## API

| Función | Qué hace |
|---|---|
| `destroy()` | Borra todas las tuplas |
| `set_value(key, v1, N, V2, v3)` | Inserta; error si la clave ya existe o `N` ∉ [1, 32] |
| `get_value(key, …)` | Devuelve los valores asociados a `key` |
| `modify_value(key, …)` | Modifica una tupla existente |
| `delete_key(key)` | Elimina una tupla |
| `exist(key)` | 1 si existe, 0 si no, −1 si hay error |

`value1` es una cadena de hasta 256 caracteres, `value2` un vector de 1 a 32 `double` y
`value3` una estructura `Coord {x, y}`.

## Diseño

- **Proxy transparente** (`proxy-sock.c`): implementa `claves.h` y se compila como
  `libclaves.so`. Los clientes solo enlazan contra la biblioteca; la dirección del servidor
  se lee de las variables de entorno `IP_TUPLAS` y `PORT_TUPLAS`.
- **Protocolo binario propio**: cada campo se serializa en orden de red (`htonl`), con las
  cadenas precedidas de su longitud, para que cliente y servidor se entiendan aunque tengan
  distinta arquitectura.
- **Servidor concurrente** (`servidor-sock.c`): bucle `accept` que lanza un `pthread` por
  conexión y cierre ordenado con `SIGINT`.
- **Persistencia y atomicidad** (`claves.c`): las tuplas se guardan en SQLite y cada
  operación se hace bajo un mutex, de modo que dos clientes que insertan la misma clave a la
  vez no dejan el almacén en un estado inconsistente.

## Compilar y ejecutar

Requiere `gcc`, `make` y las cabeceras de SQLite (`libsqlite3-dev` / `sqlite-devel`).

```bash
make                                  # libclaves.so, servidor y 7 clientes de prueba
./servidor 4500 &                     # terminal 1

export IP_TUPLAS=127.0.0.1 PORT_TUPLAS=4500 LD_LIBRARY_PATH=.
./cliente                             # un cliente
./run_clients.sh                      # los 7 clientes a la vez, para probar la concurrencia
```

Los clientes `app-cliente-*.c` cubren cada operación de la API y sus casos de error.
