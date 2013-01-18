# getpuzzlenode.rb

## ¿Por qué?

[Puzzlenode](puzzlenode.com) es un sitio que contiene 15 puzzles de programación muy interesantes que nos ayudan a mejorar nuestras habilidades. Este pequeño script descarga todos los ejercicios de [Puzzlenode](puzzlenode.com) de forma automática en una carpeta formando una estructura como ésta:

  - carpeta_de_puzzle_nodes/
    - [#1] Ejercicio 1/
      - data/
        - Todos los archivos descargables en el sitio web.
      - source/
        - README.md
        - .git/ (repositorio de git)
        - .gitignore
    - [#2] Ejercicio 2/
      - ...

## Uso

`ruby getpuzzlenode.rb carpeta`