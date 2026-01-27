# CHANGELOG

## 0.0.6

* Added ECSDataEvent class
* Refactored Inspector Devtools Extension

## 0.0.5

* Major ECSContext refactoring for improved performance and reliability
  * Converted from microtask-based to frame callback-based execution model
  * All reactive updates (watch, listen, onEnter) now aligned with Flutter's rendering pipeline
  * Better batching of multiple entity changes within the same frame
  * Simplified codebase by removing async queue machinery
* Fixed disposal lifecycle issues
  * `onExit` callback now executes synchronously during disposal with access to entities
  * Proper cleanup of pending callbacks on context disposal
  * Added disposed state checks to prevent operations on disposed contexts
  * Fixed execution order: disposed flag set first, then onExit, then cleanup
* Enhanced documentation
  * Comprehensive documentation for all ECSContext lifecycle methods
  * Detailed timing guarantees for callbacks and rebuilds
  * Clear disposal sequence documentation
* Improved test coverage
  * Added comprehensive ECSScope tests
  * Updated all tests to use proper Flutter widget testing for frame callbacks
  * Tests now properly verify batching and lifecycle behavior

## 0.0.4

* Improved ECSManager name-based singleton behavior
  * Named managers are now lifecycle-based singletons (active only)
  * Unnamed managers always create new instances with unique indexes
* Enhanced manager lifecycle management
  * Constructor now automatically activates manager
  * Simplified factory constructor logic
  * `activate()` now adds manager to global registry
  * `deactivate()` removes manager from registry
* Improved ECSScope integration
  * Managers can now receive features directly in constructor for cleaner initialization flow
* DevTools extension improvements
  * Extension callback now correctly reflects dynamic manager lifecycle
  * Automatic updates when managers are added/removed

## 0.0.3

* Fix for inspector
* Fix for nested scopes

## 0.0.2

* Fix for license files so pub.dev would recognise them

## 0.0.1

* Initial release
* Event-Component-System architecture implementation
* Reactive state management
* Built-in Devtools Extension with visual debugging
* Flow and cascade analysis
* Performance monitoring
* Graph visualization
* Comprehensive documentation and examples
