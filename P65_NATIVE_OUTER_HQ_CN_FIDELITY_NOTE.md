# P65 Native Outer / HQ CN Fidelity

P65 is intentionally narrow. It restores frozen CN string-table authority on proven Release-visible outer/HQ surfaces without changing gameplay or resources.

Evidence:
- `original_layout-568h.xml` binds `form_getgeneral` to `title_buygeneral`, `form_getgeneraltips` to `title_generaltips`, `form_generalinfo` to `title_headquarters`, and `form_deploygeneral` to `btn_princess`, `btn_college`, and `btn_deploy`.
- The same frozen layout binds conquest region labels to `text2_european` / `text2_american`.
- `strings_cn.json` freezes the exact CN values used in this pass.

Visible corrections include `获得上将 -> 获得将军`, `确　定 -> 出征` on the deploy-general primary action, and `总　部 -> 指挥部` on the HQ general-detail surface.

No Native resource bytes changed. No SOURCE_LEAN bytes changed.
