# Description
In-depth explanation of the technical aspects of the project.

## Design and Functionality
Description of how everything works, in precise detail.

## Key Libraries
* Yesod: web framework
* Persistent: database framework

## Directory Structure
The structure is taken from the Yesod MySQL scaffold, which is the Stack template yesod-mysql.  The directories and files are:

* Application.hs: key server functions to actually run the application
* Foundation.hs: foundational elements and key typeclass instances
* Import.hs: key imports
* Model.hs: builds models from the models file
* Settings.hs: settings

### Handler
Contains handlers, one file to each.

### Import
Important imports.

### Settings
Settings.

### app
Various versions of main.hs, for the development and production servers.

### config
Key configuration files.
* keter.yml: Config for using the Haskell deployment tool Keter (likely will not be used; came with the scaffold and I'm keeping it around in case it's needed)
* models: Contains descriptions for the database tables, using Persistent's DSL.
* routes: routes
* settings.yml: various settings, including static files, database connection, etc.

### static
Static files.
* hasknowledge.png: logo.
* hktext.png: just the text part of the logo

### templates
Yesod HTML (Hamlet), CSS (Lucius) and JavaScript (Julius) templates.

## Technologies and Rationale
What technologies are used and why.

### Haskell
Haskell is relatively difficult to learn, true, but I've found it to be incredibly powerful.  The type system means vastly more reliability than a language without such a powerful system, when so many errors can be caught at compile time.  In addition, Monad and Functor can be incredibly powerful; chaining operations may not be very useful in the IO Monad compared to an impure language, but the power of Monad and Functor is unrivaled where it comes to error handling with Maybe, Either, etc.  Refer to Real World Haskell's chapter on Monads for a good illustration of their capabilities.

Haskell also uses green threads, which are excellent for web server performance.

Should I need them, features like lazy lists (which can be used as streams) can also be powerful.

### Yesod
Haskell web framework designed for type safety and performance.  It is complicated to use and I did consider working without a framework, using Warp directly (but still with Persistent).  However, the type safety in particular is something I feel is worth the complexity: the framework is hard to learn, but it also makes it relatively hard to break things, with typesafe everything, even URLs.  It is an excellent example of Haskell's legendary type safety, and I feel sacrificing ease of getting started in exchange for superior reliability and maintainability is well worth it (I'll be spending a lot more time with this after getting comfortable than before).  It's also excellent at eliminating boilerplate through heavy use of Template Haskell, and the DSLs used are very clear.

### Persistent
Originally part of Yesod, now an independent library, Persistent uses the same principles of type-safety and DSLs.  This makes it reliable and clear: if I do anything wrong with my code, the type system complains.  No more SQL typos found only at runtime.  Along the same lines, because the framework handles the SQL internally, there is no risk of SQL injection.  Finally, the DSL makes things very easy and clear: do you need a detailed explanation to understand what the contents of config/models mean?  Compare that to what you would see with, for instance, Slick, a Scala functional-relational mapping library.

### Warp
I'm using the default Yesod server Warp, which apparently has the best performance of all the possible back-ends.  The rationale there is clear, and as Yesod acts the same way regardless of the back-end, there are no possible ease of use, maintainability, etc gains with other back-ends.

### PureScript
(Not currently in use, but will be when the time comes for a more sophisticated front-end)
All the power of Haskell, on the front-end.  That is a brief description of PureScript.  The language is very, very similar to Haskell and brings to bear many of the same capabilities.  I am particularly interested in the type safety, having been in the past very frustrated about constant runtime errors with React.  PureScript is also well-equipped to integrate with Haskell back-ends and there is a library for this purpose, purescript-bridge.
