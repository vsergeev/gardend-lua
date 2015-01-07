# gardend

[Design document](design.md)

## File Structure

* `inputs/`: Input blocks
* `controllers/`: Controller blocks
* `outputs/`: Output blocks
* `postprocessors/`: Post-processing blocks
* `tests/`: Unit tests
* `configs/`: Daemon configurations
* `state.lua`: state management
* `gardend.lua`: garden daemon
* `design.md`: design document
* `README.md`: this README

## Dependencies

Lua 5.2 or greater

LuaRocks: `lua-periphery` (for I/O and sleep), `busted` (for unit tests)

```
$ luarocks install lua-periphery busted
```

## Running

```
$ lua gardend.lua <configuration file>
```

e.g., propagation configuration:

```
$ lua gardend.lua configs/propagation_config.lua
```

## Issues

Feel free to report any issues, bug reports, or suggestions at [github](https://github.com/vsergeev/gardend/issues) or by email at vsergeev at gmail.

## License

gardend is MIT licensed. See the provided LICENSE file.

