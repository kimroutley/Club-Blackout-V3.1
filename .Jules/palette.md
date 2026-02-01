## 2025-05-26 - Icon-Only Buttons Need Tooltips
**Learning:** Icon-only buttons (like "+" or "x") are inaccessible to screen readers and ambiguous to some users without `tooltip` or semantic labels.
**Action:** Always add a `tooltip` property to `IconButton` widgets to provide context for screen readers and hover states.

## 2024-05-27 - Empty States Should Be Actionable
**Learning:** Static "No items" screens create a dead end for users. Adding immediate actions (like "Paste List" or "From History") directly in the empty state significantly reduces friction for first-time users.
**Action:** When implementing empty states for lists, always include the primary creation action(s) directly in the empty state view.
