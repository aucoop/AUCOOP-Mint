# Solución de problemas

Problemas que han ocurrido de verdad y qué hacer con ellos.

## El instalador se detiene en un paso

La pantalla de error indica el paso, muestra las últimas líneas y señala el registro completo: `~/.local/state/aucoop-mint/install.log`. Es seguro ejecutar otra vez el mismo comando y suele bastar, porque el trabajo terminado se omite.

## «No hay conexión a internet» antes de empezar

El instalador comprueba la red antes de pedir la contraseña. Conecta el equipo y vuelve a ejecutarlo. Si el portátil dice que está conectado pero el instalador no lo cree, probablemente NetworkManager ha detectado un portal cautivo: abre Chrome, entra en la red y prueba otra vez.

## Las descargas fallan en una red que inspecciona TLS

Nos ocurrió en una red con la pasarela Zero Trust de Cloudflare. Todas las descargas HTTPS fallaban y `wget` mostraba algo parecido a esto:

```
ERROR: cannot verify dl.google.com's certificate, issued by
'CN=Gateway CA - Cloudflare Managed G1 ...':
Self-signed certificate encountered.
```

La red descifra el tráfico y lo vuelve a firmar con su propia autoridad de certificación, que la instalación nueva de Mint todavía no conoce. Tu ordenador quizá sí confíe en ella, por eso allí funciona la misma descarga. Instala esa CA en el portátil:

```bash
sudo cp your-gateway-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

Después repite el instalador. Esto también ocurre en redes corporativas, algunos campus universitarios y filtros escolares.

## Chrome pregunta qué buscador utilizar

Es normal, no un fallo. Chrome muestra ese diálogo la primera vez que se abre en la Unión Europea. Elige uno y no volverá a aparecer.

## AUCOOP Welcome no se abre después del reinicio

Solo se abre automáticamente mientras la preparación esté pendiente. Haz doble clic en el icono AUCOOP Welcome del escritorio para recuperarlo cuando quieras.

## Las actualizaciones parecen bloqueadas

Probablemente siguen trabajando. Mira la línea bajo la barra: muestra el paquete que se instala en ese momento. Un Mint 22.3 recién instalado puede tener cientos de actualizaciones y varios cientos de megabytes pendientes. Abre «Detalles técnicos» si quieres ver la salida de apt.

## «No hay suficiente espacio» al instalar la IA

El modelo y su entorno necesitan más espacio del disponible. Welcome lo comprueba antes de descargar para no llenar el disco y fallar al final. Elige un modelo menor o libera espacio.

## El asistente de IA no arranca

Aparecerá una notificación. El registro está en `/tmp/aucoop-local-ai.log`. Hemos visto dos causas: un modelo borrado o dañado, que se arregla reinstalando, y otro programa en el puerto 8091. El lanzador actual evita la segunda usando el siguiente puerto libre.

## El asistente desaparece al cabo de un rato

Es intencionado. Si ningún navegador se conecta durante diez minutos, se apaga para liberar memoria: un modelo cargado ocupa todo su tamaño en RAM. Pulsa el icono para volver a iniciarlo.

## Falla el registro del último paso

Comprueba primero el token y después la URL de la instancia. Workbench necesita root, que obtiene mediante el diálogo de contraseña, y también necesita red. Ejecútalo desde Welcome para que todo eso quede preparado.

## Otro problema

Abre una incidencia en [github.com/aucoop/AUCOOP-Mint](https://github.com/aucoop/AUCOOP-Mint/issues) y adjunta `~/.local/state/aucoop-mint/install.log`. No contiene contraseñas, solo las acciones de los scripts.
