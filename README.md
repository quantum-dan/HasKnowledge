# HasKnowledge
Quiz tool where you fill in your own question database as you learn, and can quiz yourself later.

# Description
HasKnowledge is designed for studying for classes or for anything else you study for an extended period of time.  You can create your own subject quizzes, then fill in questions as you go along.  When you need to go back and study, you'll have a set of questions to quiz yourself on.  May also build in support for writing summaries etc and sharing quizzes.

# Next Steps
## Programming
* Implement specific-user sharing for Quizzes and Summaries
* Implement asynchronous quiz question adding
* Implement summary updating
* Implement summary auto-save
* Improve styling
* Implement deletion for quizzes, summaries, notes
* Improve UI for filter-by-topic
* Improve quiz answer-checking system

## Other
* Switch to FreeBSD server on EC2
* Add HTTPS support

# Technology
Server: FreeBSD, chosen for security, performance and stability (also, the daemon utility is awesome).  Running on AWS EC2.

Server-side: Haskell and the Yesod web framework, chosen for type safety, algebraic data types and Monad and Functor.  The learning curve is difficult, but the reward is concise, readable code and excellent safety--the type system will do a lot of work for you. Warp, the standard Yesod server, is also asynchronous by default and performs well.

Backend: MySQL, accessed via Persistent, a functional-relational mapping library with a DSL for specifying table structure and, as with Yesod (being part of the same family of libraries), a great deal of type safety.

# Branches
* master: Active development.
* Testing: Testing updates before moving to stable.
* stable: Tested and working; what is actually running.
* backup: Periodic backups of the stable branch.

# Name
Haskell + Knowledge
