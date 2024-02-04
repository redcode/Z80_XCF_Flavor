# Z80 XCF Flavor Changelog

## 1.3 / 2024-02-04

### Bugfixes

* Reverted the removal of superfluous code made in the previous version (necessary to be able to run the test more than once).

### Enhancements

* Added generation of a snapshot in SNA format (requested by Folkert van Heusden) in addition to the tape image (thanks, [Ped7g](https://github.com/ped7g)).

## 1.2 / 2024-01-30

### Enhancements

* Removed superfluous code.
* Minor optimizations.

### Project

* Moved the source code file to the root directory of the project.

## 1.1 / 2024-01-27

### Bugfixes

* Interrupts are now disabled during the test.

### Enhancements

* Added a brief description of the test on the screen.
* Modified the BASIC loader to make it easy for the user to re-run the test by typing `RUN 2` (thanks, [Ped7g](https://github.com/ped7g)).

## 1.0 / 2024-01-16

Initial public release.
