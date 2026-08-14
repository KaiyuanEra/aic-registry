# Context Variable Declaration and Reference

Variable declarations belong to the CONTEXT.md front matter; variable references belong to the body file of that context. Both must be maintained in pairs.

## Complete Example

CONTEXT.md:

```yaml
---
name: project-coding-guideline
version: 1.0.1
description: Default AI coding guideline injected into project context files.
targets:
  - CLAUDE.md
  - AGENTS.md
  - Agents.md
content: content.md
env-required: true
env-vars:
  - name: AIC_AVAILABLE_CLI_TOOLS
    description: Local command-line tools available to the model.
    required: false
    target: context
---
```

content.md:

````markdown
This project declares the available command-line tools:

```text
{{ aic.env.AIC_AVAILABLE_CLI_TOOLS }}
```
````

## Front Matter Fields

### env-required

- true: this context uses variables; a non-empty env-vars must be provided alongside.
- false: this context does not use variables; it should not contain env-vars or variable placeholders.

env-required describes whether the context as a whole uses variables; it is not equivalent to the required field of an individual variable.

### env-vars

Each variable item uses the following fields:

| Field | Required | Rules |
|---|---|---|
| name | yes | ^[A-Z][A-Z0-9_]*$, unique within the same context |
| description | yes | explains what information the variable provides and how the body uses it; no real values |
| required | yes | YAML boolean true or false, indicating whether the variable must be provided |
| default | no | non-sensitive default value used when no external value is present; no tokens, passwords, or environment-specific addresses |
| target | yes | context variables are fixed to context |

Do not fabricate a default value just because a variable is marked required: false. Only declare default when there is a stable, non-sensitive, cross-project-applicable default.

### Variable Name Hard Rules

Contexts and Skills use the exact same variable name rule:

```text
^[A-Z][A-Z0-9_]*$
```

- Must start with an uppercase letter.
- Subsequent characters can only be uppercase letters, digits, and underscores.
- Case-sensitive.
- No lowercase letters, hyphens, dots, or spaces.
- No leading digits or underscores.
- No duplicates within the same env-vars declaration.

Valid examples:

```text
API_KEY
API_BASE_URL
AIC_AVAILABLE_CLI_TOOLS
MODEL_V2_ENDPOINT
```

Invalid examples:

```text
api_key
2FA_TOKEN
API-KEY
API.KEY
_API_KEY
```

## Body Placeholder

Standard syntax:

```text
{{ aic.env.VAR_NAME }}
```

Extra spaces inside the braces are allowed, e.g. {{aic.env.VAR_NAME}}, but the standard form with spaces is output uniformly. The variable name must exactly match env-vars[].name and is case-sensitive.

The following are invalid:

```text
{{ VAR_NAME }}
{{ env.VAR_NAME }}
$VAR_NAME
${VAR_NAME}
{{ aic.env.var_name }}
```

## Consistency Rules

When generating or modifying a context, simultaneously check:

1. Each {{ aic.env.NAME }} has exactly one env-vars declaration with the same name.
2. Each env-vars declaration is referenced at least once in the body; remove the declaration when no longer used.
3. When any declaration or placeholder exists, env-required is true.
4. When env-required: true, env-vars is non-empty.
5. When env-required: false, no env-vars or placeholders exist.
6. Adding, removing, or modifying a variable declaration is a context artifact change; version must be bumped and the index regenerated.
7. Variable values are never written to the registry; the registry stores only declarations and placeholders.

## Modification Example

When adding PROJECT_TEST_COMMAND, complete all of the following in the same modification:

```yaml
env-required: true
env-vars:
  - name: PROJECT_TEST_COMMAND
    description: Verified command used to run the project test suite.
    required: true
    target: context
```

And reference it in content.md:

```text
{{ aic.env.PROJECT_TEST_COMMAND }}
```

Finally, bump CONTEXT.md.version, run make index, then run the context validation script.
