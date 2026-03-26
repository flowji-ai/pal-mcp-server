# Reviews Schema

Must also include the common `metadata:` fields.

```yaml
type: architecture              # freeform: architecture | code-quality | spec | system-enhancement | onboarding | historical-analysis | marketing | pre-implementation-gate | comparative-analysis
status: complete                # enum: complete | draft | partial
metadata:
  date_created: "..."
  date_updated: "..."
  created_by_user: ostiimac
```

| Field | Required | Notes |
|-------|----------|-------|
| `type` | Yes | Common values listed above, custom values allowed |
| `status` | No | Default `complete` |

Optional fields (add when relevant):

| Field | Notes |
|-------|-------|
| `scope` | Component being reviewed |
| `method` | Approach used |
| `source` | Origin of reviewed content |

Mutations: `create-review.sh`. No resolve script — reviews are reference documents.
