# LWC conventions: template expressions first

Template expressions are GA since Winter '27 (API 66.0+). Put simple display logic in the
HTML, not in a JS getter. `templateExpressionsDemo` is the reference for every supported
pattern:

| Pattern                           | Example                                            |
| --------------------------------- | -------------------------------------------------- |
| Template literal                  | ``{`${emp.firstName} ${emp.lastName}`}``           |
| Ternary                           | `{isLoggedIn ? 'Welcome back!' : 'Please log in'}` |
| Comparison as a boolean attribute | `disabled="{currentPage <= 1}"`                    |
| `?.` and `??`                     | `{user?.profile?.settings?.theme ?? 'default'}`    |
| Array methods                     | `{items.filter(item => item.qty > 0).length}`      |
| Class choice                      | `class="{hasLoadFailed ? 'slds-hide' : ''}"`       |

Rules: quote attribute expressions (`attr="{...}"`). An expression can't use `this`, `new`,
or function declarations. If an expression sits on its own line, put any leading space inside
the string (`' 🔥'`), because the compiler drops that line-break whitespace.

## Conditionals and element refs

- Use `lwc:if` / `lwc:elseif` / `lwc:else`. Don't use the legacy `if:true` / `if:false`.
- Use `lwc:ref="name"` with `this.refs.name` to reach an element in your own template, not
  `this.template.querySelector`. The embed components do this for `lightning-ui-embedding`.
  Use `querySelector` only where refs can't work, such as many elements from `for:each`.

As of 2026-10-15, no component in this folder uses `if:true`, `if:false` or `querySelector`.

## When a getter is still right

- `@api` getter/setter pairs. They're the component's public API (`value` in `employeeList`,
  `opportunityList`, `opportunityInputForm`).
- Logic the JS also needs. For example, `totalPages` is used by `handleNext()`, and it needs
  `Math.ceil`.
- Anything that needs `new` or helper calls, such as the `Intl` formatting for `formattedAmount`
  and `formattedCloseDate` in `opportunityList`.

## Audit (2026-10-15)

| Component                                       | Converted to template expressions                                           | Kept as JS                                                                         |
| ----------------------------------------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `employeeList`                                  | `hasEmployees`, `isPrevDisabled`, `isNextDisabled`, and the `fullName` join | `value`, `totalPages`. Search still joins the name in JS, because it's data logic. |
| `opportunityList`                               | `hasOpportunities`, `isPrevDisabled`, `isNextDisabled`                      | `value`, `totalPages`, `Intl` formatters                                           |
| `accountEmbeddedAngularApp`                     | `embeddingClass`                                                            | `computedSrc` (a plain alias for `baseUrl`, no logic)                              |
| `accountEmbedded{React,Nextjs,Vue,External}App` | none needed                                                                 | `computedSrc`                                                                      |
| `externalComponent`                             | the 🔥 badge                                                                | none                                                                               |
| `opportunityInputForm`                          | none needed                                                                 | `value` (`@api`)                                                                   |

`employeeList` and `opportunityList` moved from API 63.0 to 68.0, because expressions need
66.0+. Every other component was already on 66.0 or later.

## Testing

Stock `sfdx-lwc-jest` rejects complex expressions (LWC1060). `jest.config.js` uses
`jest/lwcTransformer.js`, which is the same transformer with `experimentalComplexExpressions: true`.
Run `npx sfdx-lwc-jest`.
