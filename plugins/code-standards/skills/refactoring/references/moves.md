# Safe refactoring moves

| Smell | Move | Steps |
|---|---|---|
| Long function | **Extract function** | copy block into a named function → call it → tests → delete original block |
| Huge file / god class | **Extract module/class** | move one cohesive group (+ its tests) → re-export from old location → update callers → remove re-export |
| Unclear name | **Rename** | IDE/tool rename across usages; one name per commit |
| Duplicate logic (3rd copy) | **Extract and reuse** | extract from one copy → replace the others one by one, tests after each |
| Nested conditionals | **Guard clauses** | invert conditions to early returns, one at a time |
| Type switches (`if type == …`) | **Replace conditional with polymorphism / map** | introduce interface/strategy map → move one branch at a time |
| Long parameter list | **Introduce parameter object** | DTO/value object; add overload/adapter during the move |
| Feature flag long dead | **Remove dead branch** | confirm flag value in all envs → delete branch + flag |
| Legacy path replaced | **Strangler** | route new traffic to the new path behind a switch → monitor → delete old path on its removal date |

## Large splits (e.g. a 6,000-line module)
1. Map responsibilities (list top-level functions, group by reason to change).
2. Characterization tests on the module's public entry points.
3. Extract the least-connected group first; re-export from the old module so callers don't change.
4. Repeat; finally update callers and delete re-exports.
5. One PR per group — reviewable and revertible.
