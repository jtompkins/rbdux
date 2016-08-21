## 0.3 (8/21/16)

Features:

* `Rbdux::Store#get` has been replaced with `Rbdux::Store#fetch`, which follows the normal Ruby semantics for `#fetch` methods.
* Rbdux now has documentation, a changelog, and a contribution guide!
* The `Dispatch Interceptor` middleware has been renamed `ThunkMiddleware`, matching the middleware of the same name from Redux.

## 0.2 (8/9/2016)

Features:

* The way `Rbdux::Store` actually stores state data is now user-replaceable with new store container types!
* The Store can be configured with a store container using the new `.with_store` class method.
* Two store containers come with Rbdux:
  * `Rbdux::Stores::MemoryStore` - a simple in-memory Hash of state data
  * `Rbdux::Stores::ImmutableMemoryStore` - an in-memory store that uses Hamster for immutable data structures.
* The way Rbdux handles middleware has changed.
  * Middleware was previously added to Rbdux using blocks provided to the `#before` and `#after` methods of the Store; these methods have been removed.
  * A new Store method, `#add_middleware`, has been added. This method takes an object that should respond to `#before`, `#after`, or both.
* Store methods to override how Rbdux handles merges have been removed.
* The `#state` accessor method has been removed in favor of a new `#get` method that defers to the Store's selected store container.

Bugfixes:

* The `MemoryStore` store container is now thread-safe.

## 0.1 (8/2/2016)

Rbdux Initial Release
