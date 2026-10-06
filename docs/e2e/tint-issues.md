# tint-issues

Run 2026-10-06T19:53:09.076Z against http://127.0.0.1:3000.

| screenshot | user | URL | shows |
|---|---|---|---|
| ![](tint-issues-list-manager.png) | manager | `/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id` | Module on: rows tinted by age (background) and due date (10px side borders), as the manager |
| ![](tint-issues-list-reporter.png) | reporter | `/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id` | A member without plugin permissions sees the same tint (the module, not the permission, switches it) |
| ![](tint-issues-list-module-off.png) | manager | `/projects/e2e-private/issues?set_filter=1&status_id=*` | Module off in this project: an 8 months old issue gets no tint class and no colour |
| ![](tint-issues-module-settings-off.png) | manager | `/projects/e2e-project/settings` | Project settings, information tab: module Tint Issues unchecked |
| ![](tint-issues-list-after-off.png) | manager | `/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id` | After switching the module off the list is plain again |
| ![](tint-issues-list-after-on.png) | manager | `/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id` | Module on again: tint is back |
| ![](tint-issues-outsider-private.png) | outsider | `/projects/e2e-private/issues` | Outsider: the private project is refused |
| ![](tint-issues-list-outsider.png) | outsider | `/projects/e2e-project/issues?set_filter=1&status_id=*&sort=id` | Outsider: public project list is tinted as for everybody |
