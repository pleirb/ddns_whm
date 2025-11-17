# 🌟 WHM Dynamic DNS con TTL Adaptivo 🌐

Script de Bash robusto diseñado para automatizar la actualización de la IP de subdominios (`A Records`) dentro de un entorno cPanel/WHM.

A diferencia de los scripts DDNS tradicionales, este utiliza una técnica de TTL adaptable para minimizar el tiempo de inactividad: reduce el TTL a 5 minutos, aplica el cambio de IP y luego restaura el TTL original.

## ✨ Características

* **Detección Automática de IP:** Utiliza `api.ipify.org` para detectar la IP pública actual.
* **Ahorro de API:** Solo realiza cambios si la IP ha cambiado.
* **Reducción de Latencia:** Baja el TTL a **5 minutos (300s)** antes del cambio de IP.
* **Restauración Segura:** Restaura el TTL original después de la actualización de la IP.
* **Verificación Final:** Comprueba la propagación usando Google DNS (`8.8.8.8`).
* **Salida Detallada:** Utiliza colores Bash para un registro de consola claro y conciso.

## ⚙️ Requisitos

1.  Acceso al API de **WHM** con credenciales de usuario y contraseña (no solo cPanel).
2.  Un entorno Linux/macOS con Bash.
3.  Las herramientas **`curl`**, **`jq`** y **`dig`** instaladas.

## 🚀 Configuración y Uso

Edita la sección **`CONFIGURACIÓN`** al inicio del script (`ddns-whm.sh`) con tus datos:

### WHM_URL="https://josefina.servidorlinux15.com:2087" (Tu acceso WHM/cPanel que puede ser diferente)
### WHM_USER="TU_USUARIO_DE_WHM"
### WHM_PASS="TU_CONTRASEÑA_DE_WHM_AQUI"
### ZONA_DNS="TU_DOMINIO_AQUI"
### SUBDOMINIO="TU_SUB_DOMINIO_AQUI"
### TTL_TEMPORAL=300 (5 minutos para propagación rápida)

## 📝 Notas del API
El script utiliza la función editzonerecord de WHM API 1 (el método más compatible con la autenticación básica de WHM para este tipo de tareas).
La variable SUBDOMINIO debe coincidir con el registro existente en cPanel.

## 🤝 Contribuciones
Las contribuciones son bienvenidas. Si encuentras errores o tienes sugerencias de mejora, por favor, abre un 'Issue' o un 'Pull Request'.

## 📜 Licencia
Distribuido bajo la Licencia MIT. Consulta el archivo LICENSE para más información.
