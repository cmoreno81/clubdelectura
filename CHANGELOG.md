# 📚 Club de Lectura
Todos los cambios importantes del proyecto se documentarán en este fichero.

El formato está inspirado en Keep a Changelog y el versionado sigue Semantic Versioning.

---
## v0.9 Beta - 30/06/2026

### 🎉 Primera beta pública

#### Clubvisión
- Sistema de votaciones
- Gala
- Lectura actual
- Historial

#### Dashboard
- Resumen mensual
- Usuario del mes
- Mood
- Tendencias

#### Libros
- Alta de libros
- Estados de lectura
- Valoraciones

#### Ranking
- Clasificaciones del club

## 💜 Gracias

Primera beta probada por:

- Cristina
- Ana
- Bea
- Silvia
- ...

Gracias por todas las ideas, errores encontrados y propuestas de mejora.

---

# [0.9.1] - 2026-07-01

## ✨ Añadido

- Nuevo sistema de votación de Clubvisión desde la aplicación.
- Sincronización de votos entre dispositivos mediante validación en backend.
- Automatización del cierre mensual de Clubvisión.
- Historial de Clubvisión accesible desde la aplicación.
- Iconos de género en el listado de libros.
- Iconos de género en la ficha de detalle de cada libro.
- Utilidad compartida `genero_utils.dart` para centralizar los iconos de género.

## 🐞 Corregido

- Solucionado el error al cargar libros cuando algunos campos numéricos llegaban como enteros.
- Corregido el control de votos duplicados entre varios dispositivos.
- Corregido el mes mostrado en el historial de Clubvisión (problema de zona horaria).
- Corregido el orden del historial para mostrar primero las ediciones más recientes.
- Mejorado el tratamiento de errores de carga mediante una vista de error reutilizable.
- Blindados los modelos frente a valores nulos o tipos inesperados.

## 💄 Mejoras de experiencia de usuario

- Nuevo mensaje: "Nadie lo está leyendo en este momento."
- Mejor consistencia visual entre Clubvisión y la sección de Libros.
- Mayor claridad en la representación visual de los géneros.
- Preparación de la aplicación para futuras mejoras sin afectar a las versiones publicadas.

## 🏗️ Arquitectura

- Creación de la rama `develop`.
- Primera organización del proyecto mediante Roadmap, Backlog y Changelog.
- Inicio del flujo de trabajo basado en versiones y releases.

---