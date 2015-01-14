# gardend

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
* `LICENSE`: MIT license
* `README.md`: this README

## Design

See the [design document](design.md).

## Dependencies

Lua 5.2 or greater

LuaRocks: `lua-periphery` (for I/O and sleep), `lua-cjson` (for state serialization), `lsqlite3` (for state storage), `lua-resty-template` (for webstats), `busted` (for unit tests)

```
$ sudo luarocks install lua-periphery
$ sudo luarocks install lua-cjson
$ sudo luarocks install lsqlite3
$ sudo luarocks install lua-resty-template
$ sudo luarocks install busted
```

## Running

```
$ lua gardend.lua <configuration file>
```

Propagation configuration:

```
$ lua gardend.lua configs/propagation_config.lua
```

## Issues

Feel free to report any issues, bug reports, or suggestions at [github](https://github.com/vsergeev/gardend/issues) or by email at vsergeev at gmail.

## License

gardend is MIT licensed. See the provided LICENSE file.

