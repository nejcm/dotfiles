# Common Patterns

- **Skeleton-first:** for new functionality, find a battle-tested skeleton, evaluate options with parallel agents (security / extensibility / relevance), clone the best, iterate inside it.
- **Repository pattern:** data access behind an interface (findAll/findById/create/update/delete); business logic depends on the abstraction, not the store.
- **API envelope:** consistent response shape — status flag, data (nullable on error), error message (nullable on success), pagination meta.
