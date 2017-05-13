# HasKnowledge
Quiz tool where you fill in your own question database as you learn, and can quiz yourself later.

# Description
HasKnowledge is designed for studying for classes or for anything else you study for an extended period of time.  You can create your own subject quizzes, then fill in questions as you go along.  When you need to go back and study, you'll have a set of questions to quiz yourself on.  May also build in support for writing summaries etc and sharing quizzes.

# Goals and Progress
## Programming:
* Started [Done]
* Implement home page [Done]
* Implement accounts [Done]
* Implement quizzes [Done]
* Implement adding questions to quizzes [Done]
* Implement sharing quizzes, either with the world or specified accounts [Public done]
* Implement summaries and other tools [Done]

## Launching:
* Determine backend technology [Done]
* Determine front-end technology
* Successfully run in a FreeBSD jail
* Transfer jail to AWS EC2 and database to AWS RDS
* Store front-end code on AWS S3 (after transitioning away from plain HTML)

# Technology
Server: FreeBSD, chosen for security, performance and stability (also, the daemon utility is awesome).  Running on AWS EC2.

Server-side: Haskell and the Yesod web framework, chosen for type safety, algebraic data types and Monad and Functor.  The learning curve is difficult, but the reward is concise, readable code and excellent safety--the type system will do a lot of work for you. Warp, the standard Yesod server, is also asynchronous by default and performs well.

Backend: MySQL, accessed via Persistent, a functional-relational mapping library with a DSL for specifying table structure and, as with Yesod (being part of the same family of libraries), a great deal of type safety.

Front-end: I will initially implement it with plain HTML simply for ease of development while I work on the server-side, but once that is complete the front-end will be re-implemented with PureScript, using an as-yet-undecided front-end framework (probably Halogen) and interacting with the backend through a JSON API.

# Branches
* master: Active development.
* stable: Tested and working; what is actually running.
* backup: Periodic backups of the stable branch.

# Name
Haskell + Knowledge
