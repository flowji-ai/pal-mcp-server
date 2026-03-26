---
Date Generated: "{{generated_at}}"
Source: messages.json
---

# Prompt: {{title}}

**Status**: {{status}} | **Created**: {{created_at}} | **Updated**: {{updated_at}}

**Creator**: {{creator}}
**Implementer**: {{implementer}}

---

## Interaction Log

| # | Type | From | Content | Time |
|---|------|------|---------|------|
{{#each messages}}
| {{id}} | {{type}} | {{from}} | {{content}} | {{timestamp}} |
{{/each}}

---
*Generated from messages.json by `/view-prompt`*
