# CHANGELOG

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
