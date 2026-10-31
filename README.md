# Laboratorio: Man-in-the-Middle sobre HTTP

Laboratorio **local** para entender, de forma visual, por qué **nunca** se deben
enviar credenciales por HTTP. Monta un login de demostración de un **banco ficticio**
(«Banco Nébula», una entidad que no existe) y te enseña cómo un atacante situado «en
medio» de la conexión captura el usuario, la contraseña y la cookie de sesión **en
texto plano**.

> ⚠️ **Solo con fines educativos y sobre tu propio equipo.** Interceptar el tráfico de
> otras personas o de sistemas que no son tuyos es ilegal.

## Qué vas a aprender

- Qué es un ataque **Man-in-the-Middle (MITM)**: situarse entre el usuario y el
  servidor para observar o alterar el tráfico.
- Por qué **HTTP** (sin cifrar) deja las credenciales a la vista de quien esté en medio.
- Cómo usar **mitmproxy** como proxy inverso para capturar una petición de login.
- Por qué los sitios serios usan **HTTPS** y **HSTS**, y por qué este ataque está
  obsoleto frente a ellos.

## Requisitos

- **Parrot OS, Debian** o una distribución derivada.
- Un usuario con permisos de `sudo`.
- Los puertos **8090** y **8002** libres.
- [mitmproxy](https://mitmproxy.org/) para la demostración:
  `sudo apt install mitmproxy`.

## Instalación

```bash
git clone https://github.com/BEMC-GTRX/laboratorio-mitm.git
cd laboratorio-mitm
./instalar.sh
```

El script pide tu contraseña de `sudo` cuando la necesita. Al terminar debe mostrar:

```
[OK] Laboratorio listo: login de demostración en http://localhost:8090/login (responde 200 OK).
```

Abre <http://localhost:8090/login> en el navegador: verás el acceso del Banco Nébula.
Credenciales de demostración:

| Usuario | Contraseña |
|---|---|
| `cliente.demo` | `Nebula-Lab-2026` |

## La demostración paso a paso

La idea es colocar a **mitmproxy entre el navegador (la víctima) y el servidor**.
Cadena completa:

```
Firefox (víctima) ──► mitmproxy :8091 ──► nginx :8090 ──► app :8002
     navega              ATACANTE          proxy          login
```

### 1. El atacante se pone en medio

Levanta mitmproxy como **proxy inverso** delante de nginx, con su panel web:

```bash
mitmweb --mode reverse:http://127.0.0.1:8090 \
        --listen-host 127.0.0.1 -p 8091 --web-port 8092
```

- `--mode reverse:...` reenvía todo lo que reciba a la aplicación real (nginx).
- `-p 8091` es el puerto por el que entrará la «víctima».
- `--web-port 8092` es el panel de mitmproxy (los 8090/8091 están ocupados).
- `--listen-host 127.0.0.1` lo mantiene en tu equipo: nada se expone a la red.

### 2. La víctima inicia sesión

En el navegador, entra como haría la víctima en <http://localhost:8091/login> e
inicia sesión con las credenciales de demostración. Para ella todo parece normal.

### 3. Lo que ve el atacante

En el panel de mitmproxy (<http://127.0.0.1:8092>), filtra por `~m POST` y abre la
petición de `/login`:

- En **Request** verás el cuerpo `usuario=cliente.demo&clave=Nebula-Lab-2026` en
  **texto plano**.
- En **Response** verás la cabecera `Set-Cookie` con la cookie de sesión, que también
  se podría robar.

## Qué aprender de aquí

- El candado dibujado dentro de la página («Conexión segura») **no significa nada**: es
  solo un icono. El cifrado real es el de `https://` y el candado del navegador.
- Con **HTTPS**, el atacante solo vería datos cifrados.
- Los sitios serios usan **HSTS** (una política que obliga al navegador a usar siempre
  HTTPS), que impide incluso forzar la bajada a HTTP (*SSL stripping*).
- **Nunca** introduzcas credenciales reales en un sitio `http://`.

## Cómo funciona por dentro

- **La aplicación** (`app/app.py`) es un pequeño programa en Python (solo biblioteca
  estándar) que sirve el login en `/login` y una cuenta de ejemplo tras acceder. Se
  ejecuta como el servicio de systemd `lab-mitm-http-app` en `127.0.0.1:8002`.
- **nginx** recibe en `127.0.0.1:8090` y hace de proxy hacia la aplicación.
- Todo escucha **solo en `127.0.0.1`**: el laboratorio no es accesible desde la red.

## Qué cambia en el sistema

- Instala la aplicación en `/opt/lab-mitm-http/` y su servicio en
  `/etc/systemd/system/lab-mitm-http-app.service` (no se habilita al arrancar el equipo).
- Añade el sitio `/etc/nginx/sites-available/lab-mitm-http.conf` y su enlace en
  `sites-enabled/`, y recarga nginx (o lo arranca si estaba parado).
- Escribe sus registros en `/var/log/nginx/lab-mitm-http.{access,error}.log`.
- Antes de modificar nada, los scripts se detienen si los puertos ya los usa otro
  programa o si encuentran archivos ajenos con el mismo nombre.

## Desinstalación

```bash
./desinstalar.sh
```

Retira la aplicación, su servicio, el sitio de nginx y sus registros. Solo borra
archivos marcados como del laboratorio. Deja nginx instalado y en el estado en que esté.

## Archivos

| Archivo | Función |
|---|---|
| `instalar.sh` | Instala dependencias y deja el laboratorio funcionando. |
| `verificar.sh` | Dice si el login responde 200. No necesita `sudo`. |
| `desinstalar.sh` | Retira todo lo que instaló el laboratorio. |
| `app/app.py` | Aplicación del login de demostración (solo biblioteca estándar). |
| `app/lab-mitm-http-app.service` | Servicio de systemd de la aplicación. |
| `nginx/lab-mitm-http.conf` | Sitio de nginx en `localhost:8090` que hace de proxy. |
| `comun.sh` | Constantes y comprobaciones de seguridad compartidas. |

## Aviso

Banco y credenciales **ficticios**: no imitan a ninguna entidad real. Úsalo solo en tu
propio equipo o en un laboratorio autorizado.
